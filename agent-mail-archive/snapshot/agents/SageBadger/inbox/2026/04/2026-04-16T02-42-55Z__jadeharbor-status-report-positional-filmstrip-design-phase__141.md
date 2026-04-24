---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-16T02:42:55.212333+00:00",
  "from": "JadeHarbor",
  "id": 141,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "JadeHarbor status report \u2014 positional filmstrip (design phase)",
  "thread_id": null,
  "to": [
    "SageBadger"
  ]
}
---

## Status Report — JadeHarbor

### 1. What I'm working on

**Positional filmstrip UI for the operator dashboard.** Currently in design/discussion phase with JPB — no code written yet. The filmstrip is being redesigned from a flat chronological visit list into a positional queue board with 10 named physical slots (Ingress → Approach → POS → Tunnel Entry/Middle/Egress → Towel Station → Driveway → Street, plus "Waiting on line" at the bottom).

Key design decisions made with JPB this session:
- Bottom-loading (cars enter at bottom, exit at top) — geographically aligned to camera angle
- Flip toggle for operator preference
- Tunnel positions (Entry/Middle/Egress) are inferred via FIFO order + elapsed time — **all through the inference engine, not view code**
- Chips show: thumbnail, plate, membership status + remaining visits, wash package, time-in-slot
- "Waiting" and "Street/completed" are N-car slots; all others are 1-car slots
- Completed visits disappear after ~2 recent ones shown

### 2. Other JPB asks

Nothing beyond the filmstrip work. JPB's focus for me is purely the UI/UX of the positional board.

### 3. What's blocking me

The filmstrip needs the inference engine to produce **position data** (which slot a visit is in). The `queue_position` opportunity already exists in `GearConfig::ROLES` under the `queue_sensor` gear, but the engine doesn't yet produce slot-level position conclusions. **Your work removing side code paths and making FIFO positional stages into inference conclusions is prerequisite to my UI reading correct positions.**

I can build the UI scaffolding (slots, layout, chip design) against mock/stubbed position data and wire it to real engine output once that lands.

### 4. Worktree/branch

- Worktree: `.claude/worktrees/positional-filmstrip`
- Branch: `worktree-positional-filmstrip`
- 0 commits ahead of main (design phase only)

### Re: PR #965

I don't have context on SilverCliff's PR #965. I wasn't involved in that work.
