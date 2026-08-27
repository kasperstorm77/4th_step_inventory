#!/usr/bin/env bash
# promote-play-release.sh — put a versionCode that is ALREADY on Google Play
# onto the PRODUCTION track, with the bilingual notes from release.md.
#
# The sibling scripts/upload-aab-to-play.sh uploads a bundle and hard-pins the
# closed `alpha` track — production is deliberately not a destination for it
# (architecture.md §7.1). This script is the explicit, separate step that
# promotes an alpha-tested build: it uploads nothing, and it will only ever
# name a versionCode Play already holds.
#
#   edits.insert → tracks.update(production) → edits.commit → read back
#
# Defaults: versionCode from pubspec.yaml's +BUILD, full rollout (status
# "completed"). `--rollout 0.2` stages a staged rollout to 20 % ("inProgress")
# instead — finish it in Play Console. Dry run unless --yes.
#
# Usage:
#   bash scripts/promote-play-release.sh                # dry run: validate, stage, discard
#   bash scripts/promote-play-release.sh --yes          # promote to production (100 %)
#   bash scripts/promote-play-release.sh --rollout 0.2 --yes
#   bash scripts/promote-play-release.sh --version-code 117 --yes
#   bash scripts/promote-play-release.sh --draft --yes    # stage a DRAFT on production; press "Start rollout" in the Console
set -euo pipefail
cd "$(dirname "$0")/.."

if [[ -t 1 ]]; then
  c_reset=$'\033[0m'; c_bold=$'\033[1m'
  c_red=$'\033[31m'; c_green=$'\033[32m'; c_yellow=$'\033[33m'; c_blue=$'\033[34m'; c_cyan=$'\033[36m'
else
  c_reset=""; c_bold=""; c_red=""; c_green=""; c_yellow=""; c_blue=""; c_cyan=""
fi
say()    { printf "%s→%s %s\n" "$c_blue"   "$c_reset" "$*"; }
ok()     { printf "%s✓%s %s\n" "$c_green"  "$c_reset" "$*"; }
warn()   { printf "%s!%s %s\n" "$c_yellow" "$c_reset" "$*"; }
err()    { printf "%s✗%s %s\n" "$c_red"    "$c_reset" "$*" >&2; }
header() { printf "\n%s%s%s\n" "$c_bold$c_cyan" "$1" "$c_reset"; printf "%s%s%s\n" "$c_bold$c_cyan" "────────────────────────────────────────────────────────────" "$c_reset"; }

readonly track="production"
key="${PLAY_SERVICE_ACCOUNT_JSON:-local_files/play-service-account.json}"
notes_file="release.md"
package="dk.stormstyrken.twelvestepsapp"
version_code=""
rollout=""
draft=0
skip_validate=0
assume_yes=0

while (( $# )); do
  case "$1" in
    --version-code) shift; version_code="${1:?--version-code needs a value}" ;;
    --rollout)      shift; rollout="${1:?--rollout needs a fraction in (0,1)}" ;;
    --draft)        draft=1 ;;
    --skip-validate) skip_validate=1 ;;   # diagnostic: go straight to commit (Play validates on commit anyway)
    --key)          shift; key="${1:?--key needs a path}" ;;
    --notes)        shift; notes_file="${1:?--notes needs a path}" ;;
    --package)      shift; package="${1:?--package needs a value}" ;;
    -y|--yes)       assume_yes=1 ;;
    -h|--help)      sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    --track)        err "--track is not a flag: this script promotes to production only."; exit 2 ;;
    *) err "unknown flag: $1"; exit 2 ;;
  esac
  shift
done

for tool in jq curl openssl; do
  command -v "$tool" >/dev/null || { err "$tool is required"; exit 1; }
done
[ -f "$key" ] || { err "service-account key not found: $key"; exit 1; }

# ─── version + notes ─────────────────────────────────────────────────────────
header "Release"
ssot=$(grep -m1 '^version:' pubspec.yaml | sed -E 's/version:[[:space:]]*//')
[ -n "$version_code" ] || version_code="${ssot##*+}"
[[ "$version_code" =~ ^[0-9]+$ ]] || { err "versionCode must be numeric, got '$version_code'"; exit 1; }

