#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
activity_file="$repo_root/ACTIVITY.md"
timezone="${ACTIVITY_TIMEZONE:-America/Toronto}"
activity_date="${ACTIVITY_DATE:-$(TZ="$timezone" date +%F)}"
activity_timestamp="${ACTIVITY_TIMESTAMP:-$(TZ="$timezone" date '+%Y-%m-%d %H:%M:%S %Z')}"
activity_event="${ACTIVITY_EVENT:-workflow_dispatch}"
activity_slot="${ACTIVITY_SLOT:-}"
activity_run_id="${ACTIVITY_RUN_ID:-local}"

schedule_slots=(
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

if [[ "$activity_event" == "schedule" ]]; then
  slot_number=0
  for index in "${!schedule_slots[@]}"; do
    if [[ "${schedule_slots[$index]}" == "$activity_slot" ]]; then
      slot_number="$((index + 1))"
      break
    fi
  done

  if [[ "$slot_number" -eq 0 ]]; then
    echo "Unknown scheduled slot: $activity_slot" >&2
    exit 1
  fi

  daily_bucket="$(hash_value "$activity_date")"
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

  selected_slots="$({
    for index in "${!schedule_slots[@]}"; do
      score="$(printf '%s' "$activity_date:${schedule_slots[$index]}" | sha256sum | cut -d' ' -f1)"
      printf '%s %s\n' "$score" "$((index + 1))"
    done
  } | sort | head -n "$target_count" | cut -d' ' -f2)"

  if ! grep -Fxq "$slot_number" <<< "$selected_slots"; then
    echo "Slot $slot_number was not selected for $activity_date ($target_count planned commits)."
    exit 0
  fi

  activity_key="scheduled-$slot_number"
  echo "Slot $slot_number selected for $activity_date ($target_count planned commits)."
else
  activity_key="manual-$activity_run_id"
fi

if grep -F "| $activity_date |" "$activity_file" | grep -Fq "| $activity_key |"; then
  echo "Activity key $activity_key is already recorded."
  exit 0
fi

printf '| %s | %s | %s |\n' "$activity_date" "$activity_timestamp" "$activity_key" >> "$activity_file"
echo "Recorded $activity_key for $activity_date."
