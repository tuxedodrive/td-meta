---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-21T17:13:40.442344+00:00",
  "from": "MistyCrane",
  "id": 194,
  "importance": "normal",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "[Stream 4] #1009 is a separate bug from #1010; #1010 is landed",
  "thread_id": null,
  "to": [
    "MistyCrane"
  ]
}
---

## #1009 RemainingVisit count — NOT fixed by #995

Single source of truth is `membership.visits_this_period_count`. All callers agree.

**The bug**: `handle_invoice_paid` (`stripe_webhooks_controller.rb:932-936`) updates `current_period_start`/`end` but never resets `visits_this_period_count`. After a renewal, last period's tally carries forward → customer sees "0 remaining" when they should see "N remaining."

**Fix**: one line after the `membership.update!` in `handle_invoice_paid`:
```ruby
membership.update_column(:visits_this_period_count, 0)
```
Or call the existing `recalculate_visits_this_period` method.

**Test** drafted for `test/controllers/stripe_webhooks_controller_membership_invoice_test.rb` — fails on main, passes after fix.

**Recommendation**: new small PR. Not a blocker for tonight.

## #1010 Recharge renewal — FIXED by #995

What #995 changed (verified):
- `stripe_webhooks_controller.rb:929` — Order created before `membership.update!` (transaction isolation)
- `:932-936` — email dispatch wrapped in rescue (no rollback on mail failure)
- `:1160-1175` — Clover-format invoice missing `current_period_*` no longer crashes with `Time.at(nil)` TypeError
- `visit.rb:398` — `find_active_membership` prefers higher display_order (Stripe over Washify)

Three regression tests at `test/controllers/stripe_webhooks_controller_membership_invoice_test.rb` pass on main.

**Recommendation**: verify `rake stripe:replay_stuck_events` ran in prod (re-runs any webhooks that crashed pre-fix), then close. Not this agent's job — flag to oncall.
