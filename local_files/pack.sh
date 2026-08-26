#!/usr/bin/env bash
# Pack / unpack everything a fresh clone needs but git does not carry.
#
#   bash local_files/pack.sh pack   [--plain] [OUT]   # default OUT: ~/Desktop/twelve_steps_local_files.tar.gz.enc
#   bash local_files/pack.sh unpack [ARCHIVE]         # default ARCHIVE: the same path
#   bash local_files/pack.sh list                     # show what would be packed and what is missing
#
# The archive holds two groups, both restored to their original repo paths:
#   1. local_files/*  — keystores, OAuth configs, store credentials, LOCAL_SETUP.md
#                       (irreplaceable; this script and README.md are tracked and skipped)
#   2. Regenerable platform files that `flutter create` would otherwise stub with
#      placeholders (launcher icons, launch images, MainActivity, gradle wrapper).
#
# `pack` encrypts with AES-256 (openssl, password prompt — or $PACK_PASSWORD for
# non-interactive use) unless --plain is given.
# `unpack` detects .enc by extension, restores the files, re-creates the Dart
# symlink for desktop_oauth_config.dart, and never overwrites without asking.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"
DEFAULT_OUT="$HOME/Desktop/twelve_steps_local_files.tar.gz.enc"
DART_LINK="lib/shared/services/google_drive/desktop_oauth_config.dart"
DART_TARGET="../../../../local_files/desktop_oauth_config.dart"

# Regenerable platform paths, packed from their in-place locations.
EXTRAS=(
  android/app/src/main/res
  android/app/src/main/kotlin
  android/app/src/debug
  android/gradle
  android/gradlew
  android/gradlew.bat
  ios/Runner/Assets.xcassets
  ios/Runner/Base.lproj
  pubspec.lock
)

PASS_ARGS=(); [ -n "${PACK_PASSWORD:-}" ] && PASS_ARGS=(-pass env:PACK_PASSWORD)

err() { printf '\033[31m%s\033[0m\n' "$*" >&2; }
info() { printf '\033[36m%s\033[0m\n' "$*"; }

collect() {
  # Prints the repo-relative paths to archive, one per line.
  local f
  for f in local_files/*; do
    case "$(basename "$f")" in pack.sh|README.md) continue ;; esac
    [ -e "$f" ] && printf '%s\n' "$f"
  done
  for f in "${EXTRAS[@]}"; do
    [ -e "$f" ] && printf '%s\n' "$f"
  done
}

cmd_list() {
  info "Will pack:"; collect | sed 's/^/  /'
  local missing=0 f
  for f in my-release-key.jks debug.keystore key.properties google-services_debug.json \
           google-services_release.json desktop_oauth_config.dart LOCAL_SETUP.md \
           play-service-account.json asc_issuer app_sp_pw; do
    [ -e "local_files/$f" ] || { err "  missing: local_files/$f"; missing=1; }
  done
  ls local_files/AuthKey_*.p8 >/dev/null 2>&1 || { err "  missing: local_files/AuthKey_<KEYID>.p8"; missing=1; }
  [ "$missing" = 0 ] && info "All expected credential files present."
  return 0
}

cmd_pack() {
  local plain=0 out=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --plain) plain=1 ;;
      *) out="$1" ;;
    esac; shift
  done
  if [ -z "$out" ]; then
    out="$DEFAULT_OUT"; [ "$plain" = 1 ] && out="${out%.enc}"
  fi
  local files; files="$(collect)"
  [ -n "$files" ] || { err "nothing to pack"; exit 1; }
  mkdir -p "$(dirname "$out")"
  if [ "$plain" = 1 ]; then
    printf '%s\n' "$files" | tar -czf "$out" -T -
  else
    command -v openssl >/dev/null || { err "openssl not found; use --plain"; exit 1; }
    printf '%s\n' "$files" | tar -czf - -T - \
      | openssl enc -aes-256-cbc -pbkdf2 -salt "${PASS_ARGS[@]}" -out "$out"
  fi
  chmod 600 "$out"
  info "Packed $(printf '%s\n' "$files" | wc -l | tr -d ' ') paths -> $out"
  [ "$plain" = 1 ] && err "Unencrypted: contains keystores and passwords. Move it over an encrypted channel and delete it afterwards."
  return 0
}

cmd_unpack() {
  local archive="${1:-$DEFAULT_OUT}"
  [ ! -f "$archive" ] && [ -f "${archive%.enc}" ] && archive="${archive%.enc}"
  [ -f "$archive" ] || { err "archive not found: $archive"; exit 1; }

  # Refuse to clobber silently.
  local existing=""
  if [ -d local_files ] && [ -n "$(collect)" ]; then
    existing="$(collect | tr '\n' ' ')"
    err "These paths already exist and will be overwritten:"; printf '  %s\n' $existing
    read -r -p "Continue? [y/N] " a; [[ "$a" =~ ^[Yy]$ ]] || exit 1
  fi

  if [[ "$archive" == *.enc ]]; then
    openssl enc -d -aes-256-cbc -pbkdf2 "${PASS_ARGS[@]}" -in "$archive" | tar -xzf - -C "$ROOT"
  else
    tar -xzf "$archive" -C "$ROOT"
  fi

  # The Dart file must be reachable from inside lib/; a symlink keeps one copy.
  if [ -f local_files/desktop_oauth_config.dart ]; then
    rm -f "$DART_LINK"
    ln -s "$DART_TARGET" "$DART_LINK"
  fi
  chmod 600 local_files/* 2>/dev/null || true
  chmod +x local_files/pack.sh android/gradlew 2>/dev/null || true

  info "Restored into $ROOT. Next:"
  cat <<'EOF'
  flutter pub get
  dart run build_runner build --delete-conflicting-outputs
  flutter build apk --debug && flutter build apk --release
  (full runbook: local_files/LOCAL_SETUP.md)
EOF
}

case "${1:-}" in
  pack)   shift; cmd_pack "$@" ;;
  unpack) shift; cmd_unpack "$@" ;;
  list)   cmd_list ;;
  *) sed -n '2,17p' "$0"; exit 1 ;;
esac
