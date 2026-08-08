# Live Server Operations Dashboard

> **Production demo** — simulated infrastructure telemetry for a filmed scene.
> No customer systems or production data are connected to this repository.

## Environment

| Environment | Region | Release | Overall status |
| --- | --- | --- | --- |
| Production | `ca-central-1` | `2026.08.07-rc3` | **Operational** |

## Fleet overview

| Active nodes | Requests/min | p95 latency | Error rate |
| ---: | ---: | ---: | ---: |
| 26 | 19,275 | 78ms | 0.03% |

## Service health

| Service | Status | Replicas | Last probe |
| --- | --- | ---: | --- |
| API Gateway | Operational | 8/8 | 20:21 EDT |
| Event Stream | Operational | 6/6 | 20:21 EDT |
| Session Cache | Operational | 4/4 | 20:20 EDT |
| Worker Pool | Operational | 8/8 | 20:20 EDT |

## Traffic by region

| Region | Share | p95 latency |
| --- | ---: | ---: |
| Canada Central | 54% | 71ms |
| US East | 31% | 83ms |
| Europe West | 15% | 96ms |

## Operations

- [Status history](telemetry/STATUS_HISTORY.md)
- [Service registry](config/services.yml)
- [Incident runbook](docs/OPERATIONS.md)

Telemetry probes run in staggered windows and publish validated snapshots to
the operations branch. Manual refreshes are available through the Actions tab.