status="completed"; fraction_json="null"
if [ "$draft" -eq 1 ] && [ -n "$rollout" ]; then err "--draft and --rollout are mutually exclusive"; exit 2; fi
[ "$draft" -eq 1 ] && status="draft"
if [ -n "$rollout" ]; then
  awk -v f="$rollout" 'BEGIN{exit !(f>0 && f<1)}' || { err "--rollout must be a fraction strictly between 0 and 1"; exit 1; }
  status="inProgress"; fraction_json="$rollout"
fi

extract_block() {
  awk -v tag="$1" '
    $0=="<" tag ">"  {grab=1; next}
    $0=="</" tag ">" {if(grab) exit}
    grab {print}
  ' "$notes_file"
}
[ -f "$notes_file" ] || { err "release notes file not found: $notes_file"; exit 1; }
version=$(awk '/^[0-9]+\.[0-9]+\.[0-9]+ - /{print $1; exit}' "$notes_file")
notes_en=$(extract_block "en-GB"); notes_da=$(extract_block "da-DK")
[ -n "$version" ]  || { err "No 'X.Y.Z - DATE:' line in $notes_file"; exit 1; }
[ -n "$notes_en" ] || { err "No <en-GB> block under the top version in $notes_file"; exit 1; }
[ -n "$notes_da" ] || { err "No <da-DK> block under the top version in $notes_file"; exit 1; }
if [ "$version" != "${ssot%%+*}" ]; then
  warn "release.md top block is $version but pubspec.yaml is ${ssot%%+*} — notes may be stale."
fi
for pair in "en-GB:$(printf '%s' "$notes_en" | wc -m | tr -d ' ')" "da-DK:$(printf '%s' "$notes_da" | wc -m | tr -d ' ')"; do
  [ "${pair##*:}" -le 500 ] || { err "${pair%%:*} notes are ${pair##*:} chars — Play's limit is 500."; exit 1; }
done
ok "v$version → versionCode $version_code → '$track' ($status${rollout:+, $rollout of users})"

# ─── authenticate ────────────────────────────────────────────────────────────
header "Authenticate"
b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
now=$(date +%s); exp=$((now + 3600))
client_email=$(jq -r .client_email "$key")
token_uri=$(jq -r '.token_uri // "https://oauth2.googleapis.com/token"' "$key")
jwt_claim=$(jq -cn --arg iss "$client_email" --arg aud "$token_uri" --argjson iat "$now" --argjson exp "$exp" \
  '{iss:$iss, scope:"https://www.googleapis.com/auth/androidpublisher", aud:$aud, iat:$iat, exp:$exp}')
pk_file=$(mktemp); trap 'rm -f "$pk_file"' EXIT
jq -r .private_key "$key" > "$pk_file"
signing_input="$(printf '%s' '{"alg":"RS256","typ":"JWT"}' | b64url).$(printf '%s' "$jwt_claim" | b64url)"
jwt="${signing_input}.$(printf '%s' "$signing_input" | openssl dgst -sha256 -sign "$pk_file" | b64url)"
access_token=$(curl -sS -X POST "$token_uri" \
  --data-urlencode "grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer" \
  --data-urlencode "assertion=$jwt" | jq -r '.access_token // empty')
[ -n "$access_token" ] || { err "Token exchange failed"; exit 1; }
ok "Access token acquired"

