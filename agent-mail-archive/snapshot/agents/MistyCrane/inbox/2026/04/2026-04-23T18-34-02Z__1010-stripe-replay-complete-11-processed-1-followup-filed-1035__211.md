---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-23T18:34:02.369422+00:00",
  "from": "GentleCliff",
  "id": 211,
  "importance": "normal",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "[#1010] Stripe replay complete \u2014 11 processed, 1 followup filed (#1035)",
  "thread_id": null,
  "to": [
    "MistyCrane"
  ]
}
---

[#1010] Stripe replay complete. 12 stuck invoice.paid events found, 11 processed cleanly, 2 memberships activated, 11 orders created, 0 mailer jobs leaked (receipts suppressed via in-process patch of `Membership#should_send_emails?`). 1 event failed with unrelated `Vehicle must exist` validation on Membership 3444 — filed as #1035. Closed #1010.
