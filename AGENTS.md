ABOUTME: Guidelines for AI agents working on td-meta repository infrastructure.
ABOUTME: This file establishes practices for maintaining cross-repository infrastructure.

# TD-Meta Agent Guidelines

This repository contains cross-repository infrastructure for TuxedoDrive. Changes here can affect multiple repositories, so extra care is required.

## Core Principles

1. **Coordination Required**: Changes to reusable workflows or cross-repo ADRs may impact multiple repositories. Always consider the blast radius.

2. **Clear Ownership**: Document which repository owns what. Per ADR-028, contracts typically live in the owning repository, not here.

3. **Backward Compatibility**: Breaking changes to reusable workflows require coordination across all consuming repositories.

4. **Immutable ADRs**: Cross-repo ADRs follow the same immutability rules as repo-specific ADRs.

## Working with Cross-Repo ADRs

When creating cross-repo ADRs:

- Use sequential numbering: 001, 002, etc.
- Ensure the decision genuinely affects multiple repositories
- Consider whether a repo-specific ADR would be more appropriate
- Coordinate with affected teams before marking as "Accepted"

## Working with Reusable Workflows

When creating or modifying reusable workflows:

- Document all inputs, outputs, and secrets clearly
- Provide sensible defaults where possible
- Consider versioning strategy (tags vs. main branch)
- Test in one repository before rolling out organization-wide
- Document breaking changes prominently

## Testing Changes

Before pushing changes:

1. Identify which repositories use the infrastructure you're modifying
2. Test changes in at least one consuming repository
3. Coordinate rollout plan if breaking changes are necessary

## Version Control

- Commit frequently with clear commit messages
- Use semantic commit messages: `feat:`, `fix:`, `docs:`, `refactor:`
- Tag stable workflow versions for consumers who want pinned versions

## Related Repositories

- [td-core](https://github.com/tuxedodrive/td-core) - Core Rails application
- [td-edge](https://github.com/tuxedodrive/td-edge) - Edge detection system
- [td-fleet](https://github.com/tuxedodrive/td-fleet) - Fleet management
- [td-agent](https://github.com/tuxedodrive/td-agent) - AI Phone Customer Service Agent
- [td-training](https://github.com/tuxedodrive/td-training) - Training materials

Consult each repository's AGENTS.md for repo-specific guidelines.
