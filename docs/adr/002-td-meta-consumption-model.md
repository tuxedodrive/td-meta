# ADR-002: Define td-meta Consumption Model for Cross-Repo Assets

**Date**: 2026-05-27
**Status**: Accepted
**Deciders**: JPB, Codex

## Context

ADR-000 defines why td-meta exists: cross-repository infrastructure and
decisions live here instead of being copied independently into every td-* repo.
ADR-001 defines one concrete use case: GitHub reusable workflows.

We now also have cross-repo operational policies and helper scripts, such as the
agent worktree policy and `scripts/agent-worktree`. Those assets do not all fit
the reusable-workflow model:

- Documentation and policies are read by agents and humans.
- GitHub workflows can be called remotely by Actions.
- Shell scripts often need to run inside the consuming repo checkout.
- Some consumers need a vendored copy for discoverability or offline use.

Without a consumption model, td-meta risks becoming a dumping ground: shared
files exist here, but each repo guesses whether to link, copy, vendor, or ignore
them.

## Decision

td-meta will classify cross-repo assets by consumption pattern:

1. **Referenced assets**: canonical docs, ADRs, and policies that consuming repos
   link to from `AGENTS.md`, README files, or repo-specific docs.
2. **Called assets**: reusable GitHub Actions workflows invoked with
   `uses: tuxedodrive/td-meta/...@<ref>`.
3. **Vendored assets**: helper scripts or templates copied into consuming repos
   when they must be available at a stable local path like `bin/...`.
4. **Generated assets**: future files produced from td-meta templates by an
   explicit sync command.

For vendored assets, td-meta remains the source of truth. Consuming repos may
carry local copies, but those copies should include a short source comment and
should be refreshed deliberately from td-meta.

## Rules

- Cross-repo policy starts in td-meta.
- Consuming repos should link to td-meta policy docs instead of restating the
  full policy.
- Reusable workflows should stay remote-called from td-meta unless GitHub
  Actions requires a local caller file.
- Scripts should be vendored only when the caller needs a local executable path,
  local repo context, or offline/discoverable behavior.
- Vendored scripts should be small, stable, and have no repo-specific secrets or
  hardcoded local machine paths.
- Gas City-managed runtime paths and metadata contracts are not td-meta-vendored
  assets; those belong to Gas City.

## Implementation

The practical operating model is documented in
`docs/policies/td-meta-consumption.md`.

td-meta provides:

- `docs/policies/` for cross-repo operational policy.
- `scripts/` for shared helper scripts.
- `.github/workflows/` for reusable workflows.
- `docs/templates/` for documentation templates.

The first vendored-script candidate under this model is `scripts/agent-worktree`.
Repos that want a local helper may copy it to `bin/agent-worktree` while linking
their `AGENTS.md` back to `td-meta/docs/policies/agent-worktrees.md`.

## Consequences

Positive:

- td-meta becomes an operational source of truth, not just an archive.
- Consuming repos have a clear rule for link vs call vs vendor.
- Future shared scripts can be rolled out intentionally and audited.

Tradeoffs:

- Vendored copies can drift if not refreshed.
- Some repo-local instructions still need small local pointers.
- We will need follow-up tooling if vendored assets become numerous.

## References

- [ADR-000: Why td-meta Exists](./000-why-td-meta-exists.md)
- [ADR-001: Consolidate Backlog Automation Using Reusable Workflows](./001-consolidate-backlog-automation.md)
- [Agent Worktree Policy](../policies/agent-worktrees.md)
- [td-meta Consumption Policy](../policies/td-meta-consumption.md)
