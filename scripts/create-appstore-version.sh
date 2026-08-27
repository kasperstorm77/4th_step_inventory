#!/usr/bin/env bash
# create-appstore-version.sh — create the App Store version record for the
# release in pubspec.yaml, so attach-appstore-build.sh and
# set-appstore-release-notes.sh have something to write to.
#
# After a version goes READY_FOR_SALE nothing creates the next one; this is the
# "+" button in App Store Connect. Idempotent — an existing editable record is
# left alone. Does NOT attach a build or submit anything.
#
# Usage:
#   bash scripts/create-appstore-version.sh          # dry run
#   bash scripts/create-appstore-version.sh --yes    # create
#   bash scripts/create-appstore-version.sh --version 2.3.9
set -euo pipefail
cd "$(dirname "$0")/.."

apply=0; version=""
while (( $# )); do
  case "$1" in
    --version) shift; version="${1:?--version needs a value}" ;;
    -y|--yes)  apply=1 ;;
    -h|--help) sed -n '2,13p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
  shift
done

ssot=$(grep -m1 '^version:' pubspec.yaml | sed -E 's/version:[[:space:]]*//')
[ -n "$version" ] || version="${ssot%%+*}"

key="${ASC_KEY:-$(ls local_files/AuthKey_*.p8 2>/dev/null | head -1)}"
[ -n "$key" ] && [ -f "$key" ] || { echo "local_files/AuthKey_<KEYID>.p8 not found" >&2; exit 1; }
[ -f local_files/asc_issuer ] || { echo "./local_files/asc_issuer not found" >&2; exit 1; }

ASC_KEY="$key" \
ASC_KEY_ID="$(basename "$key" | sed -E 's/^AuthKey_(.+)\.p8$/\1/')" \
ASC_ISSUER_ID="$(tr -d ' \n' < local_files/asc_issuer)" \
ASC_VERSION="$version" ASC_APPLY="$apply" \
  node scripts/lib/asc-create-version.mjs
