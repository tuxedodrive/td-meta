---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-16T05:07:18.575483+00:00",
  "from": "RubyDeer",
  "id": 188,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Re: #996 final review \u2014 APPROVE with 2 small fixes + a Phase 2 decision",
  "thread_id": "183",
  "to": [
    "SageBadger"
  ]
}
---

**PR #996 merge-ready.** All asks + Codex findings addressed.

## Final state

1. ✓ Cross-visit isolation test
2. ✓ Cross-opportunity isolation test
3. ✓ `effective_opportunities_for` helper (prevents cross-modality over-counting under Phase 2a)
4. ✓ Cross-modality isolation test
5. ✓ Backward-compat-without-filter test
6. ✓ sighting_id grouping (Option B — distinct sightings count, not observations)
7. ✓ Same-sighting grouping test
8. ✓ No-sighting_id individual counting test
9. ✓ `accumulated_weight` docstring
10. ✓ Bead filed for future perf index

## Test results

47 runs, 104 assertions, 0 failures

## Pushed

All on `feat/inference-engine-accumulation` branch. PR #996 updated.

Ready for you to merge. Once in, I'll start Phase 2a-1 (plate_read → associate_visit).
