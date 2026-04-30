---
layout: post
title: "Architecture Best Practices Audit: td-status"
date: '2026-04-29'
category: explorations
tags: [audit, architecture, dartantic, td-status, solid]
llm-relevance: high
---

Full audit notes for `td-status` against the supplied Architecture Best Practices rubric plus the full SOLID object-oriented principles.

## Scope

- Repo: `td-status`
- Worktree: `td-status/.claude/worktrees/arch-best-practices-code-audit`
- Branch: `arch-best-practices-code-audit`
- Audit date: 2026-04-30
- Report location: `td-meta/docs/pheels/_pheels/2026-04-29-architecture-best-practices-audit-td-status.md`
- Method: static review of Upptime configuration, generated workflows, generated history/API/graph artifacts, repository guidance, and status-page documentation.
- Runtime note: this audit did not run Upptime or call monitored services. No `td-status` source files were changed.

The user rubric lists SRP separately and also asks for SOLID. I score SRP under SOLID-S to avoid double-counting, while still covering the other 19 supplied architecture practices.

## Executive Summary

`td-status` is intentionally not an application repo. It is an Upptime status-page repo with a single configuration source, generated GitHub Actions workflows, and generated history/API/graph artifacts. For its scope, that is a reasonable architecture.

The main findings are contract drift and false-green risk. README/AGENTS still claim 18 services and 5-minute checks, while `.upptimerc.yml` monitors 10 services and the generated `upptime-checks.yml` runs every 15 minutes. Several external checks intentionally accept auth failures as success, which monitors provider reachability but not whether TuxedoDrive credentials or integrations work. The repo also relies on generated artifacts that must be manually cleaned up when services are removed.

This repo should not be over-engineered. The fix is to make the status contract honest: align docs, generated workflows, and service semantics; add a lightweight validation script or CI check that detects drift.

## Rubric Scorecard

| Practice | Verdict | Audit result |
| --- | --- | --- |
| TDD | Fail | No executable tests, actionlint config, or config-drift checks were found. |
| DRY | Mixed | `.upptimerc.yml` is the intended source of truth, but generated `api/`, `history/`, `graphs/`, and workflows require manual synchronization for removals. |
| Separation of Concerns | Mixed | Config, generated artifacts, docs, and workflows are recognizable; service-count/schedule meaning is duplicated and drifting. |
| Clear Abstractions and Contracts | Mixed-to-fail | The status page does not clearly distinguish provider reachability from authenticated integration health. |
| Low Coupling, High Cohesion | Mixed | The repo is cohesive around status monitoring, but Upptime-generated artifacts create coupling to generated file layouts. |
| Scalability and Statelessness | Pass with caveat | Upptime/GitHub Actions is stateless enough for this use case, but threshold and schedule drift affect incident latency. |
| Observability and Testability | Mixed-to-fail | The repo exists for observability, but false-green external checks and no validation harness weaken its reliability. |
| KISS | Pass | Upptime is a simple fit for this scope. |
| YAGNI | Pass | No major speculative app logic was found. |
| Do Not Swallow Errors | Mixed-to-fail | Expected 401/403/422 statuses intentionally convert auth/integration failures into green checks for some services. |
| No Placeholder Code | Pass | No placeholder implementation code was found. |
| No Comments for Removed Functionality | Mixed | Generated "do not edit" comments are appropriate; stale docs about service counts are not. |
| Layered Architecture | Not applicable | There is no runtime app layering beyond Upptime config and generated workflows. |
| Prefer Non-Nullable Variables | Not applicable | There is no typed application data model. |
| Prefer Async Notifications | Pass | GitHub issue and email notifications are configured. |
| Consider First Principles | Mixed | A status repo is the right abstraction, but the monitored checks should be defined from the operator question: "is this dependency usable?" |
| Eliminate Race Conditions | Mixed | Auto-committed generated artifacts can conflict with manual changes; Upptime handles most runtime sequencing. |
| Maintainability | Mixed | Small config is maintainable; generated artifacts and manual cleanup steps make service lifecycle changes error-prone. |
| Arrange Project Idiomatically | Mixed | The repo mostly follows Upptime conventions, but generated schedule drift and missing validation should be addressed. |

## SOLID Scorecard

| Principle | Verdict | Audit result |
| --- | --- | --- |
| Single Responsibility | Mixed | The repo has one clear reason to change, but its docs/config/workflows define conflicting monitoring contracts. |
| Open/Closed | Mixed | Adding services is straightforward through `.upptimerc.yml`, but removing services requires manual cleanup across generated directories. |
| Liskov Substitution | Not applicable | No OO substitution surface. |
| Interface Segregation | Mixed | Internal health checks and external provider reachability checks are presented through the same status interface despite different semantics. |
| Dependency Inversion | Mixed | The repo depends on Upptime-generated workflow internals; validation should depend on `.upptimerc.yml` as the source contract. |

## Major Findings

### 1. Service-count documentation has drifted from configuration

