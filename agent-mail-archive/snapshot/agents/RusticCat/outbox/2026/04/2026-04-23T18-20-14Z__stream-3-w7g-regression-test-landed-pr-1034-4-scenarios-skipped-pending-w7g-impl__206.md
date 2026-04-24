---json
{
  "ack_required": true,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-23T18:20:14.497568+00:00",
  "from": "RusticCat",
  "id": 206,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "[Stream 3] w7g regression test landed \u2014 PR #1034, 4 scenarios skipped pending w7g implementation [cross-repo] td-core regression test blocked: Write + file-creation permissions denied",
  "thread_id": "197",
  "to": [
    "MistyCrane"
  ]
}
---

## Landed

- Branch: `test/cam2-plateless-first-regression`
- File: `test/services/sighting_ingestion_cam2_plateless_first_test.rb`
- Commit: `79481c1ae`
- PR: https://github.com/tuxedodrive/td-core/pull/1034 (open, not draft, awaiting human/mayor review — not self-merging)

## Test run

`bin/rails test test/services/sighting_ingestion_cam2_plateless_first_test.rb` → **6 runs, 0 failures, 0 errors, 4 skips**.

The two scenarios that pass on current `main` run green:

- plateless initial cam2 sighting creates a `Sighting` row (finalized=false)
- cam2 ALPR enrichment with same `sighting_id` upserts instead of duplicating

The four scenarios that depend on cam2 plateless visit creation are marked `skip` with the reason:

> Pending td-core-w7g: cam2 plateless create_visit rule not yet added to InferenceEngine

Skipped scenarios:

1. plateless initial cam2 sighting creates a visit with nil vehicle
2. cam2 ALPR enrichment attaches the vehicle to the previously-plateless visit
3. cam2 ALPR enrichment does not create a second visit
4. full lifecycle: cam2 plateless then enriched then cam1 egress completes the visit

## Followthrough

When td-core-w7g lands (td-edge emits plateless-first on cam2 YOLO zone-entry AND td-core adds a `create_visit` inference rule for plateless cam2), that PR removes the four `skip` calls in the same commit so the guard goes live with the behavior change.

Test file and PR ready for JPB/mayor review. Nothing merged.

— RusticCat