api="https://androidpublisher.googleapis.com/androidpublisher/v3/applications/$package"
auth=(-H "Authorization: Bearer $access_token")
http() {
  local method="$1" url="$2"; shift 2
  local out code body
  out=$(curl -sS -X "$method" "${auth[@]}" "$@" -w $'\n%{http_code}' "$url")
  code=${out##*$'\n'}; body=${out%$'\n'*}
  if [[ "$code" != 2* ]]; then
    err "Play API $method ${url##*/} → HTTP $code"
    jq . <<<"$body" >&2 2>/dev/null || printf '%s\n' "$body" >&2
    exit 1
  fi
  printf '%s' "$body"
}
print_track_report() {
  jq -r '.tracks[]? | .track as $t | (.releases // []) | if length == 0 then "  \($t)\t(no releases)" else
    .[] | "  \($t)\t\(.status // "?")  versionCode=\((.versionCodes // []) | join(",") | if . == "" then "-" else . end)  \(.name // "")" end' <<<"$1" \
    | awk -F'\t' '{printf "  %-12s %s\n", $1, $2}'
}
serves() { # $1=tracks json $2=track $3=code $4=status-set → count of matching releases carrying the code
  jq -r --arg t "$2" --arg vc "$3" --arg want "$4" '[.tracks[]? | select(.track == $t) | (.releases // [])[]
    | select(($want | split(",")) | index(.status)) | select((.versionCodes // []) | index($vc))] | length' <<<"$1"
}

# ─── 1. open an edit and prove Play already holds the bundle ─────────────────
header "Open edit"
edit_id=$(http POST "$api/edits" | jq -r .id)
ok "Edit $edit_id"
before=$(http GET "$api/edits/$edit_id/tracks")
print_track_report "$before"
if ! http GET "$api/edits/$edit_id/bundles" | jq -e --arg vc "$version_code" '[.bundles[]? | select((.versionCode|tostring) == $vc)] | length > 0' >/dev/null; then
  http DELETE "$api/edits/$edit_id" >/dev/null
  err "Play holds no bundle with versionCode $version_code — upload it with scripts/upload-aab-to-play.sh first."
  exit 1
fi
ok "Play holds bundle versionCode $version_code"
current_prod=$(jq -r '[.tracks[]? | select(.track=="production") | (.releases // [])[] | select(.status=="completed" or .status=="inProgress") | (.versionCodes // [])[]] | map(tonumber) | max // 0' <<<"$before")
if [ "$version_code" -le "$current_prod" ]; then
  http DELETE "$api/edits/$edit_id" >/dev/null
  err "production already serves versionCode $current_prod ≥ $version_code — nothing to promote."
  exit 1
fi

# ─── 2. stage the production release ────────────────────────────────────────
header "Assign to track '$track' ($status)"
track_payload=$(jq -cn --arg track "$track" --arg vc "$version_code" --arg status "$status" \
  --argjson fraction "$fraction_json" --arg en "$notes_en" --arg da "$notes_da" \
  '{track:$track, releases:[({versionCodes:[$vc], status:$status, releaseNotes:[
      {language:"en-GB", text:$en}, {language:"da-DK", text:$da}]}
    + (if $fraction == null then {} else {userFraction:$fraction} end))]}')
http PUT "$api/edits/$edit_id/tracks/$track" -H "Content-Type: application/json" -d "$track_payload" >/dev/null
ok "v$version (versionCode $version_code) staged on '$track' with en-GB + da-DK notes"

# ─── 3. validate, then commit or discard ─────────────────────────────────────
if [ "$skip_validate" -eq 0 ]; then
  header "Validate edit"
  http POST "$api/edits/$edit_id:validate" >/dev/null
  ok "Play accepts the edit (listing, policy and bundle checks passed)"
fi

if [ "$assume_yes" -ne 1 ]; then
  header "Dry run — discarding edit"
  http DELETE "$api/edits/$edit_id" >/dev/null
  ok "Edit discarded. Nothing was published. Re-run with --yes to promote."
  exit 0
fi

header "Commit"
http POST "$api/edits/$edit_id:commit" >/dev/null
ok "Committed. v$version (versionCode $version_code) is on '$track' ($status)."

# ─── 4. read back ────────────────────────────────────────────────────────────
header "Read back"
eid=$(http POST "$api/edits" | jq -r .id)
after=$(http GET "$api/edits/$eid/tracks")
http DELETE "$api/edits/$eid" >/dev/null
print_track_report "$after"
echo
if [ "$status" = "draft" ]; then
  if [ "$(serves "$after" "$track" "$version_code" "draft")" -gt 0 ]; then
    ok "'$track' holds versionCode $version_code as a DRAFT — nothing is live yet."
    echo "  Play Console → Production → Releases → the draft → Review release → Start rollout."
  else
    err "'$track' does not report a draft carrying versionCode $version_code — check Play Console → Production."
    exit 4
  fi
elif [ "$(serves "$after" "$track" "$version_code" "inProgress,completed")" -gt 0 ]; then
  ok "'$track' serves versionCode $version_code."
  [ "$status" = "inProgress" ] && warn "Staged rollout at $rollout — raise it to 100 % in Play Console → Production."
  echo "  Watch review + rollout at Play Console → Production."
else
  err "'$track' does not report an active release carrying versionCode $version_code — check Play Console → Production."
  exit 4
fi
