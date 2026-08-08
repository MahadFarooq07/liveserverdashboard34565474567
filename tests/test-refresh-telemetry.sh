#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
telemetry_file="$repo_root/telemetry/STATUS_HISTORY.md"
backup_file="$(mktemp)"
cp "$telemetry_file" "$backup_file"

cleanup() {
  cp "$backup_file" "$telemetry_file"
  rm -f "$backup_file"
}
trap cleanup EXIT

probe_windows=(
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
  for window in "${probe_windows[@]}"; do
    index="$((index + 1))"
    TELEMETRY_DATE="$test_date" \
    TELEMETRY_TIMESTAMP="$test_date probe-$index EST" \
    TELEMETRY_EVENT="schedule" \
    TELEMETRY_SLOT="$window" \
      "$repo_root/scripts/refresh-telemetry.sh" >/dev/null
  done
}

assert_snapshot_count() {
  local test_date="$1"
  local expected_count="$2"
  local actual_count
  actual_count="$(grep -Fc "| $test_date |" "$telemetry_file" || true)"
  if [[ "$actual_count" -ne "$expected_count" ]]; then
    echo "Expected $expected_count snapshots for $test_date; found $actual_count." >&2
    exit 1
  fi
}

# Known dates exercise one-, four-, and five-probe sampling plans.
run_scheduled_day "2099-01-01"
run_scheduled_day "2099-01-04"
run_scheduled_day "2099-01-09"

# Replaying all windows must remain idempotent.
run_scheduled_day "2099-01-01"

# A manual collection publishes once, while retrying that run stays safe.
TELEMETRY_DATE="2099-12-31" TELEMETRY_TIMESTAMP="2099-12-31 manual EST" \
TELEMETRY_EVENT="workflow_dispatch" TELEMETRY_RUN_ID="12345" \
  "$repo_root/scripts/refresh-telemetry.sh" >/dev/null
TELEMETRY_DATE="2099-12-31" TELEMETRY_TIMESTAMP="2099-12-31 manual EST" \
TELEMETRY_EVENT="workflow_dispatch" TELEMETRY_RUN_ID="12345" \
  "$repo_root/scripts/refresh-telemetry.sh" >/dev/null

assert_snapshot_count "2099-01-01" 1
assert_snapshot_count "2099-01-04" 4
assert_snapshot_count "2099-01-09" 5
assert_snapshot_count "2099-12-31" 1

echo "refresh-telemetry.sh passed all tests."

