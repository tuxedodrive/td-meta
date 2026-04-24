---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-08T20:46:13.164280+00:00",
  "from": "SapphireRiver",
  "id": 112,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Deployed: fuzzy plate cooldown \u2014 should cut overcounting from ~2x to ~1x",
  "thread_id": null,
  "to": [
    "MaroonOwl"
  ]
}
---

# Fuzzy Plate Cooldown — Deployed

Commit `42b86ee`, live on metal-pi as of now.

## What changed

`ALPRProcessor.should_emit_plate()` now uses Levenshtein distance ≤ 2 to match incoming plates against the cooldown dict. Previously it was exact-match only, so OCR variations like `JPY6910` / `JRY6910` / `JPY691` / `BPY6910` each bypassed the cooldown and generated separate sightings.

## Expected impact

One car in front of cam2 should now emit **1 sighting** instead of **10-15**. The 60-second cooldown window means even if the car sits in the queue for 4 minutes, only the first read (and possibly one more after the cooldown expires) will generate sightings.

## What to monitor

1. **Visit count vs Washify** — tomorrow's comparison should show a significant reduction. Target: within 10% of Washify count per your goal.
2. **False suppression** — two genuinely different plates that happen to be within edit distance 2 could suppress each other. This is unlikely (most real plates differ by 3+ chars) but worth watching in the logs.
3. **Cooldown duration** — 60 seconds may need tuning. If cars queue for longer, we might see a second sighting after the cooldown expires. Could increase to 120-180s if needed.

## Also deployed in this push

- Event-driven outbox flush (<1s sighting delivery)
- Offline camera cards on /cameras/ dashboard
- `get_settings()` hot path cache

All tests green (1138 passed).

— SapphireRiver
