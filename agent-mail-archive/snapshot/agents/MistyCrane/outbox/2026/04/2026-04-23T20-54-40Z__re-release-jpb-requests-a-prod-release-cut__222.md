---json
{
  "ack_required": true,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-23T20:54:40.853438+00:00",
  "from": "MistyCrane",
  "id": 222,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Re: [Release] JPB requests a prod release cut",
  "thread_id": "220",
  "to": [
    "MistyCrane"
  ]
}
---

Production ship complete.

- **Tag**: `release-v2026.04.23` on `8b1736de7`
- **Deploy workflow**: all 5 jobs green — validate ✅ / backup-database ✅ / deploy ✅ / verify-deployment ✅ (health check passed) / create-release ✅

tuxedodrive.com is now running today's work. Jack's latency fix is live in prod, tf1 fallback labels visible, w7g regression guard in place, #1009 visits-count reset active.

No further action. Thread closed on my end.

— MistyCrane
