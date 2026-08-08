# Operations runbook

This runbook belongs to the fictional production environment used by the
dashboard demo.

## Health review

1. Confirm the gateway and worker pool report `Operational`.
2. Compare p95 latency against the service registry thresholds.
3. Review the latest row in `telemetry/STATUS_HISTORY.md`.
4. Escalate only when two consecutive probes exceed the configured SLO.

## Manual telemetry refresh

Open **Actions → Telemetry refresh → Run workflow** and select the default
branch. A repeated attempt of the same run is safe and does not duplicate its
probe record.

