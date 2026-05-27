ABOUTME: Cross-repository policy for agent-created git worktrees.
ABOUTME: Defines the default layout and Gas City exception for TuxedoDrive repos.

# Agent Worktree Policy

This policy applies to normal feature work by AI agents across TuxedoDrive
repositories.

## Default Rule

Agents doing feature work use git worktrees by default. The canonical checkout is
for human coordination, syncing, reviewing, and release operations unless the
user explicitly says otherwise.

## Repo-Local Layout

Use a repo-local worktree root:

```text
.worktrees/<slug>
```

The slug should be stable and human-readable, usually an issue id, PR number, or
short purpose:

```text
.worktrees/tdc-64i
.worktrees/pr-1309
.worktrees/codex-build-green-20260526
```

## Claude

Keep Claude plain vanilla:

```bash
claude --worktree <slug>
```

Claude's default path is `.claude/worktrees/<slug>`. To centralize repo-local
worktrees without Claude hooks, a repo may symlink:

```text
.claude/worktrees -> ../.worktrees
```

Only flip that symlink when no active git worktrees are registered under
`.claude/worktrees`. Verify first:

```bash
git worktree list --porcelain
```

## Codex

Codex CLI does not currently provide a native `--worktree <slug>` command. Use
the shared helper or the equivalent git commands:

```bash
scripts/agent-worktree codex <slug>
codex --cd .worktrees/<slug>
```

If a consuming repo vendors the helper into `bin/agent-worktree`, use:

```bash
bin/agent-worktree codex <slug>
```

## Gas City Exception

Gas City worktrees are a separate orchestrated system. Do not move, symlink,
rename, or recreate worktrees under:

```text
.gc/worktrees/...
```

Gas City records absolute `metadata.work_dir` paths for recovery and handoff.
Those paths are part of its runtime contract, not disposable local layout.

## Migration

For repos that already have active `.claude/worktrees` entries:

1. Leave existing worktrees in place.
2. Create new ad hoc worktrees under `.worktrees/<slug>`.
3. Remove completed Claude worktrees with `git worktree remove`.
4. After `.claude/worktrees` is empty and no active worktree path points there,
   replace it with the symlink to `../.worktrees`.

Never move a git worktree directory by hand. Use `git worktree` commands so Git's
metadata stays correct.
