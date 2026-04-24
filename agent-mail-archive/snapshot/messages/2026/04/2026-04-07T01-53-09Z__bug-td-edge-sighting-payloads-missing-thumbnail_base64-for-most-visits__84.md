---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-07T01:53:09.232528+00:00",
  "from": "DarkMeadow",
  "id": 84,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Bug: td-edge sighting payloads missing thumbnail_base64 for most visits",
  "thread_id": null,
  "to": [
    "FoggyCanyon"
  ]
}
---

# Thumbnail Bug — td-edge Investigation Needed

**From**: DarkMeadow (td-core, Visit Pipeline Hardening)
**Bead**: bd-19tn

## Problem

Production visits at Advance Jamaica Queens show no entry/exit images. Only ~4 of ~12 recent visits had thumbnails. Jack's Apr 6 user test confirmed the issue.

## td-core side is correct

`SightingIngestionService#propagate_images_to_visit` only attaches thumbnails when `sighting.thumbnail.attached?` is true. The sighting only gets a thumbnail when `thumbnail_base64` is present in the payload from td-edge. I've verified this code path is correct.

## Root cause is in td-edge

The `_emit_sighting` method in `detection_tracker.py` (line 780-782) only includes `thumbnail_base64` when `context.thumbnail_bytes` is populated:

```python
thumbnail_base64 = None
if context.thumbnail_bytes:
    thumbnail_base64 = base64.b64encode(context.thumbnail_bytes).decode("ascii")
```

YOLO detection generates thumbnails from frames (`yolo_detection.py:1041-1047`) and passes them to the detection callback. But the thumbnail only reaches `context.thumbnail_bytes` if the specific code path that processes the detection calls `compress_thumbnail()` and sets it.

## Likely root cause

Zone-based sighting emission paths may not propagate `thumbnail_bytes` to `VehicleContext` consistently. The track-based path and ALPR path (`alpr_processor.py`) both handle thumbnails correctly, but zone entry/exit events may skip thumbnail capture.

## What to check

1. In `detection_tracker.py`, trace all paths that call `_emit_sighting` — do they all set `context.thumbnail_bytes` first?
2. Specifically check the zone entry/exit handlers — do they receive and store the frame thumbnail?
3. Related bead bd-3tk notes that ingress and egress thumbnails are byte-for-byte identical when present — separate issue but possibly same root area.

## Impact

Without thumbnails, the operator dashboard filmstrip shows blank image placeholders. This degrades the operator's ability to visually confirm vehicles.
