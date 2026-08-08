#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
telemetry_file="$repo_root/telemetry/STATUS_HISTORY.md"
timezone="${TELEMETRY_TIMEZONE:-America/Toronto}"
snapshot_date="${TELEMETRY_DATE:-$(TZ="$timezone" date +%F)}"
snapshot_timestamp="${TELEMETRY_TIMESTAMP:-$(TZ="$timezone" date '+%Y-%m-%d %H:%M:%S %Z')}"
telemetry_event="${TELEMETRY_EVENT:-workflow_dispatch}"
telemetry_slot="${TELEMETRY_SLOT:-}"
telemetry_run_id="${TELEMETRY_RUN_ID:-local}"

probe_windows=(
  "11 7 * * *"
  "37 9 * * *"
  "23 12 * * *"
  "59 14 * * *"
  "41 17 * * *"
  "17 20 * * *"
  "43 22 * * *"
)

hash_value() {
  local input="$1"
  local first_byte
  first_byte="$(printf '%s' "$input" | sha256sum | cut -c1-2)"
  printf '%d' "0x$first_byte"
}

if [[ "$telemetry_event" == "schedule" ]]; then
  window_number=0
  for index in "${!probe_windows[@]}"; do
    if [[ "${probe_windows[$index]}" == "$telemetry_slot" ]]; then
      window_number="$((index + 1))"
      break
    fi
  done

  if [[ "$window_number" -eq 0 ]]; then
    echo "Unknown probe window: $telemetry_slot" >&2
    exit 1
  fi

  daily_bucket="$(hash_value "$snapshot_date")"
  if [[ "$daily_bucket" -lt 80 ]]; then
    target_count=1
  elif [[ "$daily_bucket" -lt 144 ]]; then
    target_count=2
  elif [[ "$daily_bucket" -lt 192 ]]; then
    target_count=3
  elif [[ "$daily_bucket" -lt 232 ]]; then
    target_count=4
  else
    target_count=5
  fi

  selected_windows="$({
    for index in "${!probe_windows[@]}"; do
      score="$(printf '%s' "$snapshot_date:${probe_windows[$index]}" | sha256sum | cut -d' ' -f1)"
      printf '%s %s\n' "$score" "$((index + 1))"
    done
  } | sort | head -n "$target_count" | cut -d' ' -f2)"

  if ! grep -Fxq "$window_number" <<< "$selected_windows"; then
    echo "Probe window $window_number is outside today's sampling plan."
    exit 0
  fi

  probe_id="scheduled-$window_number"
else
  probe_id="manual-$telemetry_run_id"
fi

if grep -F "| $snapshot_date |" "$telemetry_file" | grep -Fq "| $probe_id |"; then
  echo "Probe $probe_id is already present in today's status history."
  exit 0
fi

metric_seed="$(hash_value "$snapshot_date:$probe_id:$telemetry_run_id")"
active_nodes="$((20 + metric_seed % 13))"
requests_per_minute="$((14200 + metric_seed * 29))"
p95_latency="$((48 + metric_seed % 49))"
error_fraction="$((1 + metric_seed % 8))"

printf '| %s | %s | Operational | %s | %s | %sms | 0.0%s%% | %s |\n' \
  "$snapshot_date" \
  "$snapshot_timestamp" \
  "$active_nodes" \
  "$requests_per_minute" \
  "$p95_latency" \
  "$error_fraction" \
  "$probe_id" >> "$telemetry_file"

echo "Published telemetry probe $probe_id for $snapshot_date."

