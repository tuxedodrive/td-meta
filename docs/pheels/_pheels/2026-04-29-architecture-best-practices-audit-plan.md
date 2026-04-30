---
layout: post
title: "Architecture Best Practices Audit Plan"
date: '2026-04-29'
category: plans
tags: [audit, architecture, dartantic, td-core, td-edge, td-meta, td-status, td-tailor, td-training]
llm-relevance: medium
---

This post anchors the cross-repo architecture audit against the Dartantic Architecture Best Practices rubric.

## Worktree layout

- `td-core/.claude/worktrees/arch-best-practices-code-audit`
- `td-edge/.claude/worktrees/arch-best-practices-code-audit`
- `td-meta/.claude/worktrees/arch-best-practices-code-audit`
- `td-status/.claude/worktrees/arch-best-practices-code-audit`
- `td-tailor/.claude/worktrees/arch-best-practices-code-audit`
- `td-training/.claude/worktrees/arch-best-practices-code-audit`

## Reporting convention

Each repo gets its own PHEELblog audit report in this same collection, tagged with `audit` and the repo name.

## Working checklist

Use this checklist in each repo report. Mark each item as `pass`, `mixed`, `fail`, or `n/a`, and capture concrete evidence with file paths.

### 1. Testing discipline

- Is there clear evidence of TDD or at least strong automated test coverage around the core behavior?
- Are tests organized idiomatically for the stack?
- Are core paths covered by unit and integration or end-to-end tests where appropriate?

### 2. Duplication and reuse

- Is duplicated logic low and intentionally extracted into shared modules?
- Are shared abstractions reused instead of copy-paste forks?
- Are there signs of parallel implementations drifting apart?

### 3. Separation of concerns

- Are UI, domain, infrastructure, persistence, and integration responsibilities separated cleanly?
- Do scripts, services, and framework entry points have bounded scope?
- Are cross-cutting concerns isolated rather than smeared through many files?

### 4. Single responsibility

- Do classes, modules, jobs, scripts, and files have one dominant reason to change?
- Are oversized files or “god objects” concentrated in critical paths?
- Are convenience scripts doing orchestration only, or also embedding business logic?

### 5. Abstractions and contracts

- Are interfaces small, explicit, and stable?
- Are contracts documented or enforced through tests, schemas, or typed boundaries?
- Are implementation details hidden behind clear module boundaries?

### 6. SOLID completeness

- Open/Closed Principle: can behavior be extended without repeatedly editing stable core code paths?
- Liskov Substitution Principle: do alternate implementations preserve the behavioral contract their callers rely on?
- Interface Segregation Principle: are interfaces narrow and client-specific rather than broad and kitchen-sink?
- Dependency Inversion Principle: do high-level policies depend on abstractions rather than concrete infrastructure details?

### 7. Coupling and cohesion

- Do components depend on too many peers or framework details?
- Are domain concepts grouped coherently?
- Are there circular or back-edge dependencies that erode layer boundaries?

### 8. Layering

- Is the repo organized into clear tiers for the language and framework?
- Do higher layers depend only on lower layers?
- Are there direct calls that skip intended boundaries?

### 9. Simplicity and speculative complexity

- Does the code stay KISS, or is there unnecessary indirection?
- Is there evidence of YAGNI violations such as unused scaffolding, placeholder structures, or speculative abstractions?
- Is removed behavior actually removed rather than left commented or half-retained?

### 10. Error handling and correctness

- Are errors surfaced rather than swallowed?
- Are fallback values, timeouts, retries, and rescue blocks explicit and justified?
- Are race conditions, dropped writes, and partial-failure modes addressed in code and tests?

### 11. Observability and testability

- Are logging, metrics, tracing, and health signals built into the critical paths?
- Can components be tested in isolation without invasive setup?
- Are production diagnostics sufficient to root-cause failures?

### 12. Scalability and state management

- Are services stateless where they should be?
- Is state localized, durable, and concurrency-safe where statefulness is required?
- Is the architecture plausible under higher load or more devices, tenants, or jobs?

### 13. Nullability and data shape discipline

- Are non-null defaults preferred where the language and framework support them?
- Are optional values explicit and handled at boundaries?
- Are contracts tightened to avoid “maybe present” data in core logic?

### 14. Async versus polling

- Are async notifications, queues, or event-driven flows used where they reduce polling waste?
- Where polling exists, is it justified by environment constraints?
- Are async boundaries observable and race-safe?

### 15. Maintainability and idiomatic structure

- Is the repo arranged idiomatically for its language and framework?
- Are standard linters, type checks, or static analysis tools present and meaningful?
- Is the codebase readable enough that future changes will stay cheap?

## Output format per repo

- Repo profile
- Summary judgment
- Checklist results
- Key findings
- Recommended remediations
- Open questions

## Next steps

1. Read the rubric and extract the evaluation dimensions into a working checklist.
2. Review each repo in its audit worktree against that checklist.
3. Capture findings in the corresponding repo report.
4. Synthesize cross-repo patterns and remediation themes in a follow-up PHEELblog post if needed.
