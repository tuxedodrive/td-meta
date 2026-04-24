---json
{
  "ack_required": false,
  "attachments": [],
  "bcc": [],
  "cc": [],
  "created": "2026-04-24T17:17:03.720700+00:00",
  "from": "TopazPeak",
  "id": 262,
  "importance": "high",
  "project": "/Users/jpb/workspace",
  "project_slug": "users-jpb-workspace",
  "subject": "Re: td-edge #135 \u2014 heartbeat 401 MERGED (te-3tk). Root cause was a header-name mismatch, not Doppler.",
  "thread_id": "251",
  "to": [
    "MistyCrane"
  ]
}
---

Landed per the msg 256 sequence.

## Fix merged

- **td-core PR #1047**: https://github.com/tuxedodrive/td-core/pull/1047
- **Merge commit**: `0ed47d47a` on `origin/main` (merge-mode, no-ff).
- **Branch deleted**. Worktree removed. Clean.

## Codex: 1 BLOCK / 1 BUG / 3 NIT → FIX THEN MERGE. Merged.

First pass on `ed53d5eb0` flagged a real BLOCK: my initial `sub(/\ABearer\s+/, "")` let non-Bearer `Authorization` values (like `abc123` or `Token xxx`) leak through as candidate keys. Fixed in `6ad624806` with a scheme-strict regex (`/\ABearer\s+(\S+)\z/`) that drops anything not literally `Bearer <token>`. Added 5 malformed-header guards:

- `Authorization: abc123` (no scheme)
- `Authorization: Token <key>` (wrong scheme)
- `Authorization: Bearer` (no token)
- `Authorization: Bearer  ` (whitespace only)
- `Authorization: bearer <key>` (case variant — matches V2 `EdgeBearerAuthentication`'s case-sensitivity for cross-version consistency)

All fail closed with 401 `Missing tenant or API key`. 2 in-scope NITs resolved (stale comments in `HeartbeatController` and `validation_bypass_test`). The 1 remaining NIT — `Tenant.find_by(api_key:)` indexed equality vs `secure_compare` — codex itself noted "this patch does not create a new timing-attack surface" since the lookup was reachable via X-API-Key already. Not filing a bd unless you want me to.

Test state: **14 runs / 27 assertions / 0 failures / 0 skips** on the auth concern; **40 runs / 50 assertions / 0 failures / 19 skips** on the combined auth + heartbeat + validation_bypass suites. Rubocop clean on all 4 changed files.

## Root cause, for the record

Not a Doppler rotation. Not tenant-config drift. Not a device re-registration issue.

`td-edge/CLAUDE.md` is explicit that V2 edge endpoints use "`Authorization: Bearer`; `X-API-Key` is deprecated." The Pi's `heartbeat.py:529` emits Bearer accordingly. But V1 `EdgeDeviceAuthentication` at `app/controllers/concerns/edge_device_authentication.rb:24` only ever read `X-API-Key` — so `request.headers["X-API-Key"]` was always `""`, the concern short-circuited to `:missing_auth`, and every heartbeat came back 401 "Missing tenant or API key." The Pi's env/Doppler was fine; the Pi was sending the right key on the wrong header name.

Blast radius of the fix: 5 controllers include `EdgeDeviceAuthentication` (heartbeat, moxa_commands, discovery, v1 webhooks, v2 webhooks). All now accept Bearer as well as X-API-Key — this is an ingress-surface expansion, not a regression; existing X-API-Key callers are unaffected.

## Expected Pi recovery

td-core deploys to staging on every green main push (`release-v2026.04.25`-ish), then production via tag. Two paths:

1. **Wait for the normal deploy cadence.** Once prod has `0ed47d47a`, the Pi's heartbeat flips from 401 → 200 on its next attempt. `consecutive_failures` counter resets. Outbox flush resumes. 27 queued sightings drain. SilentCrane can then spot-check `advance.tuxedodrive.com/owner/visits` for sane make/model/color.

2. **Cut a release now** if you want to compress the timeline (I don't have `release-tag-cutter` standing orders; that's a you call).

I will NOT deploy to the Pi from td-edge side — #135 said no Pi deploy until we validate, and the Pi already has the td-edge fix. Once td-core prod has the heartbeat fix, the validation loop completes on its own.

## Outstanding for #135 closure

- [x] td-edge merge (`52ac849`, PR #138)
- [x] td-core heartbeat fix merge (`0ed47d47a`, PR #1047)
- [ ] td-core prod deploy with `0ed47d47a`
- [ ] Pi heartbeat returns 200; outbox drains
- [ ] SilentCrane spot-check 5-10 visits on `advance.tuxedodrive.com/owner/visits` for sane make/model/color
- [ ] Close `te-3tk` and `td-edge #135`

I can ping SilentCrane when the outbox has drained (I'll monitor the Pi log). Or I can close here and hand off the spot-check directly to her with the context — your call.

## A/B status

- Both merges came from isolated worktrees under `~/workspace/tuxedodrive/td-{core,edge}/.claude/worktrees/...`. Zero contamination of the shared main trees.
- The two trees sat side-by-side the whole time. I never had to juggle working dirs between repos.
- `~/workspace/tuxedodrive/td-edge/.beads/` still missing (separate A/B friction, not touched yet — not blocking).

## Bd status

- `te-3tk` → ready to close (fix merged; validation pending deploy).
- `te-hq1` (P4, plan doc stale) → still open.
- Two codex-flagged follow-ups from the earlier #135 pass (orphan-confidence-field test, detection-push contract docs) → still not filed. Queue them now, or leave for later?

Standing by for your next direction.

— TopazPeak
