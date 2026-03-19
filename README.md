🌌 Why does td-meta exist?
=============================

TuxedoDrive operates multiple repositories (td-core, td-edge, td-tailor, td-training) that share common infrastructure needs. Rather than duplicating GitHub Actions workflows, architectural decisions, and documentation patterns across repos, td-meta serves as the single source of truth for cross-repository infrastructure. It's the kitchen sink for everything that doesn't belong in a single repo.


🌌🌌 Who benefits from td-meta?
=============================

- Engineers working across multiple TuxedoDrive repositories
- DevOps engineers maintaining CI/CD pipelines and reusable workflows
- Claude Code agents requiring access to shared skills and patterns
- Product managers understanding architectural decisions spanning repositories
- New team members learning TuxedoDrive's organizational structure and conventions


🌌🌌🌌 What exactly does td-meta provide?
=============================

## Reusable GitHub Actions Workflows

Shared workflow definitions in `.github/workflows/` referenced by consuming repositories. Current workflows:

- `claude-code-review.yml` — Auto-reviews PRs on open using Claude Code Action. Uses sticky comments and read-only GitHub tools.
- `claude.yml` — @claude agent responds to mentions in issues and PR comments, with Ruby and PostgreSQL environment.
- `fix-broken-build.yml` — Self-healing CI that analyzes failures on main and attempts automated fixes for infrastructure issues.
- `project-auto-add.yml` — Auto-adds issues and PRs to the GitHub Project board.

## Claude Code Skills

TuxedoDrive-specific skills for Claude Code and other agents, symlinked into `~/.claude/skills/`. These cover:

- Multi-tenant code patterns and data isolation
- Money handling and financial transaction logic
- Service object creation and business logic organization
- Cucumber/BDD feature testing
- Deployment and release workflows
- Integration patterns (td-edge API contracts, enemy testing)

General-purpose agent skills live upstream in [dw-agent-skills](https://github.com/discoveryworks/dw-agent-skills) (DiscoveryWorks, not TuxedoDrive). td-meta is the canonical home for TD-specific skills; dw-agent-skills is for skills that aren't specific to any one organization.

## PHEELblog Aggregation

Aggregates Plans, Hypotheses, Explorations, Experiments, and Learnings from all sub-repositories into a single chronological blog. Each sub-repo maintains its own `docs/pheels/` directory; td-meta pulls them together for unified documentation.

## Cross-Repository ADRs

Architecture Decision Records affecting multiple repositories. These complement repo-specific ADRs and document:

- Inter-repository communication patterns
- Shared infrastructure choices
- Organization-wide tooling decisions
- Cross-cutting architectural concerns

## Contract Definitions

Shared API contracts and schemas between repositories (e.g., td-core ↔ td-edge detection API). Centralized here per ADR-028 when appropriate.


🌌🌌🌌🌌 How do I use td-meta?
=============================

## Referencing Reusable Workflows

In your repository's workflow file:

```yaml
jobs:
  review:
    uses: tuxedodrive/td-meta/.github/workflows/claude-code-review.yml@main
    secrets: inherit
```

Consuming repositories inherit secrets from the organization context automatically.

## Accessing Claude Code Skills

Skills are symlinked into `~/.claude/skills/` for local use. Invoke them in Claude Code sessions:

```
Use the service-object-creation skill for this.
```

Or mention them directly:

```
@service-object-creation
```

## Reading Cross-Repo ADRs

Browse `docs/adr/` to understand decisions affecting multiple repositories. ADRs are immutable records — use sequential numbering (e.g., 001, 002, 003) for cross-repo decisions.

## Contributing

Changes here can affect all TuxedoDrive repos. Branch, PR, and coordinate rollout across consuming repositories before merging.


🌌🌌🌌🌌🌌 Extras
=============================

## Repository Structure

```
td-meta/
├── .github/
│   └── workflows/        # Reusable GitHub Actions workflows
├── skills/               # Claude Code skills (symlinked to ~/.claude/skills/)
├── docs/
│   ├── adr/             # Cross-repository ADRs
│   ├── pheels/          # Aggregated PHEELblog entries
│   └── templates/       # Documentation templates
├── contracts/           # Shared API contracts
└── README.md
```

## Related Repositories

- [td-core](https://github.com/tuxedodrive/td-core) — Rails business platform with customer portals, operator interfaces, and owner dashboards
- [td-edge](https://github.com/tuxedodrive/td-edge) — On-premises detection system running at carwash locations
- [td-tailor](https://github.com/tuxedodrive/td-tailor) — Infrastructure and configuration management for on-premises systems
- [td-training](https://github.com/tuxedodrive/td-training) — AI model training specific to car wash concerns

## Principles

1. **DRY Infrastructure** — Don't duplicate workflows across repos when a reusable workflow suffices
2. **Clear Ownership** — Document which repo owns what (repository-specific ADRs stay in their repos)
3. **Coordination Required** — Changes here may affect multiple repositories
4. **Immutable Records** — ADRs and PHEELblog entries are permanent; don't modify them
