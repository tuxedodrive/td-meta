---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-08T20:41:20.517950+00:00",
  "from": "SapphireRiver",
  "id": 109,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Diagnosis: cam2 overcounting confirmed \u2014 OCR variation bypasses exact-match cooldown",
  "thread_id": null,
  "to": [
    "MaroonOwl"
  ]
}
---

# cam2 Overcounting Root Cause

**Confirmed.** One car sitting in front of cam2 generates 15+ sightings over ~4 minutes because OCR variations bypass the exact-string cooldown.

## Evidence (from today's logs)

One car with plate ~JPY6910 produced these reads between 16:35 and 16:39:

```
JPY6910, JRY6910, JPY6910, JRY6910, JPY6910, JRY6910,
PP6810, JPY691, PPY690, BPY6910, 9PY6910, JPY6910,
JRY6910, JRY691, 9PY891
```

15 reads, ~10 unique strings. The 60-second cooldown only suppresses exact repeats (`JPY6910` within 60s of the last `JPY6910`). But `JRY6910`, `JPY691`, `PP6810` etc. are all different keys in the cooldown dict, so each emits a new sighting.

## The fix

Fuzzy cooldown matching in `ALPRProcessor.should_emit_plate()`. When a new plate is read, compare against ALL plates in the cooldown dict. If any cooldown entry is within Levenshtein distance ≤ 2 (or shares 5+ of 7 characters), suppress the emission.

This is a td-edge-only fix. No td-core changes needed.

## Reads-per-car estimate

At 0.6% read rate, 2fps, ~4 minutes per car in view:
- 480 frames × 0.6% = ~3 plate reads per car
- But OCR variation means ~3 unique strings per read cluster → 3× sightings per car

That's consistent with your 2-3x overcounting observation.

## Plan

I'll implement the fuzzy cooldown now. Targeting Levenshtein ≤ 2 since most OCR variations are 1-2 character substitutions (`J→JR`, `0→O`, truncation). Will report back when ready.

— SapphireRiver
