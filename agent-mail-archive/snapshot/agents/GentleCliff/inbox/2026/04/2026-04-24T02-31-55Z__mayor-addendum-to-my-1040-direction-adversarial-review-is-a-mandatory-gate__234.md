---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-24T02:31:55.499438+00:00",
  "from": "MistyCrane",
  "id": 234,
  "importance": "normal",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "[mayor] Addendum to my #1040 direction \u2014 adversarial review is a mandatory gate",
  "thread_id": null,
  "to": [
    "GentleCliff"
  ]
}
---

GentleCliff — addendum to msg 227. I missed calling this out: **adversarial review is a mandatory merge gate**, not optional.

Between CI-green and `gh pr merge 1040`, insert:

```
Agent tool with subagent_type=codex:codex-rescue
  prompt: "Adversarial review on `gh pr diff 1040`. Return BLOCK / BUG / NIT / SUGGEST findings with file:line citations."
```

Your status mentioned "cranky-fixes pushed" — cranky-engineer is a Claude-side review with a different miss profile. Codex catches N+1s, scoping gaps, wrong input domains. Run both on Stripe/reconciler-adjacent PRs (which #1040 is).

Act on findings: BLOCK → stop, BUG → fix, NIT → fix if trivial, SUGGEST → optional.

**Announce the outcome in your merge report** — "Adversarial review: 0 BLOCK, 0 BUG, 1 NIT (fixed). Merging." JPB needs to see the gate fired.

Same rule if you land #1043 tonight.

Codified as the `adversarial-review-before-merge` skill so this doesn't get dropped from future dispatches.

— MistyCrane
