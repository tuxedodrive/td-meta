# ADR-001: Consolidate Backlog Automation Using Reusable Workflows

**Date**: 2026-02-05
**Status**: Accepted
**Deciders**: JPB, Claude

## Context

All TuxedoDrive repositories (td-core, td-edge, td-training, td-fleet) use the same GitHub Project board (Project #1) to track work through a Kanban flow:

```
☃️ Icebox → 📋 Backlog → 🤸‍♂️ In Progress → 👀 Waiting/Review → 🥳 Done
```

We built automation to move issues and PRs through these columns based on git/PR lifecycle events:

- **Branch created** → Move linked issues to "In Progress"
- **PR opened** → Move linked issues and the PR itself to "Waiting/Review"
- **PR merged** → Move linked issues and the PR itself to "Done"
- **Issue assigned** → Move issue to "In Progress"

### The Problem

The automation workflow (`.github/workflows/project-automation.yml`) is **duplicated identically** across all 4 repositories:

- td-core: 900+ lines
- td-edge: 900+ lines (exact copy)
- td-training: 900+ lines (exact copy)
- td-fleet: 900+ lines (exact copy)

This creates several problems:

1. **Maintenance burden** - Bug fixes require updating 4 files
   - Example: When we discovered merged PRs weren't moving to "Done", we had to fix it in all 4 repos
   - Example: When we found issues with Dependabot PR handling, we had to update 4 files

2. **Drift risk** - Copies get out of sync
   - td-core might get a fix that td-edge doesn't
   - No way to ensure all repos run identical logic

3. **Testing difficulty** - Changes must be tested in all repos

4. **Wasted effort** - 4x the code reviews, 4x the commits, 4x the CI runs

## Decision

Consolidate the backlog automation into a **single reusable GitHub Actions workflow** in td-meta that all repositories call.

### Architecture

**In td-meta** (1 file, 900+ lines):
```
.github/workflows/backlog-automation.yml  # Reusable workflow
```

**In each td-* repo** (12 lines):
```yaml
name: Backlog Automation

on:
  create:
    branches: ['**']
  push:
    branches-ignore: [main]
  issues:
    types: [assigned]
  pull_request:
    types: [opened, closed]

jobs:
  call-shared-workflow:
    uses: tuxedodrive/td-meta/.github/workflows/backlog-automation.yml@main
    secrets:
      org_project_token: ${{ secrets.ORG_PROJECT_TOKEN }}
```

That's it! 12 lines instead of 900+ duplicated lines per repo.

### How It Works

1. Event triggers (PR opened, branch created, etc.) fire in individual repos
2. Individual repo's tiny caller workflow runs
3. Caller workflow invokes the reusable workflow in td-meta
4. Reusable workflow executes the full automation logic
5. All repos always run the exact same logic

### Workflow Parameterization

The reusable workflow accepts optional inputs for customization:

```yaml
inputs:
  project_number:
    description: 'GitHub Project number'
    required: false
    type: number
    default: 1
  org:
    description: 'GitHub organization'
    required: false
    type: string
    default: 'tuxedodrive'
```

This allows repos to override defaults if needed (e.g., if we create a second project board).

## Alternatives Considered

### 1. Continue Duplicating

**Pros**:
- No changes needed
- Each repo is self-contained

**Cons**:
- 4x maintenance burden
- Drift risk
- Already caused problems (merged PRs stuck in "Waiting")

**Verdict**: ❌ Rejected - maintenance burden is too high

### 2. Git Submodules

Share the `.github/workflows/` directory via git submodules.

**Pros**:
- DRY workflows
- Version control

**Cons**:
- Complex to set up and maintain
- Easy to mess up (detached HEAD, sync issues)
- Requires git expertise
- Still 4 copies, just linked
- Submodules are notoriously difficult to work with

**Verdict**: ❌ Rejected - too complex, high risk of errors

### 3. Git Subtrees

Share workflows via git subtrees (better than submodules).

**Pros**:
- Better than submodules
- No detached HEAD issues

**Cons**:
- Still requires manual sync
- Less common than submodules (fewer people know it)
- Merge conflicts on updates
- More complex than necessary

**Verdict**: ❌ Rejected - still too complex

### 4. Copy-Paste with Good Discipline

Keep duplicating, but establish strict process to keep them in sync.

**Pros**:
- Simple
- No new infrastructure

**Cons**:
- Discipline always fails eventually
- Still 4x the work
- "Good process" doesn't fix the fundamental problem

**Verdict**: ❌ Rejected - wishful thinking

### 5. Reusable Workflows (Chosen)

**Pros**:
- ✅ Native GitHub feature - no complexity
- ✅ Single source of truth - all repos use identical logic
- ✅ Easy to maintain - update once, all repos benefit
- ✅ Version control - can pin to specific versions
- ✅ Type-safe - GitHub validates inputs/secrets
- ✅ Fast - no performance overhead
- ✅ Familiar - standard GitHub Actions patterns

**Cons**:
- Requires org-level access for private repos (we have this)
- Slightly less obvious where logic lives (mitigated by clear naming)

**Verdict**: ✅ **Accepted** - best balance of simplicity and maintainability

## Consequences

### Positive

- **DRY** - One workflow file instead of 4 identical copies
- **Easier maintenance** - Fix bugs once, all repos benefit
- **No drift** - All repos always run identical logic
- **Faster iteration** - Test once, deploy everywhere
- **Better testing** - Can test reusable workflow in isolation

### Negative

- **Indirection** - Logic lives in different repo (mitigated by clear naming and documentation)
- **Breaking changes** - Must be careful not to break all repos at once (mitigated by versioning with @v1.2.3 tags)

### Neutral

- **Versioning strategy** - Can use @main for auto-updates or pin to tags for stability
- **Learning curve** - Team must understand reusable workflows (but they're standard GitHub Actions)

## Implementation Plan

### Phase 1: Create Reusable Workflow ✅
1. Create `.github/workflows/backlog-automation.yml` in td-meta
2. Mark it as reusable with `on: workflow_call`
3. Define inputs and secrets
4. Test it works

### Phase 2: Update td-core (Test Repo)
1. Replace td-core's project-automation.yml with caller workflow
2. Test thoroughly:
   - Create branch → issue moves to "In Progress"
   - Open PR → PR and issues move to "Waiting/Review"
   - Merge PR → PR and issues move to "Done"
3. Monitor for 1-2 days to ensure no regressions

### Phase 3: Roll Out to Other Repos
1. Update td-edge with caller workflow
2. Update td-training with caller workflow
3. Update td-fleet with caller workflow
4. Delete old duplicated workflows

### Phase 4: Documentation
1. Update td-meta README to document the workflow
2. Add comments to caller workflows explaining where logic lives
3. Document versioning strategy

## Versioning Strategy

We'll use **@main** for auto-updates initially:

```yaml
uses: tuxedodrive/td-meta/.github/workflows/backlog-automation.yml@main
```

This means all repos automatically get updates when we push to td-meta's main branch.

**Future**: When the workflow is stable, we can switch to tagged versions for more control:

```yaml
uses: tuxedodrive/td-meta/.github/workflows/backlog-automation.yml@v1.0.0
```

## Rollback Plan

If reusable workflows cause problems, we can quickly rollback:

1. Revert each repo's caller workflow to the old duplicated version
2. Investigate and fix issues in td-meta
3. Re-deploy when ready

The old workflow code is preserved in git history, making rollback trivial.

## Success Criteria

✅ All 4 repos use the same logic
✅ Workflow runs successfully on all repos
✅ PRs move to "Waiting/Review" when opened
✅ PRs move to "Done" when merged
✅ No regressions from previous behavior
✅ Future updates only require changing td-meta

## References

- [GitHub Docs: Reusable Workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
- [td-meta README](https://github.com/tuxedodrive/td-meta)
- [td-core ADR-042: Create td-meta Repository](https://github.com/tuxedodrive/td-core/blob/main/docs/adr/042-create-td-meta-repo.md)
- Original workflow: `td-core/.github/workflows/project-automation.yml` (pre-consolidation)
