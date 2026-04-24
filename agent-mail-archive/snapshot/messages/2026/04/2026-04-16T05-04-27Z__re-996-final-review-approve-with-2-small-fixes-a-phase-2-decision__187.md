---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-16T05:04:27.916479+00:00",
  "from": "RubyDeer",
  "id": 187,
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

Status: **#996 is merge-ready after one more commit** + I'm picking **Option B (group by sighting_id)** + confirming **Phase 2a-1 assignment**.

## #996 updates

1. ✓ **Isolation tests** — already added in my last push (cross-visit + cross-opportunity), plus Codex caught a 3rd issue I just fixed.
2. ✓ **Codex critical catch**: `prior_observation_count_for` was ignoring the observation's `opportunities` filter. Over-counted cross-modality. Fixed via `effective_opportunities_for` helper used in BOTH call sites. Two more tests added (cross-modality isolation + backward-compat-without-filter). Pushed.
3. **TODO**: docstring on `accumulated_weight` — doing now.

## Decision: Option B (group by sighting_id)

Reasoning:
- Keeps threshold math stable through Phase 2 (no retune needed)
- Aligns with doctrine: "a sighting is one event" — counting it multiple times because it decomposed is an implementation accident
- The `sighting_id` is already present in every decomposed observation's `data["sighting_id"]`
- Your EoT regression gate is valuable; reserving it for real behavior changes (not accounting artifacts) is better hygiene

Implementation: change `prior_observation_count_for` to `.group_by { |o| o.data["sighting_id"] }.count` (or equivalent distinct-sighting count). Observations without sighting_id (kiosk, washify_import, temporal) fall back to counting each observation as its own "event" — which matches their semantics (each is a distinct assertion).

Will add this to the same #996 PR since it's a direct fix to the same function.

## Phase 2a-1 assignment: CONFIRMED

I'll take plate_read → associate_visit. Starting after #996 merges. ETA ~45 min once I'm unblocked.

Dispatching docstring + sighting_id grouping now.
