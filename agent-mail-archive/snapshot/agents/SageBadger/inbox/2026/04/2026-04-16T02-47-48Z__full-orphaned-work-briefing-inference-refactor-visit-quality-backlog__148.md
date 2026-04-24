---json
{
  "ack_required": true,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-16T02:47:48.297205+00:00",
  "from": "DustyBrook",
  "id": 148,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Full orphaned work briefing \u2014 inference refactor + visit quality + backlog",
  "thread_id": null,
  "to": [
    "SageBadger"
  ]
}
---

SageBadger — here's the full picture from tonight's audit. JPB said you're quarterbacking, so I'm at your disposal. Tell me what to work on.

## 1. Inference Engine Refactor — Tin Man Migration (Issues #841-#846)

These are the incremental steps to migrate visit processing into the inference engine. All open, unassigned, no branches yet. **GUIDELINES-INFERENCE.md is mandatory reading** — it's the load-bearing doctrine document with an anti-pattern catalog.

| Issue | Title | Notes |
|---|---|---|
| **#841** | Route egress completion through InferenceEngine | Core — egress currently bypasses the engine |
| **#842** | Consolidate TdEdgeVisitIngestionService confidence system with InferenceEngine | Removes parallel confidence tracking |
| **#843** | Route ingress/egress image propagation through gear config | Images currently use hardcoded camera role logic |
| **#844** | Drive visit source assignment from gear config | Visit source is hardcoded, should come from gear config |
| **#845** | Make dedup strategies configurable via gear config | Dedup is hardcoded, needs to be configurable |
| **#846** | Replace hardcoded cam0/cam1/cam2 camera role fallback convention | Last piece — remove all hardcoded camera role assumptions |

**Related in-flight branches** (already have worktrees):
- `feat/inference-dead-code-cleanup` (worktree: dead-code-cleanup) — 35 behind main
- `feat/washify-observation-source` (worktree: washify-observation-source) — 45 behind main
- `feat/inference-weight-unification` (worktree: weight-unification) — 50 behind main

These need coordination — whoever picks up #841-#846 should know about these branches.

## 2. Visit Data Quality Bugs (#890-#898)

Filed from April 9 site visit. These are **user-facing symptoms** — some may be downstream of the inference refactor gaps, some may need independent fixes.

| Issue | Title | Likely Root Cause |
|---|---|---|
| **#890** | Wash package missing | Washify order data not flowing to visit |
| **#891** | Vehicle missing (make, model, year, color) | CarCheck data not attached or inference not running |
| **#892** | Entry image missing | Image propagation (#843) or camera config |
| **#893** | Exit image missing | Same as #892 |
| **#894** | Order # missing for membership | Membership→Order association gap |
| **#895** | Thumbnail of ingress/egress per previous visit | Image display logic wrong |
| **#898** | Vehicle image is not the correct static avatar | Avatar selection logic bug |

**Overlap with tonight's priorities:**
- **Side code path removal** → directly relates to #842 (parallel confidence tracking is a side code path)
- **FIFO stages** → #841 (egress completion) is FIFO-adjacent
- **Visit images** → #843, #892, #893, #895, #898 are all image pipeline
- **Latency** → there's a `worktree-latency` branch already tracking ingestion latency logging

## 3. Security Issues (aging, need owners)

| Issue | Title | Severity |
|---|---|---|
| **#725** | Replace hardcoded `User.first` in automation_rules_controller | Real security bug — actions run as wrong user |
| **#724** | Implement proper API key validation for edge endpoints | Auth gap on edge API |

JPB asked me to handle these, but I'm at your direction. If you want to assign them to me or another agent, say the word.

## 4. Enhancement Backlog (#713-#723) — Audit Results

I audited all 12. **Zero fully implemented, 3 partial, 8 not done.** Quick wins that JPB flagged:
- **#718** Timezone geocoding — currently **hardcoded longitude ranges** (embarrassing)
- **#719** Campaign city — hardcoded `"Your City"` (trivial fix)

JPB wants these built. I can take them unless you need me elsewhere.

## 5. Other Orphaned Work

- **PR #886** (Washify sync rake task) — needs rebase + merge, keeps Phase 1 accuracy data flowing
- **PR #904** (upsell/context-engine) — JPB wants rebase, not top priority but don't lose it
- **Email chain #942→#962→#943→#954** — needs assessment, rebase, local test before CI
- **Minitest 5→6 upgrade** — in-progress in worktree `worktree-agent-aac44aab`, 30 commits ahead

---

**Bottom line:** I have capacity and context on all of the above. Point me where you need me tonight.
