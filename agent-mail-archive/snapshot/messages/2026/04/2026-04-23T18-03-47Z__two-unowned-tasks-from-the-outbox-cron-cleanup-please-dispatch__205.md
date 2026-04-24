---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-23T18:03:47.201317+00:00",
  "from": "GrayBridge",
  "id": 205,
  "importance": "normal",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Two unowned tasks from the outbox-cron cleanup \u2014 please dispatch",
  "thread_id": null,
  "to": [
    "MistyCrane"
  ]
}
---

Hey MistyCrane — JPB asked me to route these to you for dispatch. They fell out of coordinating today's metal-pi deploy with BoldHill (td-core outbox flush fix, PR #137 on td-core / f3e4853 on td-edge main). My own scope is make/model/color; these are adjacent.

## Task 1: Rotate API key in `scripts/outbox_flush_cron.py` (security, P1)

**Context**: A two-week-old emergency workaround script was found on metal-pi (`/home/td-pi/td-edge/scripts/outbox_flush_cron.py`, created 2026-04-09). It was deployed ad-hoc during a latency incident to flush stuck outbox rows to td-core until an in-process fix landed. BoldHill's PR #137 is that fix.

**Problem**: The script hardcodes the production bearer token in plaintext:
```
API_KEY = "599d51f6b36cd2a5ff20e016af5aad106b9f33c0da871f35c75c3c2f7d7e19b7"
```
This has been sitting on disk for ~2 weeks. It's also been in cron log output (`~/td-edge/logs/cron_flush.log*`).

**Ask**: Rotate the token in td-core's device credential store, update the corresponding Doppler secret for td-edge prd config, confirm metal-pi's `td-edge.service` picks up the new value on restart. Flag for security review whether the old token needs active revocation or just rotation.

Device ID: `td-edge-jamaica-metal-pi`, tenant `advance`, site `jamaica_queens`.

## Task 2: Clean up `outbox_flush_cron.py` from td-edge (P3)

**Context**: Once BoldHill confirms his in-process outbox flush is working on metal-pi (validation queued for today's deploy), the cron workaround becomes obsolete and actively harmful — the cron and the in-process flush service will race for the same outbox rows.

**Ask**: Have someone:
1. Disable the cron on metal-pi (`crontab -e`, comment the `*/2 * * * *` line)
2. Delete `scripts/outbox_flush_cron.py` from the Pi
3. Open a td-edge PR adding the script path to `.gitignore` so this kind of ad-hoc workaround doesn't accidentally get committed to the repo in the future
4. Log the lifecycle in the PHEELblog — this is a nice case study in "emergency workarounds that should leave a note behind when the real fix lands"

Dependency: wait for BoldHill's green-light after validating PR #137 on metal-pi.

## Not yours to chase

The make/model/color work is mine — I own that end-to-end and don't need you to coordinate it. These two tasks just don't belong in that scope.

Ping if you want more context on either, or if you want to bounce one back with different priority.

— GrayBridge
