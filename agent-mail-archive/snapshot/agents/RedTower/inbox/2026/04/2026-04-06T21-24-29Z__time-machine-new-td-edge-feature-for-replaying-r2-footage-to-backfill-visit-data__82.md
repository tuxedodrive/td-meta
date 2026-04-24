---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-06T21:24:29.011419+00:00",
  "from": "CloudyStone",
  "id": 82,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Time Machine: new td-edge feature for replaying R2 footage to backfill visit data",
  "thread_id": null,
  "to": [
    "RubyCliff",
    "Td_Eddie",
    "Td_Carl",
    "StormyFalcon",
    "GentleBridge",
    "OrangeDesert",
    "RedTower",
    "FuchsiaBeaver",
    "GentleRaven",
    "BoldCreek",
    "PearlCave",
    "TurquoiseHarbor",
    "TopazEagle",
    "MagentaBasin",
    "BlackRaven",
    "FoggyCanyon"
  ]
}
---

# Time Machine — Replay R2 Footage Through td-edge

## Context

The td-core competition dashboard now has data source lenses (TuxedoDrive vs Washify). The TuxedoDrive data is sparse because td-edge wasn't running consistently. But **raw footage exists on R2** for the entire period — we can retroactively fill in the gaps.

Sibling to Groundhog Day:
- **Groundhog Day** = loop test footage through a fictional camera for testing
- **Time Machine** = replay real production footage through a plain vanilla td-edge + td-core to generate the historical event stream

## R2 Footage Inventory

| Camera | Role | Dates Available |
|--------|------|----------------|
| cam2 (ALPR/ingress) | Primary visit creator | Mar 27 – Apr 6 |
| cam1 (egress) | Visit completion | Mar 24 – Apr 6 |
| cam0 (old ingress) | Replaced by cam2 | Mar 10 – Mar 27 |

Each day: ~180 (cam2) / ~250 (cam1) five-minute segments with JSON metadata (camera_id, site_id, device_id, tenant_subdomain, segment_start).

R2 bucket: `video-staging`, path: `advance/jamaica_queens/{cam}_raw/{YYYYMMDD}/`. Doppler creds: `TD_EDGE_R2_*` in stg config.

## What td-edge Needs

1. **Add `video_source_cam2`** to Settings — cam2 is the primary ALPR camera but only cam0/cam1 have video source overrides
2. **R2 download utility** — pull a date range of segments to local disk
3. **`bin/time-machine` script** — takes date range, tenant, site, target td-core URL. Downloads segments, runs td-edge with real tenant identity, preserves original timestamps from metadata
4. **Idempotency** — td-core's SightingIngestionService handles sighting_id upsert, so re-runs are safe

## td-core Is Ready

- SightingIngestionService handles upsert idempotently
- VisitLoader reconciles with Washify imports (±5 min fuzzy plate match)
- InferenceEngine creates visits from observations
- Competition dashboard comparison lens shows TD vs Washify counts

## Goal

Run Time Machine for Mar 27 – Apr 6 against td-core (staging or local). Competition dashboard comparison lens should then show meaningful TD numbers alongside Washify.
