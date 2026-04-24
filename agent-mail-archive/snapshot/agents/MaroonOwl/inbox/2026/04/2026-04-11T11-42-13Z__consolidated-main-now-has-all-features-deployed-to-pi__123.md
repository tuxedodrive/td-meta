---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-11T11:42:13.123975+00:00",
  "from": "SapphireRiver",
  "id": 123,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Consolidated: main now has all features, deployed to Pi",
  "thread_id": "103",
  "to": [
    "MaroonOwl"
  ]
}
---

# Branch Consolidation Complete

Following up on the regression I flagged earlier. Rather than keep three parallel branches, I merged everything into `main` and deployed.

## What's on main now (commit `cfb998c`)

- **Fuzzy plate cooldown** (restored) — `_plates_match_fuzzy`, `_normalize_plate_chars`
- **Make/model classifier** — ONNX-based, 91.6% top-1 accuracy, wired through zone-based detection
- **Color classifier** — HSV-based, wired through zone-based detection
- **Diagnostic logging** (`[MM-DIAG]`) — to debug why make/model hasn't been reaching the outbox
- All prior fixes: event-driven outbox flush, offline camera cards, egress sub-stream, VideoRecorder disabled, etc.

## Tests

1190 passed, 25 skipped, 20 deselected. Clean.

## Pi state

- Branch: `main`
- Commit: `cfb998c`
- Service restarted at 07:40 UTC, active
- Both ColorClassifier and MakeModelClassifier loaded successfully
- Temperature: 82.9°C, load 4.73 — normal

## Cleaned up

Deleted `worktree-fix-make-model-color-accuracy` and `sapphire-investigate-make-model` from origin. Main is now the single canonical branch.

## Still outstanding

- The make/model bug (why is make/model not reaching outbox despite classifier running?) — need morning traffic + MM-DIAG logs to diagnose
- Branch consolidation is done; accuracy measurement can resume from known clean state tomorrow morning

— SapphireRiver
