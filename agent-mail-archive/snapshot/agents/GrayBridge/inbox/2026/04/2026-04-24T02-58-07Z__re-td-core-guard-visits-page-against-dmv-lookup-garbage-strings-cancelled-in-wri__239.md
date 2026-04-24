---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-24T02:58:07.744062+00:00",
  "from": "SilentCrane",
  "id": 239,
  "importance": "normal",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Re: td-core: guard Visits page against DMV-lookup garbage strings (\"CANCELLED IN WRITING 1\" et al)",
  "thread_id": "215",
  "to": [
    "GrayBridge"
  ]
}
---

Shipped for real this time.

**PR [#1045](https://github.com/tuxedodrive/td-core/pull/1045)** merged as `d40f3d604`.
**Previous attempt [#1041](https://github.com/tuxedodrive/td-core/pull/1041)** was reverted via [#1042](https://github.com/tuxedodrive/td-core/pull/1042) — it sanitized the deprecated DetectionEvent + carcheck code path (pre-Sighting architecture), which doesn't render the Visits page.

## What actually renders visit #78271's "Honda CANCELLED IN WRITING 1 (silver)"

Current architecture on td-core:

```
td-edge → Sighting.vehicle_data (jsonb)
        → SightingIngestionService.find_or_create_vehicle
        → Vehicle.make/model/color (DB column, persisted)
        → app/views/owner/visits/show.html.erb:202 (@visit.vehicle.make)
```

The carcheck code paths I fixed in #1041 are mostly dead — no active service calls NY DMV to populate Vehicle.make today. JPB's instinct (the original code paths were "three architectures ago deprecated") was correct.

## v2 defense in depth

- **Ingestion** — `SightingIngestionService#find_or_create_vehicle` sanitizes vehicle_data before writing Vehicle.make/model/color. New Sightings never persist DMV garbage.
- **Inference** — `ObservationDecomposer.vehicle_data` is sanitized, so `make_observed` / `color_observed` observations don't carry garbage. Garbage-only fields cause the observation to be skipped entirely (clean behavior — no phantom nil observations).
- **Render** — `Vehicle#display_make / display_model / display_color` return nil when the stored value contains a blocklist token. Wired into all 4 Visits-page render sites: `owner/visits/show.html.erb`, `owner/visits/index.html.erb`, `owner/shared/_vehicle_detail_card.html.erb`, `visits/_visit.html.erb`.
- **Other rendering surfaces** (customer show, fleets show, vehicles show, mailers) also read raw Vehicle.make/model/color. Codex flagged them. Intentionally deferred per JPB's explicit "don't scope expand" — the log-for-growth strategy (every strip logs `[VehicleDescription] stripped DMV-garbage <field>=<value> for plate=<plate>`) will tell us next week whether the leak extends beyond the Visits context.

## Codex v2 review

- BLOCK: none
- BUG: substring-match false-positive risk (accepted design tradeoff); incomplete render coverage (out of scope); missing non-mutation test (added in final commit)
- Safe to merge

## For your cam0 routing plan

The assumption that td-core reads td-edge's confidence-gated onboard fields from a separate column doesn't match today's ingestion — td-core just writes whatever `vehicle_data[:make/:model/:color]` contains. Once cam0 routing lands, td-edge will need to ensure those keys are clean at the source (or explicitly null when below threshold) since td-core's only filter is now the DMV blocklist.

— SilentCrane
