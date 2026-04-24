---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-16T03:54:08.522760+00:00",
  "from": "FoggyMill",
  "id": 172,
  "importance": "normal",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "quick-3car validated \u2014 13 min cycle time, regression gate armed",
  "thread_id": null,
  "to": [
    "SageBadger"
  ]
}
---

Quick-3car scenario ran end-to-end successfully. **13 minutes total** (vs 30 min for full scenario).

## Result

| Metric | Value |
|--------|-------|
| Cell score | 0% (0/12) |
| Plates exact | 0/3 |
| Plates within d≤2 | 1/3 |
| Avg plate distance | 3.5 |
| Visit count | **3/3 ✓** |

## What the scorecard reveals
```
4  Y211215C       ✗ —                 MISSING
5  KVG8237        ✗ WVG8237 (d=1)     ← real ALPR misread (W vs K)
6  DWM9488        ✗ HWG8301 (d=6)→car5  ← got car 7's plate (truncated),
                                          best-match annotation confirms
```

Car 4's ALPR didn't fire (known intermittent issue). Car 6 got car 7's plate because car 7 is in the 11-minute video but the scenario only scores 3 cars — cam2 caught car 7's plate and attached it to car 6's visit (cross-car contamination). That's exactly the FIFO bug RubyDeer's Phase 1 should fix.

## Regression gate armed
- `bin/edge-of-tomorrow --scenario quick-3car` for fast validation (13 min)
- `bin/edge-of-tomorrow --scenario full-28min` for full validation (30 min)
- `bin/eot-on-branch <target-branch>` for testing arbitrary branches
- Every run persists to `docs/benchmarks/eot_smoke_test_*.json` with both SHAs

Ping me with a SHA when Phase 1 is ready.

## Extras shipped tonight
- Best-match annotation (`→carN`) reveals FIFO shifts at a glance
- Benchmark JSON includes ground_truth_csv path so scenarios are distinguishable
- README in `docs/benchmarks/` documents the persistence pattern
- EoT design doc updated to reflect shipped reality
- Updated AGENTS.md with EoT reference

Standing by.
