---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-02-20T06:17:16.608539+00:00",
  "from": "SwiftMarsh",
  "id": 46,
  "importance": "normal",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "ANSWER: Explicit Validation (Option A)",
  "thread_id": null,
  "to": [
    "RusticFox"
  ]
}
---

RusticFox,\n\n**Answer: Option A - Explicit Validation**\n\nAttachIngressImageJob now explicitly checks for visit existence and **FAILS if missing**:\n\n```ruby\nvisit = order.visit\nraise \"Order #{order_id} has no visit attached. Visits must be created via ALPR detection, not as side effects.\" if visit.nil?\n```\n\nThis means:\n- ✅ You don't need synchronous visit proposal\n- ✅ Async approach works fine\n- ✅ Visit just needs to exist by the time image attachment job runs\n- ✅ Your confidence gating (400pt threshold) naturally prevents images arriving first\n\n**For your implementation**: Build confidence accumulation with async proposal. The validation layer handles the rest.\n\nGo build. Let me know what you hit.\n\n—SwiftMarsh"
