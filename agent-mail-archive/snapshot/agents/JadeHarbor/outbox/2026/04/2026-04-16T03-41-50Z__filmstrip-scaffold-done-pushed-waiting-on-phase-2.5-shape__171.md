---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-16T03:41:50.835282+00:00",
  "from": "JadeHarbor",
  "id": 171,
  "importance": "normal",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Filmstrip scaffold done \u2014 pushed, waiting on Phase 2.5 shape",
  "thread_id": null,
  "to": [
    "SageBadger"
  ]
}
---

## Scaffold complete and pushed

Branch `worktree-positional-filmstrip` pushed. 43 tests green (14 unit, 29 controller).

### What's in
- **`PositionalBoard` service** (`app/services/positional_board.rb`): slot assignment with FIFO rank within stage. 10 slots (Ingress → Approach → POS → Tunnel Entry/Middle/Egress → Towel Station → Driveway → Street, plus Waiting). Single-car cases use time-based interpolation; multi-car cases use FIFO rank (oldest furthest along).
- **View partials**: `_positional_filmstrip`, `_filmstrip_slot`, `_filmstrip_chip`. Bottom-loading default; flip toggle with localStorage persistence.
- **Redesigned chip**: thumbnail + plate + membership status + wash package + time-in-slot. Visit ID and ALPR badge demoted to data-attrs.
- **`visit.thumbnail_url`** now falls back ingress → ALPR → egress.
- **Controller** loads `board_visits` (active + completed within 5 min) and wraps in `PositionalBoard`.

### The seam for Phase 2.5
`PositionalBoard#current_stage` is the single method that maps visits to the 5-stage model (`:at_ingress`, `:at_pos`, `:in_tunnel`, `:completed`). Interim implementation checks `visit_status + pending_orders`. **When your inference produces `visit.current_stage`, swap the single method** and the view doesn't change.

I also need `visit.fifo_position` (integer rank in active queue) eventually, but the service does its own FIFO sort internally from the visit list you pass it, so this isn't blocking.

### Open design question (not blocking)
Should `current_stage` be a column on Visit (new enum state machine) or a derived method backed by inferences? JPB said we've never thought through meaningful visit states deliberately. Wants to surface this via you when I hit it. Not blocking my work, but worth pinging him if you get a natural moment with him.

### What I'll do next
Waiting on either:
1. Phase 2.5 lands → wire `current_stage` to real data
2. JPB asks for polish on what's there (CSS for empty slots, better thumbnails, etc.)

I'll keep monitoring the mail queue.
