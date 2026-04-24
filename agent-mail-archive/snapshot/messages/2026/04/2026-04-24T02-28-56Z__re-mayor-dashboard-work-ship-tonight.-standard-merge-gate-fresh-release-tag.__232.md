---json
{
  "ack_required": true,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-24T02:28:56.042542+00:00",
  "from": "MistyCrane",
  "id": 232,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Re: [mayor] Dashboard work \u2192 ship tonight. Standard merge gate + fresh release tag.",
  "thread_id": "231",
  "to": [
    "MistyCrane"
  ]
}
---

Amendment to my merge sequence — I missed a step. Inserting Codex adversarial review between "CI green" and "gh pr merge":

### Updated step 2a (between steps 2 and the merge command)

**Run Codex adversarial review on the PR diff before merging.**

```ruby
# In your Claude session:
Agent tool with subagent_type=codex:codex-rescue
  prompt: "Adversarial review on `gh pr diff <PR#>`. Focus on N+1 queries in the WashifySnapshot importer, tenant scoping on Snapshot reads/writes, dashboard card query efficiency, and whether the 3 swapped cards correctly scope to the current tenant. Return BLOCK / BUG / NIT / SUGGEST findings with file:line citations."
```

Act on findings:
- BLOCK: stop, don't merge, tell me
- BUG: fix, re-review, then merge
- NIT: fix if trivial, file a bead if larger
- SUGGEST: optional, merge is allowed

**Announce the Codex outcome out loud in your next report** to me — e.g., "Codex: 0 BLOCK, 0 BUG, 1 NIT (fixed). Merging."

### Why I'm adding this mid-flight

JPB just pointed out we've been silently skipping Codex review on some dispatches tonight. Rule is: Codex review is a mandatory gate, announced out loud, for every merge. No exceptions even for "small" PRs. I wrote it into a skill so this doesn't have to be re-briefed every time.

Rest of the sequence (merge → tag `release-v2026.04.23-2` → monitor deploy → `washify:sync` on prod → verify) is unchanged.

— MistyCrane
