# ADR-000: Why td-meta Exists

**Date**: 2026-02-05
**Status**: Accepted
**Deciders**: JPB, Claude

## Context

This is a meta-ADR explaining the purpose and scope of the td-meta repository.

## Decision

The `tuxedodrive/td-meta` repository exists to house cross-repository infrastructure and decisions that affect multiple TuxedoDrive repositories (td-core, td-edge, td-training, td-fleet, etc.).

## Rationale

For the full context, problem statement, alternatives considered, and decision rationale, see:

**[td-core ADR-042: Create td-meta Repository for Cross-Repo Infrastructure](https://github.com/tuxedodrive/td-core/blob/main/docs/adr/042-create-td-meta-repo.md)**

This ADR exists to close the loop - td-meta's first ADR links back to the td-core ADR that created it.

## What Lives Here

1. **Reusable GitHub Actions workflows** - Shared workflows that other repos call
2. **Cross-repo ADRs** - Decisions affecting multiple repositories (like this one)
3. **Documentation templates** - ADR templates, PHEEL templates, etc.
4. **Shared contracts** - Only when no single repo owns them (rare)

## What Doesn't Live Here

1. **Application code** - td-meta has no application code
2. **Repo-specific decisions** - Those stay in individual repo ADRs
3. **API contracts** - Stay in owning repos (per td-core ADR-028)

## How to Use td-meta

### When to Create an ADR Here

Ask: "Does this decision affect 2+ repositories?"

- **Yes** → Create ADR in td-meta
- **No** → Create ADR in the affected repo

**Examples:**
- ✅ Standardizing Git commit message format across all repos → td-meta ADR
- ✅ Shared GitHub Actions workflow → td-meta ADR
- ❌ td-core database schema change → td-core ADR
- ❌ td-edge video compression strategy → td-edge ADR

### When to Create a Reusable Workflow Here

Ask: "Is this workflow duplicated or could be shared across repos?"

- **Yes** → Create reusable workflow in td-meta
- **No** → Keep it in the individual repo

**Examples:**
- ✅ Project board automation (used by all repos) → td-meta workflow
- ✅ Common CI checks (linting, security scans) → td-meta workflow
- ❌ td-core deployment to production → td-core workflow
- ❌ td-edge model training pipeline → td-edge workflow

## ADR Numbering

- **td-meta ADRs**: 000, 001, 002, 003, etc.
- **Individual repo ADRs**: Continue their own sequences (td-core is on 042, etc.)

This makes it immediately clear whether an ADR is cross-repo or repo-specific.

## Next Steps

See [td-meta ADR-001: Consolidate Backlog Automation using Reusable Workflows](./001-consolidate-backlog-automation.md) for the first real cross-repo decision.

## References

- [td-core ADR-042: Create td-meta Repository for Cross-Repo Infrastructure](https://github.com/tuxedodrive/td-core/blob/main/docs/adr/042-create-td-meta-repo.md) (the ADR that created td-meta)
- td-meta README: https://github.com/tuxedodrive/td-meta
