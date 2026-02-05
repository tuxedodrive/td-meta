# Reusable GitHub Actions Workflows

This directory contains reusable workflow definitions that can be called from other TuxedoDrive repositories.

## Purpose

Centralizing common CI/CD patterns here ensures:

1. Consistency across repositories
2. Single source of truth for shared processes
3. Easier maintenance and updates
4. DRY infrastructure

## How to Use Reusable Workflows

In your repository's workflow file (e.g., `.github/workflows/ci.yml`):

```yaml
name: CI

on: [push, pull_request]

jobs:
  use-shared-workflow:
    uses: tuxedodrive/td-meta/.github/workflows/reusable-workflow.yml@main
    with:
      # Input parameters
      parameter-name: value
    secrets:
      # Secrets if needed
      secret-name: ${{ secrets.SECRET_NAME }}
```

## Versioning Strategy

### Using `@main`

```yaml
uses: tuxedodrive/td-meta/.github/workflows/workflow.yml@main
```

**Pros:** Always get latest updates automatically
**Cons:** Breaking changes could affect your CI without warning

**Use when:** Workflow is stable and you want automatic updates

### Using `@v1` (tags)

```yaml
uses: tuxedodrive/td-meta/.github/workflows/workflow.yml@v1
```

**Pros:** Pinned version, predictable behavior
**Cons:** Manual update required to get improvements

**Use when:** You need stability and want to opt-in to updates

### Using `@commit-sha`

```yaml
uses: tuxedodrive/td-meta/.github/workflows/workflow.yml@abc123...
```

**Pros:** Maximum stability, exact version control
**Cons:** No automatic improvements

**Use when:** Production-critical workflows

## Current Workflows

(To be added as workflows are created)

## Creating New Reusable Workflows

When creating a reusable workflow:

1. Use clear, semantic naming
2. Document all inputs and outputs
3. Provide sensible defaults where possible
4. Consider backward compatibility
5. Test in a single repository before rolling out organization-wide

Example structure:

```yaml
name: Reusable Workflow Name

on:
  workflow_call:
    inputs:
      input-name:
        description: 'Description of what this input does'
        required: true
        type: string
        default: 'default-value'
    outputs:
      output-name:
        description: 'Description of what this output contains'
        value: ${{ jobs.job-name.outputs.output-name }}
    secrets:
      secret-name:
        description: 'Description of what this secret is for'
        required: true

jobs:
  job-name:
    runs-on: ubuntu-latest
    outputs:
      output-name: ${{ steps.step-id.outputs.output-name }}
    steps:
      - name: Do something
        id: step-id
        run: echo "Hello from reusable workflow"
```

## Coordination

Changes to reusable workflows can affect multiple repositories. Before making breaking changes:

1. Check which repositories use the workflow
2. Coordinate updates with affected teams
3. Consider using versioning to avoid breaking changes
4. Document migration path if breaking changes are necessary

## References

- [GitHub Reusable Workflows Documentation](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
- TuxedoDrive workflow examples: See individual repository `.github/workflows/` directories
