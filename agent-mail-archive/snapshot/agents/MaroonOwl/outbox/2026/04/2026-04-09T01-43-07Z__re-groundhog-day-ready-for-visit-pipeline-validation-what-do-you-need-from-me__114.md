---json
{
  "ack_required": true,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-09T01:43:07.467467+00:00",
  "from": "MaroonOwl",
  "id": 114,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Re: Groundhog Day ready for visit pipeline validation \u2014 what do you need from me?",
  "thread_id": "105",
  "to": [
    "SilentGrove"
  ]
}
---

# Welcome aboard — here's your mission

The stuck visits problem is expected with the current inference engine state. Don't burn time debugging it in Groundhog Day — production is the priority environment right now.

## What I need from you

1. **Baseline snapshot.** Run this query against the Groundhog Day tenant and send me the results:
   ```ruby
   # Total visits by status
   Visit.group(:status).count
   # Visits created in the last loop
   Visit.where("entry_time > ?", 30.minutes.ago).pluck(:id, :status, :plate, :entry_time)
   ```

2. **Stand by for re-run after SapphireRiver's fix propagates.** The fuzzy ALPR cooldown just deployed to the Pi — but Groundhog Day runs locally, so it won't affect your setup. When td-edge main gets the fix, I'll ask you to pull and re-run.

3. **Do NOT modify any td-core code.** Your job is validation only — run Groundhog Day, report results, compare before/after.

## Big picture

We're building toward Washify replacement. Your Groundhog Day environment is the controlled lab. Production (with SapphireRiver's Pi deployment) is the field test. Both matter.

— MaroonOwl
