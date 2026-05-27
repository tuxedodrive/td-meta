🌌 Why does td-meta exist?
=============================

TuxedoDrive operates multiple repositories (td-core, td-edge, td-tailor, td-agent, td-training) that share common infrastructure needs. Rather than duplicating GitHub Actions workflows, architectural decisions, and documentation patterns across repos, td-meta serves as the single source of truth for cross-repository infrastructure.


🌌🌌 Who benefits from td-meta?
=============================

- Developers working across multiple td-* repositories
- DevOps engineers maintaining CI/CD pipelines
- Product managers understanding architectural decisions that span repositories
- New team members learning TuxedoDrive's organizational patterns


🌌🌌🌌 What exactly does td-meta provide?
=============================

## Cross-Repo ADRs

Architectural Decision Records that affect multiple repositories live in `docs/adr/`. These complement repo-specific ADRs and document decisions about:

- Inter-repo communication patterns
- Shared infrastructure choices
- Organization-wide tooling decisions
- Cross-cutting architectural concerns

## Reusable GitHub Actions Workflows

Shared workflow definitions in `.github/workflows/` that can be referenced from other repositories using workflow calls. This ensures consistency in:

- CI/CD processes
- Deployment patterns
- Testing strategies
- Security scanning

## Contract Definitions

Shared API contracts and schemas that multiple repositories depend on (when appropriate to centralize rather than keep in the owning repository per ADR-028).

## Documentation Templates

Standard templates for ADRs, PHEELs, and other documentation to maintain consistency across repositories.

## Agent Worktree Policy

The cross-repo policy for AI-agent feature work lives in
`docs/policies/agent-worktrees.md`. It defines `.worktrees/<slug>` as the
normal repo-local destination, keeps `claude --worktree <slug>` plain vanilla
through an optional `.claude/worktrees -> ../.worktrees` symlink, gives Codex a
shared helper path, and carves out Gas City-managed `.gc/worktrees` as a
separate orchestrated system.

## Consumption Model

The rules for using td-meta assets from consuming repos live in
`docs/policies/td-meta-consumption.md`. Shared assets should be classified as
link/reference, remote call, vendor, or generate so td-meta remains the source of
truth without forcing every repo to copy everything.


🌌🌌🌌🌌 How do I use td-meta?
=============================

## Referencing Reusable Workflows

In your repository's workflow file:

```yaml
jobs:
  shared-job:
    uses: tuxedodrive/td-meta/.github/workflows/reusable-workflow.yml@main
    with:
      parameter: value
```

## Reading Cross-Repo ADRs

Browse `docs/adr/` to understand architectural decisions that affect multiple repositories. ADRs follow the same immutable format as repo-specific ADRs.

## Contributing Cross-Repo Infrastructure

1. Clone this repository
2. Create a feature branch
3. Add or modify infrastructure (workflows, ADRs, contracts)
4. Submit a PR for review
5. Coordinate rollout across affected repositories


🌌🌌🌌🌌🌌 Extras
=============================

## Repository Structure

```
td-meta/
├── .github/
│   └── workflows/        # Reusable GitHub Actions workflows
├── docs/
│   ├── adr/             # Cross-repository ADRs
│   ├── policies/        # Cross-repository operational policies
│   └── templates/       # Documentation templates
├── scripts/             # Shared helper scripts for consuming repos
├── contracts/           # Shared API contracts (when centralized)
└── README.md
```

## Related Repositories

- [td-core](https://github.com/tuxedodrive/td-core) - Core Rails application
- [td-edge](https://github.com/tuxedodrive/td-edge) - Edge detection system
- [td-tailor](https://github.com/tuxedodrive/td-tailor) - Fleet management
- [td-agent](https://github.com/tuxedodrive/td-agent) - AI Phone Customer Service Agent
- [td-training](https://github.com/tuxedodrive/td-training) - Training materials

## Principles

1. **DRY Infrastructure**: Don't duplicate workflows across repos when a reusable workflow suffices
2. **Clear Ownership**: Document which repo owns what (e.g., td-core owns API contracts per ADR-028)
3. **Coordination Required**: Changes here may affect multiple repositories - coordinate rollouts
4. **Immutable ADRs**: Like all ADRs, cross-repo ADRs are immutable records of decisions
