#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
activity_file="$repo_root/ACTIVITY.md"
timezone="${ACTIVITY_TIMEZONE:-America/Toronto}"
activity_date="${ACTIVITY_DATE:-$(TZ="$timezone" date +%F)}"
activity_timestamp="${ACTIVITY_TIMESTAMP:-$(TZ="$timezone" date '+%Y-%m-%d %H:%M:%S %Z')}"

if grep -Fq "| $activity_date |" "$activity_file"; then
  echo "Activity for $activity_date is already recorded."
  exit 0
fi

printf '| %s | %s |\n' "$activity_date" "$activity_timestamp" >> "$activity_file"
echo "Recorded activity for $activity_date."

