ABOUTME: Operating model for consuming shared assets from td-meta.
ABOUTME: Defines when repos should link, call, vendor, or generate cross-repo infrastructure.

# td-meta Consumption Policy

td-meta is the source of truth for cross-repo infrastructure, policies, and
decisions. Consuming repos should use the lightest integration pattern that keeps
the source of truth clear and avoids unnecessary copying.

## Asset Types

| Asset type | Lives in td-meta | Consumption pattern |
| --- | --- | --- |
| Cross-repo ADRs | `docs/adr/` | Link/reference |
| Operational policies | `docs/policies/` | Link/reference |
| Reusable GitHub workflows | `.github/workflows/` | Remote `uses:` call |
| Documentation templates | `docs/templates/` | Copy or generate from source |
| Helper scripts | `scripts/` | Vendor only when a local executable is useful |
| Shared contracts | `contracts/` | Link or package; prefer owning repo when one exists |

## Link

Use links for canonical docs that agents and humans read.

Examples:

- `AGENTS.md` points to `td-meta/docs/policies/agent-worktrees.md`.
- Repo ADRs cite a td-meta ADR for cross-repo decisions.

Local docs may summarize the rule, but should not duplicate the full policy.

## Call

Use remote calls for GitHub Actions reusable workflows:

```yaml
jobs:
  shared:
    uses: tuxedodrive/td-meta/.github/workflows/example.yml@main
```

Caller workflows should stay small and repo-specific only where GitHub requires
local event triggers or secrets wiring.

## Vendor

Vendor a td-meta asset into a consuming repo only when it must exist locally.
Good reasons:

- Agents need a stable local command like `bin/agent-worktree`.
- The script needs to run from the consuming repo's git root.
- Offline/discoverable behavior matters.

Vendored files should include:

- A short source comment pointing back to td-meta.
- Minimal repo-specific edits.
- A clear refresh path in the commit or rollout notes.

Example:

```text
td-meta/scripts/agent-worktree -> td-core/bin/agent-worktree
```

## Generate

Use generation when the local file has a stable shape but repo-specific values.
This is appropriate for future templates such as:

- Standard `AGENTS.md` sections.
- Workflow caller stubs.
- Shared config fragments.

Generated files should include a comment naming the generator or source template.

## Ownership Rules

- Cross-repo policy starts in td-meta.
- Repo-specific policy stays in that repo.
- API contracts stay in the owning repo unless no single owner exists.
- Gas City runtime state, `.gc/worktrees`, and bead `metadata.work_dir` recovery
  paths are owned by Gas City, not td-meta.

## Rollout Checklist

When adding a new shared td-meta asset:

1. Classify it as link, call, vendor, or generate.
2. Document the consumption pattern in the same commit.
3. Update `README.md` or `AGENTS.md` if agents need to discover it.
4. Roll it out to one consuming repo first.
5. Only then fan out to the remaining repos.
