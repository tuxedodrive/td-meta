# Workflows

## Reusable (called via `uses:` from consuming repos)

| Workflow | Purpose |
|----------|---------|
| `claude-code-review.yml` | PR auto-review with Claude Code Action |
| `project-auto-add.yml` | Auto-add issues/PRs to GitHub Project board |
| `backlog-automation.yml` | Project board status transitions on branch/PR/merge events |

Callers in consuming repos: see `examples/callers/`.

## Per-repo (deployed directly to each repo)

Named `{workflow}.{repo}.yml` — edit here, deploy to the repo's `.github/workflows/`.

| Workflow | Deployed as | Purpose |
|----------|-------------|---------|
| `claude.td-core.yml` | `td-core/.github/workflows/claude.yml` | @claude agent with Ruby/Postgres |
| `claude.td-edge.yml` | `td-edge/.github/workflows/claude.yml` | @claude agent with Python |
| `fix-broken-build.td-core.yml` | `td-core/.github/workflows/fix-broken-build.yml` | Self-healing CI |
