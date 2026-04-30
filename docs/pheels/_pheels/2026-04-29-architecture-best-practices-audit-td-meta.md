---
layout: post
title: "Architecture Best Practices Audit: td-meta"
date: '2026-04-29'
category: explorations
tags: [audit, architecture, dartantic, td-meta, solid]
llm-relevance: high
---

Full audit notes for `td-meta` against the supplied Architecture Best Practices rubric plus the full SOLID object-oriented principles.

## Scope

- Repo: `td-meta`
- Worktree: `td-meta/.claude/worktrees/arch-best-practices-code-audit`
- Branch: `arch-best-practices-code-audit`
- Audit date: 2026-04-30
- Report location: `td-meta/docs/pheels/_pheels/2026-04-29-architecture-best-practices-audit-td-meta.md`
- Method: static review of repository purpose, reusable workflow implementation, ADRs, contracts directory, repo guidance, and generated PHEELblog audit placement.
- Runtime note: this audit did not execute GitHub Actions or external GitHub API calls. No `td-meta` source files were changed except this report.

The user rubric lists SRP separately and also asks for SOLID. I score SRP under SOLID-S to avoid double-counting, while still covering the other 19 supplied architecture practices.

## Executive Summary

`td-meta` has the right architectural purpose: centralize cross-repo coordination artifacts instead of duplicating workflows and ADR patterns. That is a strong DRY and separation-of-concerns move for the TuxedoDrive repo family.

The main architecture risk is that the repo currently centralizes cross-repo behavior without enough verification, versioning, or contract enforcement. A 418-line reusable workflow contains embedded JavaScript, GraphQL, status IDs, branch/PR issue discovery, and project mutation behavior, but there is no local test harness, no actionlint configuration, no dry-run mode, and no pinned version strategy in the consumer examples. The ADR promises branch-created automation that the reusable workflow does not implement as a first-class job.

This repo should remain small. The fix is not more framework. The fix is executable validation around the one high-blast-radius workflow and clearer ownership of what belongs here versus in owning repos.

## Rubric Scorecard

| Practice | Verdict | Audit result |
| --- | --- | --- |
| TDD | Fail | No executable workflow tests, actionlint config, fixture tests, or dry-run harness were found. |
| DRY | Pass with caveat | Centralizing shared backlog automation is a correct DRY move, but all consumers currently inherit the same untested workflow blast radius. |
| Separation of Concerns | Mixed | ADRs, contracts, templates, and reusable workflows are separated conceptually; the backlog workflow itself mixes lookup, policy, discovery, and mutation. |
| Clear Abstractions and Contracts | Mixed-to-fail | Inputs/secrets are explicit, but status option IDs, event semantics, and branch-created behavior are not stable contracts. |
| Low Coupling, High Cohesion | Mixed | The repo is cohesive around cross-repo coordination; consumers coupled to `@main` are tightly coupled to every workflow change. |
| Scalability and Statelessness | Mixed | Reusable workflows scale better than copied YAML, but project queries are partially paginated and use small fixed limits. |
| Observability and Testability | Fail | Workflow behavior depends on GitHub-side execution logs; there is no local or fixture-based way to validate mutations before rollout. |
| KISS | Mixed | The repository structure is simple, but the central workflow's embedded JavaScript and GraphQL are complex for the risk level. |
| YAGNI | Mixed | The repo mostly avoids speculative artifacts, but the `contracts/` directory is only a README today despite being advertised as a shared contract area. |
| Do Not Swallow Errors | Mixed | GitHub Script steps generally throw on GraphQL failures, but lookup/mutation decisions are log-driven rather than asserted in tests. |
| No Placeholder Code | Pass | No placeholder implementation code was found in the active repo, though `contracts/` is currently only a placeholder area. |
| No Comments for Removed Functionality | Pass | ADR history belongs here; no major source-level dead-code comments were found. |
| Layered Architecture | Mixed | Repository-level layers are clear; workflow internals are not layered into reusable/testable units. |
| Prefer Non-Nullable Variables | Mixed | Workflow inputs and secrets are declared, but project status option IDs are hardcoded globals rather than resolved contracts. |
| Prefer Async Notifications | Not applicable | This repo does not implement runtime services. GitHub event-driven workflows are appropriate for its scope. |
| Consider First Principles | Mixed | The purpose doc does this well, but from scratch the central automation would likely ship with tests and versioned release channels. |
| Eliminate Race Conditions | Mixed-to-fail | Project item mutation can race with concurrent issue/PR events, and there is no idempotency or test coverage for duplicate event orderings. |
| Maintainability | Mixed | Small repo size is good; a single large workflow with embedded scripts is hard to maintain safely. |
| Arrange Project Idiomatically | Mixed | Layout is idiomatic for a meta/workflow repo, but missing actionlint/tests/versioning weakens GitHub Actions idiom. |

