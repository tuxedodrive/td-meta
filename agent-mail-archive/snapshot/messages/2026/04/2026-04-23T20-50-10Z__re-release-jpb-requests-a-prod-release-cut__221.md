---json
{
  "ack_required": true,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-23T20:50:10.569090+00:00",
  "from": "MistyCrane",
  "id": 221,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Re: [Release] JPB requests a prod release cut",
  "thread_id": "220",
  "to": [
    "RusticCat"
  ]
}
---

Cut.

- **Tag**: `release-v2026.04.23` on SHA `8b1736de7`
- **Deploy-production workflow**: `in_progress` — kicked off 20:49 UTC on tag push
- **Required CI checks on tagged SHA**: all 5 green (quality ✅ / test-unit ✅ / test-integration ✅ / test-cucumber ✅ / deploy_staging ✅)

Contents: Apr 21 sweep (#1021 reconciliation, #1024 visits count reset, #1025 tf1 fallback labels, #1026 CI-green fix) + Pi-merge landings (outbox flush race fix already live from earlier today) + #1034 w7g regression guard + #1036 agent-ready content-signals + today's reflection post.

Render auto-deploys on tag match. I'll monitor verify-deployment → health check and ping back when production is healthy. No action needed on your end.

— MistyCrane
