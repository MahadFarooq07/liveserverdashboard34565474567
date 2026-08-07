#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
activity_file="$repo_root/ACTIVITY.md"
backup_file="$(mktemp)"
cp "$activity_file" "$backup_file"

cleanup() {
  cp "$backup_file" "$activity_file"
  rm -f "$backup_file"
}
trap cleanup EXIT

test_date="2099-12-31"
test_timestamp="2099-12-31 21:37:00 EST"

ACTIVITY_DATE="$test_date" ACTIVITY_TIMESTAMP="$test_timestamp" \
  "$repo_root/scripts/update-activity.sh"

first_count="$(grep -Fc "| $test_date | $test_timestamp |" "$activity_file")"
if [[ "$first_count" -ne 1 ]]; then
  echo "Expected one activity entry after the first run; found $first_count." >&2
  exit 1
fi

ACTIVITY_DATE="$test_date" ACTIVITY_TIMESTAMP="$test_timestamp" \
  "$repo_root/scripts/update-activity.sh"

second_count="$(grep -Fc "| $test_date | $test_timestamp |" "$activity_file")"
if [[ "$second_count" -ne 1 ]]; then
  echo "Expected the second run to be idempotent; found $second_count entries." >&2
  exit 1
fi

echo "update-activity.sh passed all tests."

