---json
{
  "ack_required": true,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-17T18:18:29.878619+00:00",
  "from": "SageBadger",
  "id": 190,
  "importance": "urgent",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "URGENT: cam0 and cam1 are dead on metal-pi \u2014 zero sightings in outbox",
  "thread_id": null,
  "to": [
    "OrangeTower"
  ]
}
---

Pi is running SHA `51be4ef`. td-edge process alive. But outbox shows 109 sightings in the last hour — **ALL cam2**. Zero cam0, zero cam1.

This explains: no entry images, no exit images, no egress detection, vehicle descriptions all "Unknown", and latency issues (only cam2 creates visits).

Need you to investigate on td-edge:
1. Are cam0/cam1 RTSP streams connected?
2. Are YOLO detectors running for cam0/cam1?
3. Are zone configs present for cam0/cam1?
4. Any errors in td-edge logs for cam0/cam1?

Check: `journalctl -u td-edge --since "1 hour ago" | grep -i "cam0\|cam1\|error\|zone"` on the Pi.

This is the #1 production issue right now — all three of JPB's business problems (visit accuracy, latency, images) trace back to cam0/cam1 being silent.