README and AGENTS say the page monitors 18 external or critical services. Evidence: [README.md](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/README.md:9), [README.md](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/README.md:18), and [AGENTS.md](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/AGENTS.md:7).

`.upptimerc.yml` says there are 10 services and defines 10 `sites` entries. Evidence: [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:6), [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:41), and [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:162).

Impact: operators and users cannot tell whether eight services were intentionally removed, not yet added, or accidentally dropped. This is a clear contract/maintainability failure.

Recommended direction: update README/AGENTS to derive the count from `.upptimerc.yml`, or add a validation check that fails when documented counts do not match configured services.

### 2. Monitoring cadence has drifted between config, docs, and generated workflow

README and AGENTS say checks run every 5 minutes. Evidence: [README.md](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/README.md:30) and [AGENTS.md](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/AGENTS.md:7).

`.upptimerc.yml` also says checks should run every 5 minutes. Evidence: [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:200) and [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:204).

The generated `upptime-checks.yml` schedule runs every 15 minutes. Evidence: [upptime-checks.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/upptime-checks.yml:3) and [upptime-checks.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/upptime-checks.yml:4).

Impact: with threshold 5, a real outage could take materially longer to mark down than operators expect. At 5-minute checks the threshold window is about 25 minutes; at 15-minute checks it is about 75 minutes. Evidence for threshold: [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:221) and [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:222).

Recommended direction: regenerate workflows from `.upptimerc.yml` or update the config/docs if 15 minutes is intentional. Add a drift check comparing `.upptimerc.yml` schedule to generated workflow cron.

### 3. Several external checks can be green while the real integration is broken

Payments accepts Stripe 400/401 as success. Evidence: [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:72), [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:74), and [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:76).

Email, SMS, weather, pollen, and secrets checks similarly accept unauthenticated or forbidden responses for some providers. Evidence: [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:85), [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:87), [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:98), [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:119), [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:126), and [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:145).

Impact: this monitors vendor reachability, not whether TuxedoDrive can authenticate or perform business-critical operations. It can produce false green status during credential expiration, account lockout, permission changes, or API contract drift.

Recommended direction: label these checks as "provider reachability" or add separate authenticated synthetic checks for "integration usable". Do not present unauthenticated 401/403 responses as business integration health.

### 4. Generated artifacts are a DRY and maintainability trap

The repo guidance says removing a service requires editing `.upptimerc.yml` and manually deleting matching `history/`, `api/`, and `graphs/` artifacts. Evidence: [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:31), [AGENTS.md](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/AGENTS.md:21), [AGENTS.md](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/AGENTS.md:22), [AGENTS.md](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/AGENTS.md:23), and [AGENTS.md](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/AGENTS.md:24).

Impact: a source-of-truth config exists, but the repository can still show stale incidents, stale graphs, or stale API JSON if cleanup is incomplete.

Recommended direction: add a validation script that derives expected service slugs from `.upptimerc.yml` and checks that generated directories match. This can run in CI without changing the Upptime architecture.

### 5. Broad workflow permissions and full secrets context are worth isolating

The generated check workflow requests write permissions for checks, contents, deployments, issues, and statuses, and passes the full GitHub secrets context into the Upptime action. Evidence: [upptime-checks.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/upptime-checks.yml:9), [upptime-checks.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/upptime-checks.yml:27), and [upptime-checks.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/upptime-checks.yml:31).

Other generated Upptime workflows also pass `SECRETS_CONTEXT`. Evidence: [uptime.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/uptime.yml:35), [uptime.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/uptime.yml:38), and [setup.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.github/workflows/setup.yml:47).

Impact: this may be normal for Upptime, but it increases blast radius. Any custom edits or third-party-action compromise would have broad write and secrets context.

Recommended direction: keep generated workflow compatibility, but document why broad permissions are required and avoid adding custom code to these jobs. If custom checks are needed, run them in separate jobs with minimal permissions and scoped secrets.

## Positive Controls To Preserve

- Keep Upptime for this repo. It is a simple and idiomatic fit for uptime/status history.
- Keep `.upptimerc.yml` as the human-editable source of truth.
- Keep GitHub issue and email notifications. Evidence: [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:189), [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:191), [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:196), and [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:197).
- Keep internal health endpoint keyword checks, but make sure they are tied to real readiness semantics. Evidence: [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:47), [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:54), and [.upptimerc.yml](/Users/jpb/workspace/tuxedodrive/td-status/.claude/worktrees/arch-best-practices-code-audit/.upptimerc.yml:58).

## Remediation Priority

1. Align service counts in README, AGENTS, and `.upptimerc.yml`.
2. Align the check schedule in `.upptimerc.yml` and generated `upptime-checks.yml`.
3. Split "provider reachable" from "TuxedoDrive integration usable" in service names and checks.
4. Add a small drift check for configured services versus generated history/API/graph directories.
5. Document the permission/secrets model for generated workflows and keep custom code out of broad-permission jobs.
