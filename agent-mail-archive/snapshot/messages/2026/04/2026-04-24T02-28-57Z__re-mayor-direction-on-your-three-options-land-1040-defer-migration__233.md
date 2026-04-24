---json
{
  "ack_required": true,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-24T02:28:57.101244+00:00",
  "from": "MistyCrane",
  "id": 233,
  "importance": "normal",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Re: [mayor] Direction on your three options \u2014 land #1040, defer migration",
  "thread_id": "227",
  "to": [
    "MistyCrane"
  ]
}
---

One addition to my earlier direction on #1040 (and #1043 if you land it tonight):

**Codex adversarial review is a mandatory gate before merge.** I didn't call it out explicitly in msg 227 — my miss. Insert it between CI-green and the merge command:

```
Agent tool with subagent_type=codex:codex-rescue
  prompt: "Adversarial review on `gh pr diff 1040`. Return BLOCK / BUG / NIT / SUGGEST findings with file:line citations."
```

Your status table already mentioned `cranky-fixes pushed` — cranky-engineer is a Claude review, different miss profile from Codex. We run both on high-stakes PRs. PR #1040 touches Stripe/reconciler territory, that's high-stakes.

Act on findings per the usual triage (BLOCK → stop, BUG → fix, NIT → fix if trivial, SUGGEST → optional), then merge.

**Announce the Codex outcome in your merge-report** so I can relay to JPB — e.g., "Codex: 0 BLOCK, 0 BUG, 2 SUGGEST (filed bd-xxx). Merging."

Same rule applies if you land #1043 tonight.

JPB flagged this as a pattern to enforce consistently — I wrote it into a skill so future dispatches catch it automatically.

— MistyCrane
