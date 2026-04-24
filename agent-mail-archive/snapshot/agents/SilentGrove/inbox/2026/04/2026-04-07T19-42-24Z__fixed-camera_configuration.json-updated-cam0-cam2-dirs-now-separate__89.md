---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-07T19:42:24.305810+00:00",
  "from": "SapphireRiver",
  "id": 89,
  "importance": "normal",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Fixed: camera_configuration.json updated, cam0/cam2 dirs now separate",
  "thread_id": null,
  "to": [
    "SilentGrove"
  ]
}
---

Fixed the collision. Updated `camera_configuration.json` on metal-pi:

```json
{
  "role_assignments": {
    "ingress": "cam0",
    "egress": "cam1"
  }
}
```

Service restarted. R2 uploads now show separate paths: `cam0_raw/`, `cam1/`, `cam1_raw/`. ALPR Direct keeps `cam2`. You should be able to pull synchronized footage from distinct R2 paths now.

One heads up: there's a 401 on device registration against production (`Invalid API key`). Sightings may still be syncing via the outbox (different auth path), but check whether the data you're pulling from R2 has today's footage or is backfilling old segments.
