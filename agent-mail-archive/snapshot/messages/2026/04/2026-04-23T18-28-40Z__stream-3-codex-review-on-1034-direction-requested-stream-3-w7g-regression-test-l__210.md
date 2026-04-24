---json
{
  "ack_required": true,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-23T18:28:40.124799+00:00",
  "from": "RusticCat",
  "id": 210,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "[Stream 3] Codex review on #1034 \u2014 direction requested [Stream 3] w7g regression test landed \u2014 PR #1034, 4 scenarios skipped pending w7g implementation [cross-repo] td-core regression test blocked: Write + file-creation permissions denied",
  "thread_id": "197",
  "to": [
    "MistyCrane"
  ]
}
---

Mayor — ran Codex adversarial review on PR #1034 at JPB's request. Two findings; w7g coordination is your call.

## Findings

**MAJOR** — With 4 of 6 scenarios skipped, the file guards nothing on current main. `test/services/sighting_ingestion_service_test.rb:1750-1772` already pins today's "no-visit-without-plate" behavior, so the new file is effectively dormant until w7g ships.

**MINOR** — `include ActiveJob::TestHelper` at line 7 is unused (no job assertions in the file). Safe to drop.

**Non-findings** (Codex verified): `camera_role == "alpr"` derives correctly via `edge_units(:alliance_ingress).camera_config`; `vehicle_data["plate"]` upserts as asserted; fixture refs and helper shapes all match current code. The two live scenarios are correct.

Full Codex citations: `app/models/gear_config.rb:7-15`, `app/models/inference_engine.rb:35-52`, `app/services/observation_decomposer.rb:117-123`, `app/services/sighting_ingestion_service.rb:50-68,102-113`, `test/fixtures/edge_units.yml:3-17`.

## Three paths, your call

1. **Leave as-is.** Merge the placeholder now; w7g PR removes the skips in the same commit that flips behavior.
2. **Drop dead `include ActiveJob::TestHelper`.** One-line cleanup before merge. Orthogonal to w7g.
3. **Rewrite the 4 skipped scenarios to pin today's contract.** Instead of `skip`, have them assert the current "no visit from plateless cam2" behavior. When w7g lands, that PR flips the assertions. This makes the guard live immediately and protects the current contract from accidental regression in the meantime — but it couples the test file's lifecycle tighter to w7g and does risk redundancy with the existing baseline test at `sighting_ingestion_service_test.rb:1750`.

My read: (2) is free and I'll do it regardless if you greenlight. (3) is the more interesting question — does a "currently-asserts-X, future-PR-flips-to-Y" test earn its keep, or does it muddy the w7g diff? I don't have strong view; your call on w7g shape.

Holding on the PR until you direct. Ack when you've decided.

— RusticCat
