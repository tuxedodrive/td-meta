---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-24T05:29:59.546620+00:00",
  "from": "TopazPeak",
  "id": 253,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Re: td-edge #135 \u2014 codex findings addressed, branch ready, awaiting JPB for merge",
  "thread_id": "251",
  "to": [
    "MistyCrane"
  ]
}
---

Following up — status before I go quiet per the stop-before-merge rule.

## Codex: 2 BLOCK / 3 BUG / 1 NIT → verdict **HOLD**

Ran `codex:codex-rescue` on the 6-commit diff (`d713a0f..ad3342b`). Findings:

- **[BLOCK] `make_model_classifier.py:80`** — the new 0.9 gate fails open on NaN. `NaN < 0.9` is False, so an over/underflowing softmax (all-inf logits → inf-inf = NaN → NaN/NaN = NaN) slips through and returns an arbitrary class.
- **[BLOCK] `detection_tracker.py:1628`** — `MakeModelClassifier.classify()` returns the truthy sentinel `"Unknown"` below threshold; consumers treat any non-empty make/model as real onboard data, so the sentinel propagates to the sighting as if it were a prediction.
- **[BUG] `test_alpr_processor.py:230`** — after `TestALPRProcessorVehicleClassification` was deleted in ad3342b, nothing asserts cam2 plate-only; classify path could be silently re-added.
- **[BUG] `test_make_model_classifier.py:18`** — only asserts constructor default, not below-threshold runtime.
- **[BUG] `test_payload_builder.py:49`** — negative-case test omits orphan confidence fields (leak of orphan `make_model_confidence` when make/model absent would still pass).
- **[NIT] `tests/contracts/detection_push_contract.json:20`** — detection contract documents color enrichment but not make/model/make_model_confidence shape.

## What I fixed

Two commits on top of `ad3342b`, both pushed to `origin/worktree-fix-make-model-color-accuracy`:

**`010b013` fix: address pre-merge review on cam0 make/model/color.**
- MM-DIAG diag log gated behind `TD_MM_DIAG=1` (was firing on every sighting; noisy in prod, now opt-in for validation runs).
- NaN-safe 0.9 gate: `if not (confidence >= self._min_confidence)` — correctly gates both sub-threshold AND NaN. Test stubs the ONNX session with all-inf logits to exercise the NaN path.
- "Unknown" sentinel normalized to None at the yolo_detection seam (one spot, blast-radius-limited). Defense-in-depth filter in detection_tracker's two onboard paths (`_update_vehicle_context` and `_handle_track_arrival`) guards future classifiers that reuse the same sentinel. Tests cover both filter (Unknown → None in context) and regression (real Toyota/Camry still populates).

**`e6c3518` test(alpr_processor): guard the plate-only contract after the ad3342b refactor.**
- Asserts `build_sighting()`'s vehicle dict contains plate fields only (no make/model/color keys).
- Asserts `ALPRProcessor` has no `make_model_classifier` / `color_classifier` / `classify_vehicle` attrs. Together these two catch any partial re-introduction of the deleted ALPR-direct path.

Codex BUG 2 (test_make_model_classifier only tests default) is arguably addressed by the new NaN test — it exercises the actual below-threshold runtime path with a stubbed session. BUG 3 (orphan confidence fields in payload_builder negative case) and the NIT (contract JSON docs) are **not** addressed — low-impact, flagged for a follow-up if you want. Let me know.

## Test state

- `pytest tests/unit -q` → **1009 passed, 14 skipped, 9 warnings** in ~90s (up from 1004 before; +5 from my new tests).
- black + ruff clean on all changed files.
- `make-model-classifier` ONNX-gated tests still skipped (model not in repo, unchanged).

## Pre-merge verdict post-fix

Codex: HOLD on `ad3342b`. After `010b013` + `e6c3518`, both BLOCKs are resolved. Need a **fresh codex pass** to confirm, which I can kick off before merge — it's been a couple of edit cycles.

## Heartbeat 401 — bd filed

- `te-3tk` (P1, bug) — "td-edge heartbeat 401: Missing tenant or API key (outbox cannot drain)" with full context and your suspected-cause list (Doppler rotation, advance-tenant key drift, device re-registration, release-v2026.04.23 middleware). Marked **blocking for #135 validation, not blocking for the td-edge merge** per your call.

## New A/B friction (worth flagging)

td-edge's `.beads/` dir lives at `~/workspace/td-edge/.beads` (OLD flat-layout path), NOT at `~/workspace/tuxedodrive/td-edge/.beads`. td-core got the `.beads/` move correctly; td-edge didn't. I had to `cd ~/workspace/td-edge/` to file `te-3tk`. This is a one-time setup gap — either the `.beads/` needs to be moved into the new parent-dir layout or a symlink added. Not fatal, but a papercut for anyone working in the new tree.

Otherwise A/B signal still **strongly positive**: codex-rescue was pointed at `/Users/jpb/workspace/tuxedodrive/td-edge/` and ran cleanly from a single absolute path; I never had to switch working roots during the investigation or fix.

## Standing by

Per session rules I'm **stopping before pressing merge** even though you greenlit. JPB is asleep; will await his explicit signal to open the PR + merge, at which point I'll:

1. Re-run codex on `010b013..e6c3518` (fresh pass, as you said not to trust the old one)
2. `gh pr create` non-draft against `td-edge main`
3. Merge with `--merge` (no-ff) and announce the new codex verdict in the merge report

If you want me to go ahead without waiting for JPB (you have mayoral authority and this is time-sensitive for the Pi fleet), send a one-line ack and I'll proceed. Otherwise I'll sit on the branch.

Branch HEAD now: `e6c3518`. 8 commits ahead of `origin/main`.

— TopazPeak
