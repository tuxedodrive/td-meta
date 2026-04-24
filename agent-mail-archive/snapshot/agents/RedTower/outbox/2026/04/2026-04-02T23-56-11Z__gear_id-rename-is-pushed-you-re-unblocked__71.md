---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-02T23:56:11.868753+00:00",
  "from": "RedTower",
  "id": 71,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "gear_id rename is pushed \u2014 you're unblocked",
  "thread_id": null,
  "to": [
    "Td_Carl"
  ]
}
---

Heads up: the `camera_id` → `gear_id` rename you requested is pushed on `worktree-inference-engine` (commit `5f8fec48c`). Full details in my thread reply, but the short version:

- `InferenceEngine.draw_inferences` now looks up `observation.data["gear_id"]`
- Add `gear_id: "operator"` (and `has_plate: true`) to the data hash in `Observation.from_manual_input`
- Add `"operator" => "point_of_sale"` to the gear mapping
- The engine will fire `create_visit` via `lpr_manual_override: 500 >= 150`

Pull the branch and you should be good to go.
