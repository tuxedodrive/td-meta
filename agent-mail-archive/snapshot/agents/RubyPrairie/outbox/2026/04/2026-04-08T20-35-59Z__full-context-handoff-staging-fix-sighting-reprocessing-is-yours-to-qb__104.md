---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-08T20:35:59.479770+00:00",
  "from": "RubyPrairie",
  "id": 104,
  "importance": "normal",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Full context handoff \u2014 staging fix + sighting reprocessing is yours to QB",
  "thread_id": "100",
  "to": [
    "MaroonOwl"
  ]
}
---

Hey MaroonOwl — JPB wants you to quarterback the sighting reprocessing / overcounting work. Here's everything I've found.

## What I did this session

### 1. Staging camera_config fix (done)
**Root cause**: EdgeUnit id=2 on staging had `camera_config: nil` and `device_identifier: nil`. td-edge was syncing sightings successfully (HTTP 201, logged as `✅ Synced`), but SightingIngestionService couldn't resolve camera roles → no visits created. Same failure mode as the Apr 6 incident.

**Fix applied** on staging console:
```ruby
eu = EdgeUnit.find(2)
eu.update!(
  device_identifier: 'td-edge-jamaica-metal-pi',
  camera_config: {
    'cam0' => { 'role' => 'ingress' },
    'cam1' => { 'role' => 'egress' },
    'cam2' => { 'role' => 'alpr' }
  }
)
```

**Verified working**: sent a test sighting from the Pi, got `visit_id: 111253, action: "created"` back. New visits are flowing.

### 2. Health check for misconfigured EdgeUnits (code written, not yet deployed)
Branch `worktree-fix-staging` has:
- `EdgeUnit.misconfigured` scope — finds active units with nil camera_config
- `EdgeUnit#misconfigured?` instance method
- `/health` endpoint now includes `edge_units` check with warnings listing misconfigured devices
- edge_units is a soft check (warnings, not hard failure — app stays "healthy" but the warning is visible)
- All tests pass (5917 runs, 0 failures, 3 pre-existing fixture errors)

Files changed:
- `app/models/edge_unit.rb` (added scope + method)
- `app/controllers/health_controller.rb` (added check_edge_units)
- `test/models/edge_unit_test.rb` (4 new tests)
- `test/controllers/health_controller_test.rb` (2 new tests)

I still need to commit and push this branch. Will do that before closing out.

### 3. Sighting reprocessing (not started — handing to you)

My original plan was a simple rake task to replay orphaned sightings (sightings with no visit from the Apr 7-8 gap) through SightingIngestionService. But your overcounting findings change the picture significantly.

**Key facts about the orphaned sightings:**
- td-edge synced sightings to staging continuously through the outage — they got HTTP 201 back
- Sighting records exist in the staging DB with all data (camera_id, vehicle_data, timestamps)
- They just never triggered visit creation because GearConfig got `nil` camera_config
- The gap is roughly Apr 7 10:01am through Apr 8 ~3pm ET

**Why naive reprocessing is risky given your findings:**
- If we're already 2x overcounting on production, blindly replaying orphaned sightings will compound the problem
- Many orphaned sightings are likely duplicate observations of the same car (queue pauses, etc.)
- The InferenceEngine should help with smarter correlation, but needs tuning

## Infrastructure notes

- **td-edge targets.yaml on Pi**: confirmed correct — sends to both `api.tuxedodrive.com` (prod) and `api.staging.tuxedodrive.com` (staging)
- **Staging auth**: `EdgeBearerAuthentication` skips API key validation for non-production (`return true unless Rails.env.production?`), so auth is never the issue on staging
- **Pi SSH**: `ssh -o ProxyCommand='cloudflared access ssh --hostname %h' td-pi@ssh-metal-pi.tuxedodrive.dev`
- **Pi logs**: `/home/td-pi/td-edge/logs/td-edge.log`
- **Staging shell**: `ssh srv-d6ekcs41hm7c73f7ctb0@ssh.oregon.render.com`

## Suggested next steps (your call)

1. Address the 2x overcounting — this seems like the bigger issue than backfilling a 1-day gap
2. If you do want to reprocess orphaned sightings, scope it carefully: query `Sighting.where(visit_id: nil).where('created_at BETWEEN ? AND ?', gap_start, gap_end)` and consider dedup before replaying
3. The `washify:import_all` rake task exists locally but isn't deployed to staging — if JPB wants historical Washify data backfilled, that code needs to reach main first

Good luck — ping me if you need anything.
