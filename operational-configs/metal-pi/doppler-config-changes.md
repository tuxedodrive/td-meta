---
date: 2026-04-28
title: Doppler config changes for leaked-keys rotation
author: agent prep for JPB
status: rotation-pending
tags: [security, secrets, rotation, doppler]
---

# Doppler config changes — 2026-04-28 leaked-keys rotation

ABOUTME: What JPB needs to change in the Doppler dashboard so the Pi can pick up
ABOUTME: rotated secrets via EnvironmentFile + doppler run, with no hardcoded keys.

## Project: `td-edge`

### Configs in play

```
td-edge
├── dev                                       # local dev + Pi when running in dev mode
├── stg                                       # staging base
│   └── stg_advance-jamaica_queens-lane_1     # metal-pi when running in stg
└── prd                                       # production base
    └── prd_advance-jamaica_queens-lane_1     # metal-pi when running in prd
```

### Service tokens to mint

| Token name | Config it points at | Stored on Pi at |
|------------|---------------------|-----------------|
| `metal-pi-dev`  | `dev`  (or `dev_advance-jamaica_queens-lane_1` if branched) | `/etc/td-edge/doppler.env` when `TD_EDGE_ENVIRONMENT=development` |
| `metal-pi-stg`  | `stg_advance-jamaica_queens-lane_1`                          | `/etc/td-edge/doppler.env` when `TD_EDGE_ENVIRONMENT=staging` |
| `metal-pi-prd`  | `prd_advance-jamaica_queens-lane_1`                          | `/etc/td-edge/doppler.env` when `TD_EDGE_ENVIRONMENT=production` |

The Pi only needs ONE token loaded at any given time. Switching between dev /
stg / prd means rewriting `/etc/td-edge/doppler.env` and restarting td-edge.
No code change needed, no unit edit needed.

### Secrets to set / rotate

#### `dev` config

| Key | Action | Notes |
|-----|--------|-------|
| `TD_EDGE_DEV_API_KEY` | SET (new value) | Distinct from prd. 64 char hex. Was previously hardcoded in a systemd drop-in; now Doppler-injected like every other secret. |
| `TD_EDGE_ENVIRONMENT` | SET | `development` |

#### `prd` config (or `prd_advance-jamaica_queens-lane_1`)

| Key | Action | Notes |
|-----|--------|-------|
| `TD_EDGE_PRODUCTION_API_KEY` | SET (new value) | Distinct from dev. 64 char hex. Old value was identical to dev — rotation MUST split them. |
| `TD_EDGE_ENVIRONMENT` | SET | `production` |
| `TD_EDGE_CARCHECK_API_KEY` | ROTATE | Per #3 / #4 in the rotation list. CarCheck dashboard → revoke → mint → paste here. |

### Tokens to revoke

| Token | Why |
|-------|-----|
| Old `prd` service token (`dp.st.prd.l3bOaxY6...`) | Leaked via `ps -eo command` on 2026-04-27. Revoke AFTER the new token is verified working on the Pi (so we don't tear down the running service before the replacement is live). |
| Any `dev` token tied to the old hardcoded `TD_EDGE_DEV_API_KEY=599d51f6...` | Defense in depth — even though the value lived in systemd, not Doppler, refresh the token. |

## How the unit picks dev vs prd

The proposed `td-edge.service` is environment-agnostic. The Pi's actual env is
determined by which Doppler token sits in `/etc/td-edge/doppler.env`.

To switch:

```bash
# To dev:
echo "DOPPLER_TOKEN=<DEV_TOKEN>" | sudo tee /etc/td-edge/doppler.env
sudo chmod 600 /etc/td-edge/doppler.env
sudo chown root:root /etc/td-edge/doppler.env
sudo systemctl restart td-edge

# To prd:
echo "DOPPLER_TOKEN=<PRD_TOKEN>" | sudo tee /etc/td-edge/doppler.env
sudo chmod 600 /etc/td-edge/doppler.env
sudo chown root:root /etc/td-edge/doppler.env
sudo systemctl restart td-edge
```

`TD_EDGE_ENVIRONMENT` is set IN the matching Doppler config, so the Pi always
agrees with itself: dev token → `TD_EDGE_ENVIRONMENT=development`, prd token
→ `TD_EDGE_ENVIRONMENT=production`. No risk of dev key + prd env or vice versa.

## What this retires

From `td-core/docs/plans/2026-04-28-leaked-keys-rotation.md`:

- Gap A — Doppler token in `/proc/cmdline` (fixed by `EnvironmentFile`)
- Gap B — `TD_EDGE_DEV_API_KEY` hardcoded in systemd drop-in (fixed by deleting the drop-in + injecting via Doppler dev)
- Gap C — Dev and prd API keys identical (fixed by minting two distinct values during rotation)
