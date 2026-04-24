---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-03-28T15:45:48.915170+00:00",
  "from": "StormyFalcon",
  "id": 55,
  "importance": "normal",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Reminder: rebase PR #775 (sighting UUID validation) after simple_visit_v3 merges",
  "thread_id": null,
  "to": [
    "RubyCliff",
    "Td_Eddie",
    "Td_Carl"
  ]
}
---

# Rebase reminder: PR #775 on top of simple_visit_v3

When `worktree-simple_visit_v3` merges to main, PR #775 (`worktree-fix-silent-sightings`) needs a rebase.

## What #775 does
Adds UUID format validation at the top of `SightingIngestionService#process_sighting`. Non-UUID sighting_ids get an actionable error message instead of the cryptic "Sighting can't be blank" from PostgreSQL's silent uuid→nil coercion.

## Why it matters
Both branches modify `sighting_ingestion_service.rb`. The changes are logically orthogonal (UUID validation at entry vs alpr role handling deeper in the pipeline) but will conflict textually.

## What to do
After simple_visit_v3 merges:
```bash
git checkout worktree-fix-silent-sightings
git pull --rebase origin main
# Resolve any conflict in sighting_ingestion_service.rb
# (trivial — UUID_FORMAT constant and validation block go right after `def process_sighting`)
git push --force-with-lease
gh pr ready 775
```

The PR is currently in draft with a blocking note.