## SOLID Scorecard

| Principle | Verdict | Audit result |
| --- | --- | --- |
| Single Responsibility | Mixed-to-fail | The repo has one clear reason to exist, but the backlog workflow has several responsibilities in one file and several GitHub Script blocks. |
| Open/Closed | Mixed-to-fail | Adding new project states or lifecycle transitions requires editing hardcoded workflow logic and status IDs. |
| Liskov Substitution | Not applicable | There is little OO substitution surface. The closest analog is workflow-call compatibility, which is not strongly versioned. |
| Interface Segregation | Mixed | Workflow inputs are small, but consumers cannot opt into only some lifecycle transitions. |
| Dependency Inversion | Mixed-to-fail | Consumers depend directly on the concrete `@main` workflow and concrete GitHub Project option IDs. |

## Major Findings

### 1. The high-blast-radius workflow has no executable test harness

`td-meta` exists to reduce duplication across repositories. The repo guidance correctly warns that reusable workflow changes can affect multiple repositories and should be tested in a consuming repository. Evidence: [AGENTS.md](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/AGENTS.md:10), [AGENTS.md](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/AGENTS.md:33), and [AGENTS.md](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/AGENTS.md:42).

The actual repo has no test files, package metadata, Makefile, actionlint config, or local workflow fixture harness. The reusable workflow itself is 418 lines of YAML plus embedded JavaScript/GraphQL. Evidence: [backlog-automation.yml](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/backlog-automation.yml:1), [backlog-automation.yml](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/backlog-automation.yml:43), [backlog-automation.yml](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/backlog-automation.yml:80), [backlog-automation.yml](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/backlog-automation.yml:177), and [backlog-automation.yml](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/backlog-automation.yml:333).

Impact: a single edit can break issue/PR automation in every consuming repo, and there is no cheap way to catch syntax, event-shape, GraphQL, or policy regressions before rollout.

Recommended direction: add an executable validation target that runs `actionlint` plus fixture tests for the embedded scripts. If extracting JS is too much, start with a dry-run workflow mode and checked-in event payload fixtures.

### 2. ADR behavior and implementation have drifted

ADR-001 says branch creation should move linked issues to In Progress. Evidence: [ADR-001](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/docs/adr/001-consolidate-backlog-automation.md:17), [ADR-001](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/docs/adr/001-consolidate-backlog-automation.md:60), and [ADR-001](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/docs/adr/001-consolidate-backlog-automation.md:218).

The current workflow has jobs for assigned issues, PR-linked issues, and PR items, but no first-class branch-created job. It only checks linked branches as a fallback while handling PR events. Evidence: [backlog-automation.yml](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/backlog-automation.yml:75), [backlog-automation.yml](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/backlog-automation.yml:164), [backlog-automation.yml](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/backlog-automation.yml:216), and [backlog-automation.yml](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/backlog-automation.yml:319).

Impact: docs describe a lifecycle contract that consumers may depend on, but the implementation no longer satisfies it. This is a clear abstraction/contract failure.

Recommended direction: either implement branch-created behavior in the reusable workflow or update the ADR/status docs to say the current supported triggers are assignment and PR lifecycle only.

### 3. Consumers are encouraged to depend on `@main`

