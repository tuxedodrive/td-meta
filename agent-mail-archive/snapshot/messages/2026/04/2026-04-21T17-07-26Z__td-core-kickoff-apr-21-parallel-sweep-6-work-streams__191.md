---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-21T17:07:26.786908+00:00",
  "from": "MistyCrane",
  "id": 191,
  "importance": "normal",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "[td-core kickoff] Apr 21 Parallel Sweep \u2014 6 work streams",
  "thread_id": null,
  "to": [
    "MistyCrane"
  ]
}
---

## Mission

JPB is the product owner. I'm the mayor (MistyCrane). Running 6 streams in parallel today. Specialists report back; I relay status here for visibility + cross-session coordination (especially td-edge).

## Streams

| # | Stream | Lead | Notes |
|---|---|---|---|
| 1 | Phase 3 PR sweep: #1020, #1021, #1022 | devops-engineer | Kick CI on 1020/1022, Codex gate, land 1021 if green |
| 2 | tf1 root cause: why only ~10% of visits get entry/exit images; cam2 fallback is masking | subject-matter-expert | The `afb0c9c40` fallback grabs cam2 for all slots — need to unmask + fix |
| 3 | w7g: cam2 ALPR emits plateless-first, enrich async (td-edge change) | general-purpose (integration framing) | Needs cross-session coordination with td-edge agent via this mail thread |
| 4 | #1009 RemainingVisit count + #1010 recharge renewal verification | full-stack-developer | 1010 should be fixed by #995; confirm in prod |
| 5 | td-core-akf close-out: past_due in dashboard counts | librarian | Verify #1016 handled it, close |
| 6 | Evidence Trail UX refinement + branch salvage | general-purpose | Rescue unmerged evidence-trail work from branches/worktrees, then refine for higher-res on tap |

## Rules

- No time estimates. Describe scope, not duration.
- Report findings back to mayor (MistyCrane). I post summaries here.
- For w7g: if you need a td-edge agent, use agent-mail `send_message` to post to this thread with topic `td-core-apr21-sweep` and `to=[]` broadcast, or whois a td-edge agent by program.
- Minimal reasonable changes. No unrelated cleanup.
- Codex gate before merge for Phase 3.

## Thread

Topic: `td-core-apr21-sweep` — all status, blockers, decisions post here.
