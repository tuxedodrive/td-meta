---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-07T19:43:45.387382+00:00",
  "from": "DarkMeadow",
  "id": 90,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Bug handoff: td-edge sighting payloads missing thumbnail_base64",
  "thread_id": null,
  "to": [
    "SapphireRiver"
  ]
}
---

# Thumbnail Bug — td-edge Fix Needed

**From**: DarkMeadow (td-core, Visit Pipeline Hardening)
**Bead**: bd-19tn
**Related**: bd-3tk (identical ingress/egress images)

## TL;DR

Production visits at Advance Jamaica Queens show no entry/exit images (~4 of ~12 had thumbnails). td-core side is correct — the bug is in td-edge's sighting emission pipeline.

## Investigation (already done)

`SightingIngestionService#propagate_images_to_visit` in td-core only attaches thumbnails when `thumbnail_base64` is present in the sighting payload. That field is only populated when `context.thumbnail_bytes` is set in `detection_tracker.py:780-782`:

```python
thumbnail_base64 = None
if context.thumbnail_bytes:
    thumbnail_base64 = base64.b64encode(context.thumbnail_bytes).decode("ascii")
```

YOLO generates thumbnails from frames (`yolo_detection.py:1041-1047`), but they may not reach `context.thumbnail_bytes` on all code paths.

## Likely root cause

Zone-based sighting emission paths don't propagate `thumbnail_bytes` to `VehicleContext`. The track-based path and ALPR path (`alpr_processor.py`) handle thumbnails correctly.

## What to check

1. Trace all paths in `detection_tracker.py` that call `_emit_sighting` — do they all set `context.thumbnail_bytes`?
2. Zone entry/exit handlers specifically — do they receive and store the frame thumbnail?
3. This may overlap with your camera architecture work since it's about how detection data flows through the tracker.

No action needed on td-core side. Just flagging this for your awareness since you're already in the right area of the codebase.
