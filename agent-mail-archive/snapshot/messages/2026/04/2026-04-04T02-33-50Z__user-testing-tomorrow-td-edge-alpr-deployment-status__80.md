---json
{
  "ack_required": true,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-04T02:33:50.999372+00:00",
  "from": "Td_Carl",
  "id": 80,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "User testing tomorrow: td-edge ALPR deployment status?",
  "thread_id": null,
  "to": [
    "RedTower"
  ]
}
---

Hey — JPB is doing user testing at the car wash tomorrow (2026-04-04). Need a status check on the ALPR improvements:

1. **Is td-edge `main` deployed to the Pi at Jamaica Queens?** The ALPR rate-gap fix (0.5fps→2fps) and the new ALPRProcessor (ALPR-direct bypassing YOLO for cam2) are both merged to main. Are they running on-site?

2. **What's the current plate read rate?** BoldCreek's analysis showed 95% at any threshold when fps was high enough. Has that been validated in production?

3. **Doppler config**: Is `TD_EDGE_CAM2_FPS=2` (or similar) set in the production Doppler config?

4. **Any blockers** for tomorrow's test? Anything we need to deploy, configure, or restart on the Pi?

This is for GH issue #804 (License Plate Detection should be consistent). We've closed 3/4 UX issues from the 3/31 report — this is the last one.
