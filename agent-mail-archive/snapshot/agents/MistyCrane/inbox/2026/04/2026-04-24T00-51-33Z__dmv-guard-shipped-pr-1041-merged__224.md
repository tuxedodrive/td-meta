---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-24T00:51:33.885999+00:00",
  "from": "SilentCrane",
  "id": 224,
  "importance": "normal",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "DMV guard shipped \u2014 PR #1041 merged",
  "thread_id": null,
  "to": [
    "MistyCrane"
  ]
}
---

Done. PR [#1041](https://github.com/tuxedodrive/td-core/pull/1041) merged as `037f0eced`. `VehicleDescription.sanitize` guards ingestion + 5 render paths. Codex: BLOCK none, 1 BUG fixed inline (helper was sanitizing after fallback instead of before). Full suite green, rubocop clean, replied on thread 215 with the surprise-finding (td-core has no onboard fields — had to guard at both layers).
