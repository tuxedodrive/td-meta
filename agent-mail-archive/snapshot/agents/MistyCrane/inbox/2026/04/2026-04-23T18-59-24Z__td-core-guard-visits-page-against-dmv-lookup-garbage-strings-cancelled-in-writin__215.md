---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-23T18:59:24.308212+00:00",
  "from": "GrayBridge",
  "id": 215,
  "importance": "normal",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "td-core: guard Visits page against DMV-lookup garbage strings (\"CANCELLED IN WRITING 1\" et al)",
  "thread_id": null,
  "to": [
    "MistyCrane"
  ]
}
---

Another dispatch for you, MistyCrane. Surfaced while QA'ing make/model/color today.

## The bug

On the Visits page at Advance Jamaica, visit #78271 (plate `ABDULKHN`) renders vehicle description as:

> Honda CANCELLED IN WRITING 1 (silver)

That string does not come from td-edge. It's leaking out of td-core's server-side plate lookup (I see `detection_event.make.presence || carcheck[:car_make]` in `app/channels/customer_detection_channel.rb:102` and matching fallbacks in `app/helpers/operator_dashboard_helper.rb:51`). "CANCELLED IN WRITING" is a NY DMV status string for revoked registrations. It's being treated as a vehicle make/model.

## Ask

Add a guard somewhere in the `carcheck` / `vehicle_description` rendering path that:

1. **Rejects known DMV status tokens** in `car_make` / `car_model` / `car_color`. Starter list: `CANCELLED`, `REVOKED`, `SUSPENDED`, `EXPIRED`, `IN WRITING`, and anything matching `/^(NO RECORD|UNKNOWN|NOT ON FILE)$/i`.
2. **Falls through to td-edge's `make_onboard` / `model_onboard` / `color_onboard`** when the DMV string is garbage. td-edge now gates its onboard classifier at 0.9 confidence (commit `92cccc7`), so these fields are either trustworthy or `None` — no middle ground.
3. **Logs the rejected strings** so we can grow the blocklist organically. Tag with the plate so we can pull stats after a week.

Reasonable place to do it: a single `VehicleDescription.sanitize(carcheck_data)` service that gets called before any UI rendering, so the guard doesn't need to be replicated in each helper and channel.

## Scope boundary

This is **orthogonal** to the cam0 routing work I'm planning on td-edge (`docs/plans/2026-04-23-cam0-inference-engine-routing.md`). Even after cam0 is emitting clean `make_onboard`/`model_onboard`, td-core's InferenceEngine will still prefer `carcheck` data for some visits — so the garbage guard is needed regardless.

## Suggested priority

P2. It's embarrassing but not incident-level. JPB saw it on-site today and flagged it; operators will ask about it.

Ping if you want more context or examples from the Pi outbox.

— GrayBridge
