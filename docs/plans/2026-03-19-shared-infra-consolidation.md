---
layout: post
title: "Shared Infrastructure Consolidation into td-meta"
date: '2026-03-19'
category: plans
tags: [infrastructure, github-actions, agents, td-meta]
llm-relevance: high
---

# Shared Infrastructure Consolidation

## Status: Phase 1 complete (copy into td-meta). Phase 2 not started (cutover).

## Problem

Shared config (GitHub Actions workflows, Claude Code agents, skills) is
duplicated across td-core, td-edge, td-tailor, td-training with no single
source of truth. A bug fix in one repo (e.g., the review spam fix) doesn't
propagate to others.

## Strategy: Copy first, cut over later

Phase 1 is non-destructive — everything is copied INTO td-meta while the
originals remain untouched in each repo. Phase 2 (cutover) replaces local
copies with symlinks/callers pointing to td-meta. Phase 2 happens one repo
at a time.

---

## Phase 1: Copy into td-meta (DONE)

All done on branch `consolidate-shared-infra` (PR #1).

- [x] Reusable workflows: `claude-code-review.yml`, `project-auto-add.yml`
- [x] Per-repo workflows: `claude.td-core.yml`, `claude.td-edge.yml`, `fix-broken-build.td-core.yml`
- [x] Caller examples in `examples/callers/`
- [x] 9 generic agent definitions in `.claude/agents/`
- [x] `bin/setup-meta` script for symlinking agents
- [x] README rewritten
- [x] AGENTS.md updated with workflow architecture

## Phase 2: Cut over consuming repos (NOT STARTED)

Do one repo at a time. Each step is independently reversible.

### 2a. td-core workflows

1. Merge td-core PR #688 (workflow fix — independent, safe to merge now)
2. Replace `td-core/.github/workflows/claude-code-review.yml` with the thin
   caller from `examples/callers/claude-code-review.yml`
3. Deploy `claude.td-core.yml` as `td-core/.github/workflows/claude.yml`
   (this is the same content, just sourced from td-meta now)
4. Deploy `fix-broken-build.td-core.yml` as `td-core/.github/workflows/fix-broken-build.yml`
5. Test: open a non-draft PR on td-core, verify the review posts cleanly

**Rollback**: revert the caller workflow commit. The old workflow is in git history.

### 2b. td-core agents

1. Run `../td-meta/bin/setup-meta` from td-core root
2. Verify agents appear as symlinks in `.claude/agents/`
3. Test: invoke `@architect` in Claude Code, verify it reads GUIDELINES-ARCHITECTURE.md
4. If working: delete td-core's local agent files (they're now symlinks)
5. Add `.claude/agents/` to `.gitignore` (symlinks shouldn't be committed)

**Rollback**: delete the symlinks, `git checkout .claude/agents/` to restore originals.

### 2c. td-edge workflows

1. Replace `td-edge/.github/workflows/claude-code-review.yml` with thin caller
2. Deploy `claude.td-edge.yml` as `td-edge/.github/workflows/claude.yml`
   (replaces the broken bare-bones version that had read-only permissions)
3. Test: open a non-draft PR on td-edge

### 2d. td-edge agents

1. Run `../td-meta/bin/setup-meta` from td-edge root
2. td-edge gets all 9 agents immediately (currently has none)
3. Create `GUIDELINES-ARCHITECTURE.md` for td-edge (Python/detection-specific)

### 2e. td-tailor and td-training

1. Both currently only have `project-auto-add.yml` — replace with thin caller
2. Run `bin/setup-meta` for agents
3. Create minimal GUIDELINES files as needed

## Phase 3: Skills migration (FUTURE)

Move TD-specific skills from `dw-agent-skills` into `td-meta/skills/`.
General-purpose skills stay in dw-agent-skills. Update `bin/setup-meta`
to symlink skills too.

## Phase 4: PHEELblog aggregation (FUTURE)

Set up td-meta to aggregate `docs/pheels/` from all sub-repos into a
single Jekyll-rendered PHEELblog.

---

## Key decisions

- **Symlinks for agents** (not submodules, not packages). Requires td-meta
  to be cloned locally. Simple, zero-overhead, already proven pattern.
- **Reusable workflows for universal actions** (claude-code-review,
  project-auto-add). Called via `uses:` from thin callers.
- **Per-repo workflows stored in td-meta** but deployed directly to each
  repo. Named `{workflow}.{repo}.yml`. Can't be reusable because they need
  repo-specific triggers and services.
- **Agents reference GUIDELINES generically** ("read GUIDELINES-ARCHITECTURE.md")
  rather than embedding repo-specific content. Each repo's GUIDELINES files
  provide the domain knowledge.

## Related

- td-core PR #688: workflow spam fix (merge independently)
- td-meta PR #1: this consolidation work
