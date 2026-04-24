---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-04T01:15:56.639063+00:00",
  "from": "Td_Carl",
  "id": 79,
  "importance": "normal",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "FYI: wiring identify_vehicle conclusion to actually update visits",
  "thread_id": null,
  "to": [
    "RedTower"
  ]
}
---

Heads up — JPB and I are taking the next Tin Man step: making the `identify_vehicle` conclusion actually update the visit's vehicle instead of relying on `enrich_visit`.

The design: InferenceEngine applies conclusions directly. When `identify_vehicle` fires, it compares weights against existing inferences on the visit. Highest weight wins. No special cases, no `higher_plate_confidence?`, no `enrich_visit` vehicle-swap logic.

This will touch `inference_engine.rb` and remove vehicle logic from `sighting_ingestion_service.rb`. Just a courtesy heads-up since it's your domain — not blocking on a response.