The README and ADR examples tell consumers to use the reusable workflow from `@main`. Evidence: [README.md](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/README.md:56), [ADR-001](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/docs/adr/001-consolidate-backlog-automation.md:72), and [ADR-001](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/docs/adr/001-consolidate-backlog-automation.md:236).

The repo guidance says to consider versioning strategy and tag stable workflow versions. Evidence: [AGENTS.md](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/AGENTS.md:33) and [AGENTS.md](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/AGENTS.md:49).

Impact: `@main` is convenient, but it gives every workflow edit immediate organization-wide blast radius. This is a dependency-inversion and open/closed problem for consumers.

Recommended direction: publish tagged channels such as `backlog-automation/v1` or repo tags like `workflow-backlog-v1.0.0`; use `@main` only for canaries or explicit early adopters.

### 4. Project status option IDs are hardcoded global configuration

The workflow hardcodes status option IDs in top-level environment variables. Evidence: [backlog-automation.yml](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/backlog-automation.yml:28), [backlog-automation.yml](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/backlog-automation.yml:29), and [backlog-automation.yml](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/backlog-automation.yml:30).

The workflow resolves the project and status field, but not the status options by display name. Evidence: [backlog-automation.yml](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/backlog-automation.yml:35), [backlog-automation.yml](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/backlog-automation.yml:155), and [backlog-automation.yml](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/backlog-automation.yml:157).

Impact: recreating or changing GitHub Project statuses can silently break automation or move items to the wrong option if IDs drift.

Recommended direction: resolve status option IDs by configured names at runtime, or require option IDs as explicit workflow inputs per consumer project.

### 5. GraphQL queries use fixed small limits without pagination

The workflow uses `projectItems(first: 10)` and `issues(first: 100)` without pagination in key lookup paths. Evidence: [backlog-automation.yml](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/backlog-automation.yml:93), [backlog-automation.yml](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/backlog-automation.yml:221), [backlog-automation.yml](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/backlog-automation.yml:259), and [backlog-automation.yml](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/backlog-automation.yml:363).

Impact: this can miss project items, linked issues, or branches once repositories grow. The automation then looks healthy but silently fails to move all intended items.

Recommended direction: add pagination helpers and tests for repos with more than 10 project items and more than 100 open issues.

### 6. `contracts/` is documented as a central area, but ownership doctrine says most contracts belong elsewhere

The README advertises centralized shared contracts. Evidence: [README.md](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/README.md:39) and [README.md](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/README.md:86).

The repo guidance says contracts typically live in the owning repository, not here. Evidence: [AGENTS.md](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/AGENTS.md:12) and [README.md](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/README.md:101).

Impact: this is not currently a bug because the directory is mostly empty, but the documentation leaves an ambiguity that can cause future contract ownership drift.

Recommended direction: make `contracts/README.md` the explicit policy: default contracts live with the owning repo; `td-meta/contracts` is only for cross-owner contracts with a named owner and versioning plan.

## Positive Controls To Preserve

- Keep `td-meta` as the cross-repo coordination repo. Its purpose is clear and valuable. Evidence: [README.md](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/README.md:4).
- Keep ADRs here. ADR history is appropriate in a meta repo and does not violate "no comments for removed functionality."
- Keep reusable workflows, but give them versioned release channels and executable validation.
- Keep the guidance about blast radius, backward compatibility, and cross-repo ownership. Evidence: [AGENTS.md](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/AGENTS.md:10), [AGENTS.md](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/AGENTS.md:14), and [AGENTS.md](/Users/jpb/workspace/tuxedodrive/td-meta/.claude/worktrees/arch-best-practices-code-audit/AGENTS.md:27).

## Remediation Priority

1. Add `actionlint` and a minimal local validation target for `.github/workflows/backlog-automation.yml`.
2. Decide whether branch-created automation is supported; align ADR and implementation.
3. Stop recommending `@main` as the default consumer pin once stable tags exist.
4. Resolve or parameterize status option IDs instead of hardcoding them.
5. Add pagination for project-item and issue GraphQL queries.
6. Clarify shared contract ownership policy in `contracts/README.md`.
