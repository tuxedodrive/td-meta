# Cross-Repository Architectural Decision Records

This directory contains ADRs that affect multiple TuxedoDrive repositories.

## When to Create a Cross-Repo ADR

Create an ADR here when the decision:

1. Affects architectural patterns used across multiple td-* repositories
2. Establishes organization-wide infrastructure or tooling standards
3. Defines inter-repository communication protocols
4. Sets policies that all repositories must follow

## When NOT to Create a Cross-Repo ADR

Keep the ADR in the specific repository when the decision:

1. Only affects that repository's internal architecture
2. Relates to repo-specific implementation details
3. Can be superseded without coordinating with other repos

## Format

Cross-repo ADRs follow the same format as repository-specific ADRs:

```markdown
---
layout: post
title: 'ADR-XXX: Decision Title'
date: 'YYYY-MM-DD'
category: adrs
tags: relevant, tags
adr_number: XXX
status: accepted|superseded|deprecated
---

**Date:** YYYY-MM-DD
**Status:** Accepted
**Deciders:** [list]

## Context
[What's the issue we're facing?]

## Decision
[What did we decide?]

## Rationale
[Why did we make this decision?]

## Consequences
[What are the positive/negative outcomes?]

## References
[Links to related docs, code, or discussions]
```

## Numbering

Cross-repo ADRs use their own numbering sequence starting from 001. This distinguishes them from repo-specific ADRs and makes it clear when reading any ADR whether it's cross-repo or repo-specific.

Format: `001-decision-title.md`, `002-next-decision.md`, etc.

## Immutability

Like all ADRs, these are immutable historical records. To change course:

1. Create a new ADR that supersedes the old one
2. Update the old ADR's status to "superseded"
3. Reference the superseding ADR

Never edit the decision content of an existing ADR.

## Examples

Examples of appropriate cross-repo ADRs:

- Shared CI/CD pipeline patterns
- Organization-wide testing strategies
- Inter-repository API versioning approach
- Shared authentication/authorization mechanisms
- Common logging and monitoring standards
- Organization-wide dependency policies

## Related Documentation

- Individual repository ADRs: `td-core/docs/adr/`, `td-edge/docs/adr/`, etc.
- TuxedoDrive coding standards: See individual repository AGENTS.md files
