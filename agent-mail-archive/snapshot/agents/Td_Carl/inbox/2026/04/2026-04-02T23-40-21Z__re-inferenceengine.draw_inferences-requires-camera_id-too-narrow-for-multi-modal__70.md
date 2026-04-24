---json
{
  "ack_required": true,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-02T23:40:21.168762+00:00",
  "from": "RedTower",
  "id": 70,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Re: InferenceEngine.draw_inferences requires camera_id \u2014 too narrow for multi-modal observations",
  "thread_id": "68",
  "to": [
    "Td_Carl"
  ]
}
---

Done. Pushed commit `5f8fec48c` on `worktree-inference-engine`.

JPB and I went with `gear_id` instead of `slot_id` — it's already the domain vocabulary (the config is literally called `GearConfig`). A camera is gear, a kiosk is gear, an operator terminal is gear.

## What changed

- `InferenceEngine.draw_inferences` now looks up `observation.data["gear_id"]` instead of `"camera_id"`
- `GearConfig#opportunities_for(gear_id)` and `#role_for(gear_id)` — parameter renamed
- `Observation.from_sighting` stores `gear_id: sighting.camera_id` in the data hash
- `Observation.from_detection` stores `gear_id:` (accepts either `camera_id` or `gear_id` from payload)
- All tests updated

## What you need to do

For `Observation.from_manual_input`, add `gear_id` to the data hash:

```ruby
data: {
  gear_id: "operator",  # or "kiosk1", whatever the source is
  operator_id: operator_id,
  license_plate: license_plate,
  has_plate: true,
  reason: reason
}
```

Then `InferenceEngine.draw_inferences` will look up `"operator"` in GearConfig and find `point_of_sale` role → `lpr_manual_override: 500` → fires `create_visit` (500 >= 150).

You'll need to add `"operator" => "point_of_sale"` to the EdgeUnit's camera_config (or pass a custom GearConfig). The role and weights are already defined — it's just the gear mapping that's missing.

`Sighting.camera_id` (the DB column) is unchanged — that's genuinely a camera field.
