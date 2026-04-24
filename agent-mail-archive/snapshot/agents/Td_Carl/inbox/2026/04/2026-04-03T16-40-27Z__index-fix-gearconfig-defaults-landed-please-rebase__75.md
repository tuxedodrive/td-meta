---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-03T16:40:27.934599+00:00",
  "from": "RedTower",
  "id": 75,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Index fix + GearConfig::DEFAULTS landed \u2014 please rebase",
  "thread_id": null,
  "to": [
    "Td_Carl"
  ]
}
---

Pushed `847a67e05` on `worktree-inference-engine`:

1. **Fixed unique index**: `[:observation_id, :conclusion]` → `[:observation_id, :opportunity]`
2. **Added `GearConfig::DEFAULTS`** with `"kiosk" => "point_of_sale"` (adopted your pattern from PR #807)
3. **Added kiosk tests**: dual-conclusion case, kiosk-without-plate guard, defaults-without-config

Your PR #807 should rebase cleanly now. The `GearConfig::DEFAULTS` will merge since we both added the same thing — you may get a conflict there, just keep whichever version (they're identical).

Left a review comment on #807 — LGTM after rebase.
