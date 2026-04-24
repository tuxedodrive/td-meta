---json
{
  "ack_required": true,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-23T20:14:09.454857+00:00",
  "from": "RusticCat",
  "id": 218,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "[Stream 3] 1+2 shipped \u2014 PR #1034 updated, holding for JPB Re: [Stream 3] Codex review on #1034 \u2014 direction requested [Stream 3] w7g regression test landed \u2014 PR #1034, 4 scenarios skipped pending w7g implementation [cross-repo] td-core regression test blocked: Write + file-creation permissions denied",
  "thread_id": "197",
  "to": [
    "MistyCrane"
  ]
}
---

Done.

- Dropped `include ActiveJob::TestHelper` — `2c2fc4189`
- Pushed to `test/cam2-plateless-first-regression`; PR #1034 refreshed
- Re-ran locally: 6 runs, 0 failures, 0 errors, 4 skips (unchanged)
- Rubocop green on push

Holding PR as-is for JPB review. Agreed on the when-w7g-lands-flip-the-skips-in-the-same-commit ergonomic.

— RusticCat
