---
layout: post
title: "bd backlog purge + prefix realignment"
date: '2026-05-12'
category: learnings
tags: [tooling, beads, dolt, gas-city, cleanup, librarian]
llm-relevance: high
authors: [JPB, PearlCreek]
---

# bd backlog purge + prefix realignment

## Why

Beads backlogs across the td-* repos had drifted into an unusable state:

- **Gas-city ephemera dominated story tickets ~99:1.** Each gc rig iteration
  (wisp, molecule, order, session, convoy) spawned a bead, and they piled up
  faster than they got cleaned. td-city alone had 12,502 beads — 39 of which
  were real bugs/features.
- **Prefixes were inconsistent.** `core/tm/tc/te/tta/ttr/tds` instead of a
  uniform `td*` namespace. With TuxedoBay planned as a second company,
  we wanted `tb*` reserved cleanly.
- **Dolt storage was bloated.** Server-mode `.beads/dolt/` directories had
  cross-DB contamination (td-city's server hosted `hq`, `td_core`,
  `td_training`, `tm`, and `beads`). bd rename-prefix walked all DBs at once
  and saw 468 issues where only 38 lived in the active workspace.
- **Gas City couldn't reasonably use the backlog as-is.**

## What we did

### Phase 1 — Inventory + ephemera detection

Built a filter (`/tmp/ephemera-identify.py`) that sniffs ephemera by:

- Title patterns: `^order:`, `^nudge:`, `^Stuck:`, `^ci-failure:`,
  `^backlog-audit:`, `^WRITE_TEST`, `^Probe`, etc.
- Issue types: `session`, `molecule`, `convoy`, `wisp`, `gate`,
  `merge-request`, `agent`, `role`, `rig`, `spec`, `convergence`,
  `message`, `event`
- Labels matching `order-tracking`, `exec`, `wisp`, `gc:session`, or
  prefixes like `order-run:`, `agent:`, `convoy:`, `molecule:`, `rig:`,
  `session:`, `wisp:`, `pool:`, `inbox:`
- Description patterns: `gc nudge`, `DOG_DONE`, `drain-ack`, `gc bd
  (close|list|create)`, `gastown.mayor`, etc.
- Subtask inheritance: if `bd-abc` is ephemera, `bd-abc.N` is too.

### Phase 2 — Purge

Per workspace:

1. Export current dolt → jsonl
2. Run filter → split into `<repo>-real.txt` + `<repo>.txt` (ephemera ids)
3. `bd delete --from-file <ephemera-ids> --force`
4. Immediately `bd export -o .beads/issues.jsonl` to overwrite stale jsonl
   (else auto-import re-reads the old jsonl and reverts the delete).

Some repos had no useful local state — those we wiped and re-ran `bd init`
against the configured `sync.remote` (git remote), which rebuilt dolt from
the canonical git-tracked issues.

### Phase 3 — Prefix realignment

```text
td-core    → tdc-
td-edge    → tde-
td-meta    → tdm-
td-status  → tds-
td-tailor  → tdl-
td-training→ tdr-
td-city    → tdx-
```

Used `bd rename-prefix <new>- --repair` (the `--repair` flag consolidates
mixed prefixes that accumulate when issues get imported from different
sources).

### Phase 4 — Storage shrink

Backup tarballs (one per repo) were dominated by `.beads/backup/*.darc`
files — dolt's internal noms archive snapshots. The 12k-issue wisp churn
on td-city produced 2.3GB of redundant `.darc` chunks. Across 9 repos:
**7.8GB of bloat.**

For preservation, we dropped from each tarball:

- `.beads/dolt/` (dolt binary state, reconstructible from jsonl)
- `.beads/embeddeddolt/` (same)
- `.beads/backup/` (redundant `.darc` archive snapshots — the real bloat)

Kept the source-of-truth text bits: `issues.jsonl`, `config.yaml`, `hooks/`,
`formulas/`, `metadata.json`, `interactions.jsonl`, `routes.jsonl`,
`last-touched`, `README.md`.

**Result: 7.8 GB → 1.4 MB (≈5700×).**

## Final state

