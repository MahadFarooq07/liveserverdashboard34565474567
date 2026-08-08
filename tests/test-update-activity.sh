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

schedule_slots=(
  "11 7 * * *"
  "37 9 * * *"
  "23 12 * * *"
  "59 14 * * *"
  "41 17 * * *"
  "17 20 * * *"
  "43 22 * * *"
)

run_scheduled_day() {
  local test_date="$1"
  local index=0
  for slot in "${schedule_slots[@]}"; do
    index="$((index + 1))"
    ACTIVITY_DATE="$test_date" \
    ACTIVITY_TIMESTAMP="$test_date slot-$index EST" \
    ACTIVITY_EVENT="schedule" \
    ACTIVITY_SLOT="$slot" \
      "$repo_root/scripts/update-activity.sh" >/dev/null
  done
}

assert_day_count() {
  local test_date="$1"
  local expected_count="$2"
  local actual_count
  actual_count="$(grep -Fc "| $test_date |" "$activity_file" || true)"
  if [[ "$actual_count" -ne "$expected_count" ]]; then
    echo "Expected $expected_count entries for $test_date; found $actual_count." >&2
    exit 1
  fi
}

# These dates exercise target counts of 1, 4, and 5 respectively.
run_scheduled_day "2099-01-01"
run_scheduled_day "2099-01-04"
run_scheduled_day "2099-01-09"

# Replaying every slot must not create duplicates.
run_scheduled_day "2099-01-01"

# A manual dispatch always creates one commit, while a retry of the same run
# remains idempotent.
ACTIVITY_DATE="2099-12-31" ACTIVITY_TIMESTAMP="2099-12-31 manual EST" \
ACTIVITY_EVENT="workflow_dispatch" ACTIVITY_RUN_ID="12345" \
  "$repo_root/scripts/update-activity.sh" >/dev/null
ACTIVITY_DATE="2099-12-31" ACTIVITY_TIMESTAMP="2099-12-31 manual EST" \
ACTIVITY_EVENT="workflow_dispatch" ACTIVITY_RUN_ID="12345" \
  "$repo_root/scripts/update-activity.sh" >/dev/null

assert_day_count "2099-01-01" 1
assert_day_count "2099-01-04" 4
assert_day_count "2099-01-09" 5
assert_day_count "2099-12-31" 1

echo "update-activity.sh passed all tests."
