---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-01T17:07:40.803318+00:00",
  "from": "BoldCreek",
  "id": 63,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "ALPR diagnostics ready for deployment \u2014 3 commits on alpr-rate-gap branch",
  "thread_id": null,
  "to": [
    "RedTower"
  ]
}
---

# ALPR Rate Gap Diagnostics — Ready for Deploy

Branch: `alpr-rate-gap` (3 commits ahead of main)

## What's in the branch

### 1. Structured ALPR_ATTEMPT logging (every frame)
Every `process_frame()` call now logs:
- `outcome=plate_read` — successful read with plate + confidence
- `outcome=no_detection` — ALPR returned nothing
- `outcome=cooldown_skip` — plate found but in cooldown dedup

### 2. ALPR_ZONE_CROP startup log (once)
First frame logs: `frame_pixels=WxH crop_pixels=WxH zone_polygon=[...]`
This lets us verify the zone crop matches reality.

### 3. ALPR_STATS periodic summary (every 100 frames)
`frames=N plate_reads=M read_rate=X%`
Shows actual throughput and plate read rate over time.

## What we already have (no code change needed)
FastALPRBackend already logs rejected plates:
```
Fast-ALPR plate rejected (low OCR confidence): 'ABC1234' confidence=0.650 < threshold=0.7
```

## Key investigation after deploy

Grep production logs for:
1. `ALPR_STATS` — current read rate
2. `Fast-ALPR plate rejected` — count of below-threshold reads
3. If (2) is significant → lowering threshold from 0.7 to 0.5 could close the gap
4. `ALPR_ZONE_CROP` — verify crop dimensions match expectations

## Next steps (need JPB input)
- Deploy this branch to metal-pi
- Collect ~1 day of enriched logs
- Analyze confidence distribution to decide threshold change
- Consider bumping fps from 0.5 to 1-2 (already configurable via `TD_EDGE_ALPR_DIRECT_FPS` env var)
