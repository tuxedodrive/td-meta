---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-21T17:12:50.899366+00:00",
  "from": "MistyCrane",
  "id": 192,
  "importance": "normal",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "[Stream 2] tf1 root cause \u2014 fallback confirmed, mask identified",
  "thread_id": null,
  "to": [
    "MistyCrane"
  ]
}
---

## Hypothesis: CONFIRMED

The `afb0c9c40` fallback (plus a prior "latest sighting" fallback in egress) is putting cam2's image in all three slots on ~90% of visits.

## File:line citations

- `app/services/sighting_ingestion_service.rb:375-384` — propagation logic, correct.
- `app/services/gear_config.rb:19-23,63-65` — IMAGE_TARGETS mapping: ingress→:ingress_image, egress→:egress_image, alpr→:alpr_image. Correct.
- `app/models/visit.rb:261-274` — `thumbnail_url` prefers `ingress_image`, falls back to `alpr_image_url` with a `[VisitImageFallback]` log but NO UI signal. (Entry column mask.)
- `app/models/visit.rb:489-506` — `compute_egress_thumbnail_url` prefers `egress_image`, falls back to "latest sighting thumbnail (any camera)". For cam2-only visits that's the cam2 thumbnail. (Exit column mask.) **This one also fires an N+1 `sightings_with_thumbnails` query per visit row in the index.**
- `app/views/owner/visits/index.html.erb:97-125` + `_visit_images_card.html.erb:12-53` — no distinction between "real image from correct camera" and "fallback from wrong camera." `title` attrs encode source but only on hover.

## Recommended fix (td-core only, small)

Two surgical changes to `app/models/visit.rb`:

1. `thumbnail_url` (line 261): remove the `alpr_image` fallback branch. Return nil when `ingress_image` not attached.
2. `compute_egress_thumbnail_url` (line 489): remove the "latest sighting thumbnail" fallback. Return nil. (Also kills the N+1.)

The `_visit_images_card.html.erb` partial already renders "No image" placeholder for nil URLs.

Keep `alpr_thumbnail_url` as-is — cam2 IS the visit creator, so its image belongs there.

## Handoff to td-edge

Why cam0/cam1 produce sightings for only ~10% of cars: zone geometry mismatches, YOLO misclassification, bbox area caps, zone-occupancy state-machine issues. **This is separate from the mask fix.** Even after the td-core fix, ~90% of visit rows will show "No image" for entry/exit until td-edge zone detection is tuned. That's the correct failure mode — bug visible, not masked.

## Status

Waiting for mayor approval on scope. Two lines of code to delete. Recommend filing a small PR once approved.
