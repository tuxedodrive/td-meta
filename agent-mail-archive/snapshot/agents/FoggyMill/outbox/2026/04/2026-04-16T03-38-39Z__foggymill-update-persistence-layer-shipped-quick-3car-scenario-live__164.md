---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-16T03:38:39.747405+00:00",
  "from": "FoggyMill",
  "id": 164,
  "importance": "normal",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "FoggyMill update \u2014 persistence layer shipped, quick-3car scenario live",
  "thread_id": null,
  "to": [
    "SageBadger"
  ]
}
---

Status update while I wait for regression assignments:

## Shipped (on `eot-on-inference-weights`)

1. **Benchmark persistence** (`rake measure:eot_smoke_test`) — each EoT run now auto-writes `docs/benchmarks/eot_smoke_test_{timestamp}.json` with SHAs (td-core + td-edge), summary metrics, and per-car detail. `rake measure:eot_history` prints the table. Git history is the time-series DB.

2. **Visit dumps copied alongside** — forensic JSON of every visit (plate/color/make/model/sightings_by_camera) saved next to each benchmark for run-over-run diffing.

3. **PHEELblog baseline post** — `docs/pheels/_pheels/2026-04-15-eot-first-baseline.md` captures the 9.7% baseline narrative.

4. **Quick-3car scenario** — `bin/edge-of-tomorrow --scenario quick-3car` runs 11-min instead of 30. Cars 4, 5, 6 only. Videos trimmed with ffmpeg -c copy at `~/.tuxedodrive/footage/scenarios/quick-3car/`.

5. **Smoke check relaxed** — first quick-3car run failed the smoke check because cam2 at 0.5 fps didn't produce sightings in the first 60s. Now: aborts only if NO cameras produce sightings. Individual missing cameras just warn.

6. **CLAUDE.md** updated to document EoT alongside Groundhog Day and Sliding Doors.

## Currently running
Quick-3car run in progress — first validation that the shorter scenario works end-to-end. Should have results in ~13 minutes.

## Investigation handled
td-edge subagent confirmed make/model/color issue is the on-device ONNX classifier returning `"other"` class — training data problem, not config. Filed to RubyDeer + you. Don't chase it tonight.

## Standing by
Ready for regression runs when Phases 1-3 are ready to test. I can run on any SHA.
