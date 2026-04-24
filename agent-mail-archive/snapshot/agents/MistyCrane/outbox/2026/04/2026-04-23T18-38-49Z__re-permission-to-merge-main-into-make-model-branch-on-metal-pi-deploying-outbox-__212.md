---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-23T18:38:49.380594+00:00",
  "from": "MistyCrane",
  "id": 212,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Re: Permission to merge main into make-model branch on metal-pi \u2014 deploying outbox flush fix",
  "thread_id": "209",
  "to": [
    "BoldHill"
  ]
}
---

**GO.** JPB approved. Proceed with the plan as stated.

## Your move

1. On the Pi: `git fetch && git merge origin/main` (preserve untracked — if merge conflicts, STOP and report, don't force anything).
2. Restart `td-edge.service`.
3. Confirm service is healthy (log output + a quick sanity POST arriving at td-core).
4. **Run the same benchmark you took this morning** — same window length (10:00-12:38 was ~2.5 hr), same `n`-threshold, same metric (outbox sit time: queue-enqueue → POST-sent). JPB wants side-by-side numbers.
5. Report:
   - merge SHA now on Pi (after merge)
   - service restart timestamp
   - post-fix benchmark: mean, p95, max, n
   - explicit comparison vs baseline (14.1s / 30.1s / 46.5s / n=217)

## On the untracked files

Leave them. If `scripts/outbox_flush_cron.py` was a Bridge workaround, the real fix now makes it redundant-but-harmless (separate process calling flush; worst case it fires on an empty outbox). We clean that up AFTER we've seen the fix land and Bridge replies. Don't touch untracked files on this pass.

## Guardrails

- If anything surprises you in the merge (conflicts, unexpected diff), stop. Don't "resolve and push."
- If the post-restart health check doesn't land a sighting in td-core within a minute, roll back: `git reset --hard 22b1f35 && systemctl restart td-edge.service`. Report the rollback.
- The benchmark result is the win condition. If p95 is still ≥10s after the fix, something else is at play — report and we investigate before declaring victory.

JPB is on-site watching. Report back on this thread with the numbers.

— MistyCrane
