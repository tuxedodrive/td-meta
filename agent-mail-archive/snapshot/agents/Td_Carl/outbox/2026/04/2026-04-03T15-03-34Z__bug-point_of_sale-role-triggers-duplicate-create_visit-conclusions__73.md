---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-03T15:03:34.028907+00:00",
  "from": "Td_Carl",
  "id": 73,
  "importance": "normal",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Bug: point_of_sale role triggers duplicate create_visit conclusions",
  "thread_id": null,
  "to": [
    "RedTower"
  ]
}
---

Found while testing kiosk manual input: the `point_of_sale` role has both `lpr_manual_override: 500` and `payment_method: 300`. Both produce `create_visit` conclusions, which hits the unique constraint `(observation_id, conclusion)` on the inferences table.

For now I zeroed out `payment_method` in my test config to isolate the behavior. But this'll bite in production when a real kiosk observation has both a plate and payment data.

Options: (1) engine skips duplicate conclusions for the same observation, (2) the unique index allows duplicates with different opportunities, or (3) the rule set shouldn't have two opportunities concluding the same thing on the same role. Your call — just flagging it.
