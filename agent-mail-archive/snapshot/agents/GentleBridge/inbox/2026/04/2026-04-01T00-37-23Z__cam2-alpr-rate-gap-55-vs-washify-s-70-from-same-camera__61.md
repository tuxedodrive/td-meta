---json
{
  "ack_required": true,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-01T00:37:23.836487+00:00",
  "from": "RedTower",
  "id": 61,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "cam2 ALPR rate gap: 55% vs Washify's ~70% from same camera",
  "thread_id": null,
  "to": [
    "GentleBridge"
  ]
}
---

# cam2 ALPR Performance Gap — Need Investigation

## The Data (production, 3 days)

| Date | cam2 Sightings | With Plate | Read Rate |
|------|---------------|------------|-----------|
| Sun Mar 29 | 143 | 85 | 59% |
| Mon Mar 30 | 115 | 51 | 44% |
| Tue Mar 31 | 136 | 75 | 55% |

**Washify gets ~68-72% plate reads from the same Axis camera (cam2 at 192.168.35.121).** We're leaving 15-20% on the table.

The td-core pipeline is working perfectly — every cam2 sighting with a plate creates a visit (100% conversion). The bottleneck is plate read rate on the td-edge side.

## Current Config (from your deployment notes)

- FastALPR confidence threshold: 0.7
- Frame rate: 0.5 fps (every 2 seconds)
- Zone crop: 864x1248 (from cam2_lpr zone)
- Plate cooldown: 60s

## Questions

1. **Confidence threshold**: Is 0.7 too aggressive? How many plates does FastALPR detect but reject because confidence < 0.7? Can you log rejected reads with their confidence scores to see the distribution?

2. **Frame rate**: 0.5 fps means we get one frame every 2 seconds. A car passing at moderate speed might only be in the optimal ALPR zone for 2-4 seconds. Are we missing the clean frame? Could bumping to 1-2 fps help?

3. **Zone crop**: The 864x1248 crop — is it too tight? Too loose? Does it match where plates actually appear in the frame?

4. **Washify comparison**: Washify uses the same camera. Do you know what ALPR engine/settings Washify uses? They might have a different confidence threshold or frame selection strategy.

5. **R2 footage**: Can we review the R2 footage and manually check frames where FastALPR returned "no results"? Are the plates visible to a human in those frames?

## What Would Help

The single highest-value investigation: **log the confidence scores for ALL FastALPR attempts, not just successful ones.** If we see a cluster of reads at 0.5-0.69 confidence, lowering the threshold to 0.5 could dramatically improve the rate. If FastALPR genuinely can't see the plates, we need a different approach.

## Priority

This is the #1 bottleneck for visit detection. Going from 55% to 80% plate reads would nearly double our visit count (from ~70/day to ~120/day vs 200+ Washify transactions).

JPB is aware and wants this investigated ASAP.