| repo | prefix | total | open | notes |
|------|--------|-------|------|-------|
| td-core | `tdc` | 390 | 171 | rebuilt from git remote |
| td-edge | `tde` | 5 | 1 | rebuilt from git remote |
| td-meta | `tdm` | 11 | 11 | purged 1463 → 11 |
| td-status | `tds` | 0 | – | already aligned |
| td-tailor | `tdl` | 0 | – | prefix re-aligned |
| td-training | `tdr` | 0 | – | purged 1307 → 0 |
| td-city | `tdx` | 38 | 25 | purged 12502 → 38 |

Also: `tdc-0sa3` (supervisor wedge bug — stale `ANTHROPIC_API_KEY` in
gc supervisor env) got renamed to `tdx-12d7e3ca` because it lived in
td-city's backlog. The bug describes a gas-city issue, so td-city is a
reasonable home, but move to td-core if you'd rather see it there.

A snapshot from 2026-05-07 has 35 records not in the current
td-core remote — likely unpushed WIP. Preserved at
`td-core-bd-snapshot-2026-05-07.jsonl` inside the asset bundle.

## How to reconstruct (if a real ticket got nuked)

The shrunk backups live at `assets/2026-05-12-bd-backlog-purge/backups.tar.gz`
(relative to this post).

```bash
# Extract the asset bundle
tar -xzf docs/pheels/_pheels/assets/2026-05-12-bd-backlog-purge/backups.tar.gz -C /tmp
cd /tmp/td-cleanup-backups-2026-05-12

# Per-repo backup is one tar.gz, e.g. td-city-beads.tar.gz
# It contains the FULL pre-purge .beads/ directory (text bits only)
mkdir /tmp/recover && cd /tmp/recover
tar -xzf /tmp/td-cleanup-backups-2026-05-12/td-city-beads.tar.gz
# Now /tmp/recover/.beads/issues.jsonl has the full pre-purge state
# (e.g. td-city had 12,518 lines before purge)

# To rebuild a working bd workspace from this:
cd /tmp/recover
bd init --prefix=<prefix> --non-interactive
# auto-import reads issues.jsonl and rebuilds dolt
bd stats
```

Per-repo asset bundle contents:

- `<repo>-beads.tar.gz` — full pre-purge `.beads/` (minus dolt binaries)
- `ephemera-ids/<repo>.txt` — every id we deleted (so you can grep for a
  ticket id and see if/why it was dropped)
- `ephemera-ids/<repo>-real.txt` — every id we kept
- `td-core-bd-snapshot-2026-05-07.jsonl` — extra td-core snapshot with
  35 records not in remote
- `td-city-pre-rebuild.jsonl` — td-city state before final rebuild

## Lessons

Captured as `bd remember` entries in td-city (stored as bd memories so they
surface in future sessions; search with `bd memories <keyword>`):

- **bd-init-pulls-from-git-remote** — `bd init` will pull canonical issues
  from `sync.remote` automatically. Use this to recover from corrupted
  local state when the remote exists.
- **bd-rename-prefix-cross-db** — `bd rename-prefix` in dolt server-mode
  walks ALL databases on the same dolt server, not just the active one.
  Use embedded mode to isolate.
- **gas-city-ephemera-vs-real** — Gas-city wisps/molecules/orders/etc.
  are message-passing artifacts, not story tickets. Detect by issue type
  + title prefix + label prefix.

Also: when auto-import is enabled (the default), `bd delete` from dolt is
not safe on its own. The next read re-imports a stale jsonl and resurrects
the deleted records. Always `bd export -o .beads/issues.jsonl` immediately
after a bulk delete to overwrite the jsonl with the post-delete state.

## Future work — gc ephemera lifecycle

The root cause of the 12k bloat is that gc rigs create beads as their
work-tracking substrate but nothing reaps them when work is done. Options:

- gc closes its own wisps on rig exit (preferred — locality of cleanup)
- A separate sweeper rig runs nightly and prunes closed-and-stale ephemera
- Move gc ephemera to a separate dolt DB (`gc_ephemera`) so it never
  pollutes the story-ticket backlog

Filed as part of the gas-city backlog hygiene work.
