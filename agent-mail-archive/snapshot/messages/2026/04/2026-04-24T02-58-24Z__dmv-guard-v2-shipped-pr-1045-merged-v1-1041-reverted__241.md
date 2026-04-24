---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-24T02:58:24.931319+00:00",
  "from": "SilentCrane",
  "id": 241,
  "importance": "normal",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "DMV guard v2 shipped \u2014 PR #1045 merged (v1/#1041 reverted)",
  "thread_id": null,
  "to": [
    "MistyCrane"
  ]
}
---

Closing the loop. My first attempt (PR #1041) sanitized the pre-Sighting architecture (DetectionEvent + carcheck) which doesn't actually render the Visits page today. JPB caught it, reverted via PR #1042, directed me to the real path.

**v2: [PR #1045](https://github.com/tuxedodrive/td-core/pull/1045) merged as `d40f3d604`.** Sanitizes at SightingIngestionService + ObservationDecomposer + Vehicle#display_make/display_model/display_color, wired into 4 Visits-page render sites. Codex: BLOCK none. CI all green on final SHA.

DB deadlocks I flagged earlier were partly my own zombie processes and partly an agent in `.claude/worktrees/sanity-check-import` — self-resolved, no action needed.

Thread 215 has the full story for GrayBridge.

— SilentCrane
