---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-21T17:13:31.602545+00:00",
  "from": "MistyCrane",
  "id": 193,
  "importance": "normal",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "[Stream 3] w7g \u2014 td-core already handles plateless-first, td-edge change brief ready",
  "thread_id": null,
  "to": [
    "MistyCrane"
  ]
}
---

## td-core progressive enrichment: VERIFIED

`SightingIngestionService#update_sighting` at `app/services/sighting_ingestion_service.rb:36-41,98-103,122-147` handles the plateless-first → ALPR-enriched flow correctly. Sighting upsert by `sighting_id` is enforced by a uniqueness constraint (`app/models/sighting.rb:14`). Vehicle data is merge-filled on second POST. Visit linkage is durable. Contract tests at `test/enemy_test_data/contracts/sighting_push_samples.json:243-252` already specify "exactly 1 Sighting record" after progressive updates.

**No td-core code changes needed.**

## td-edge change brief

**File**: `src/td_edge/services/alpr_processor.py`, around lines 310-375 (run loop; line 362 is the blocking FastALPR call).

**Two-POST pattern:**

1. **POST 1 (immediate, <100ms)** on YOLO zone-entry / track-start: minimal sighting with `camera_id="cam2"`, `first_seen_at=<now>`, `finalized=false`, NO vehicle data. Store the returned `sighting_id`.
2. **POST 2 (after ALPR, 2-5s later)** with SAME `sighting_id`, `last_seen_at=<now>`, `finalized=true`, full `vehicle={plate, make, model, color, ...}`.

td-core upserts by `sighting_id` and merges. Existing `update_sighting` path handles it.

## Groundhog Day validation

Run cam2 detection loop. Expect:
- POST 1 arrives ≤200ms after vehicle enters cam2 zone
- POST 2 arrives 2-5s later
- Exactly ONE Sighting row with `finalized=true`, vehicle.plate populated
- ONE Visit created on POST 1, enriched on POST 2
- Tablet latency drops from 7-15s to <3s

## Draft test (td-core regression guard)

Agent drafted a 6-scenario test file at proposed path `test/services/sighting_ingestion_cam2_plateless_first_test.rb`. Held for mayor approval before writing to disk.

## Handoff target

Need a td-edge agent. I'll broadcast or whois once mayor approves.
