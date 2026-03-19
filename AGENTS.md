ABOUTME: Guidelines for AI agents working on td-meta repository infrastructure.
ABOUTME: This file establishes practices for maintaining cross-repository infrastructure.

# TD-Meta Agent Guidelines

This repository contains cross-repository infrastructure for TuxedoDrive. Changes here can affect multiple repositories, so extra care is required.

## Workflow Architecture

Workflows fall into two tiers:

### Reusable workflows (called via `uses:`)
- `claude-code-review.yml` — PR auto-review, same everywhere
- `project-auto-add.yml` — auto-add issues/PRs to GitHub Project

Consuming repos use thin callers (see `examples/callers/`):
```yaml
jobs:
  review:
    uses: tuxedodrive/td-meta/.github/workflows/claude-code-review.yml@main
    secrets: inherit
```

### Per-repo workflows (deployed directly)
Named `{workflow}.{repo}.yml` — stored here, deployed to each repo's `.github/workflows/`:
- `claude.td-core.yml` → td-core's @claude agent (Ruby/Postgres)
- `claude.td-edge.yml` → td-edge's @claude agent (Python)
- `fix-broken-build.td-core.yml` → td-core's self-healing CI

These can't be reusable workflows because they need repo-specific triggers, services, and event context.

## Core Principles

1. **Blast radius**: Changes to reusable workflows affect all consuming repos immediately.
2. **Per-repo workflows need deployment**: After editing a `*.td-core.yml` file, deploy it to the consuming repo.
3. **Immutable ADRs**: Cross-repo ADRs follow the same immutability rules as repo-specific ADRs.

## Related Repositories

- [td-core](https://github.com/tuxedodrive/td-core) — Rails business platform
- [td-edge](https://github.com/tuxedodrive/td-edge) — On-premises detection system
- [td-tailor](https://github.com/tuxedodrive/td-tailor) — Infrastructure management (fka td-fleet)
- [td-training](https://github.com/tuxedodrive/td-training) — AI model training

Consult each repository's AGENTS.md for repo-specific guidelines.
