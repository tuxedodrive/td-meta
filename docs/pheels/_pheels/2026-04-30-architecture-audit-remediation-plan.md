---
layout: post
title: "Architecture Audit Remediation Plan"
date: '2026-04-30'
category: plans
tags: [audit, architecture, remediation, td-core, td-edge, td-meta, td-status, td-tailor, td-training]
llm-relevance: high
---

This is the executable planning document for the cross-repo architecture audit. Use it to track remediation progress after the audit reports.

## Progress Snapshot

- Audit reporting: 7/7 complete
- P0 remediation stories: 0/5 complete
- P1 remediation stories: 0/7 complete
- P2 remediation stories: 0/6 complete
- Current phase: audit complete, remediation not started

## Completed Audit Milestones

- [x] Create audit worktrees for `td-core`, `td-edge`, `td-meta`, `td-status`, `td-tailor`, and `td-training`.
- [x] Write the cross-repo audit plan PHEEL.
- [x] Write full `td-core` audit against the architecture rubric plus SOLID.
- [x] Write full `td-edge` audit against the architecture rubric plus SOLID.
- [x] Write full `td-meta` audit against the architecture rubric plus SOLID.
- [x] Write full `td-status` audit against the architecture rubric plus SOLID.
- [x] Write full `td-tailor` audit against the architecture rubric plus SOLID.
- [x] Write full `td-training` audit against the architecture rubric plus SOLID.
- [x] Commit and push the audit reports to `td-meta` `main`.

## Tracking Rules

- Mark a story complete only when its acceptance criteria are complete and committed.
- Prefer one PR or commit series per story unless the story explicitly spans repositories.
- For security-sensitive stories, rotate credentials before relying on code cleanup.
- Keep remediation notes in PHEELblog or bead issue comments, not in source comments.

## P0 Stories

### AAR-001: Rotate and Remove `td-tailor` Plaintext Secrets

Repo: `td-tailor`

Status: Not started

User story: As an operator, I want all committed plaintext fleet secrets removed and rotated so leaked credentials cannot be reused.

Acceptance criteria:

- [ ] Rotate every credential exposed in committed `configs/.env.*` files.
- [ ] Remove plaintext secret files from the current tree.
- [ ] Add ignore rules for `.env.*` while preserving `.env.example`.
- [ ] Convert per-site secrets to SOPS-encrypted `secrets.env.enc` files.
- [ ] Add a secret-scan gate that fails on plaintext API keys, RTSP credentials, R2 keys, and Pi secrets.
- [ ] Add a PHEEL note or runbook entry documenting what was rotated and when, without including secret values.

### AAR-002: Replace Shared Pi Defaults in `td-tailor`

Repo: `td-tailor`

Status: Not started

User story: As an operator, I want each edge device to use unique credentials so compromise of one Pi does not compromise the fleet.

Acceptance criteria:

- [ ] Remove hardcoded shared Pi password defaults from active scripts.
- [ ] Generate or require per-device credentials during imaging.
- [ ] Store deploy credentials in SOPS, not shell defaults.
- [ ] Make deployment fail unless credentials are explicit or a declared lab mode is enabled.
- [ ] Update README/CLAUDE guidance to remove reusable default credentials.

### AAR-003: Harden `td-core` Tenant Isolation

Repo: `td-core`

Status: Not started

User story: As a tenant, I want all reads and writes scoped to my tenant so data cannot cross tenant boundaries.

Acceptance criteria:

- [ ] Add regression tests with duplicate identifiers across tenants.
- [ ] Fix unscoped import, webhook, dashboard, and edge-resolution paths identified in the audit.
- [ ] Add or tighten database uniqueness constraints where global identifiers are assumed.
- [ ] Add a review or static-analysis guard for unscoped tenant-sensitive queries.
- [ ] Document the tenant-scoping contract in the existing architecture guidance.

### AAR-004: Replace Trust-Based Physical Control APIs

Repos: `td-core`, `td-edge`

Status: Not started

User story: As an operator, I want physical-control commands to be authenticated, device-scoped, and replay-safe so tenant/site query parameters are not the security boundary.

Acceptance criteria:

- [ ] Define a signed, device-scoped v2 command contract for moxa and wash-sequence control.
- [ ] Add replay protection or command leasing with idempotency keys.
- [ ] Require device authentication for physical-control command fetch, ack, fail, and status updates.
- [ ] Update `td-edge` clients to use the new contract.
- [ ] Deprecate or block trust-based v1 physical-control endpoints after migration.
- [ ] Add contract tests on both sides.

### AAR-005: Stop False Success in `td-edge` Sync and Error Paths

Repo: `td-edge`

Status: Not started

User story: As an operator, I want failed sync, camera, config, and command paths to surface explicit degraded state so the system does not appear healthy when work failed.

Acceptance criteria:

- [ ] Stop marking unimplemented R2 uploads as synced.
- [ ] Replace `return []` on td-core command/sequence API failures with typed degraded-state results or raised domain errors.
- [ ] Replace camera/config fallback paths that hide failures with explicit error states.
- [ ] Add tests proving API failure is distinguishable from "no work".
- [ ] Add metrics or logs for degraded states that can be observed in production.

## P1 Stories

### AAR-006: Split `td-edge` Hotspots

Repo: `td-edge`

Status: Not started

User story: As a developer, I want oversized edge modules split by responsibility so dashboard, stream, camera, zone, detection, and tracking changes can be made safely.

Acceptance criteria:

- [ ] Split `api/routers/td_core.py` into focused routers or presenters.
- [ ] Split `cli.py` into command modules with thin Click entrypoints.
- [ ] Extract `ObjectTracker` responsibilities behind explicit services.
- [ ] Preserve existing contract and race-condition tests during the split.
- [ ] Add import-linter or package-boundary rules for the extracted modules.

### AAR-007: Fix `td-edge` Python Package Idioms

Repo: `td-edge`

Status: Not started

User story: As a developer, I want the Python package imported as `td_edge` so packaging, import-linter, and runtime imports match standard Python practice.

Acceptance criteria:

- [ ] Change package declaration from `src` package root to `td_edge`.
- [ ] Rewrite `src.td_edge.*` imports to `td_edge.*`.
- [ ] Retarget import-linter contracts to `td_edge`.
- [ ] Run tests and import-linter after migration.

### AAR-008: Align `td-status` Monitoring Contracts

Repo: `td-status`

Status: Not started

User story: As an operator, I want the status page to report what it actually monitors so service counts, check frequency, and health semantics are trustworthy.

Acceptance criteria:

- [ ] Align README, AGENTS, and `.upptimerc.yml` service counts.
- [ ] Align `.upptimerc.yml` check schedule with generated workflow cron.
- [ ] Label unauthenticated provider checks as provider reachability, not integration health.
- [ ] Add or plan authenticated synthetic checks for critical integrations.
- [ ] Add a drift check for configured services versus generated history/API/graph artifacts.

### AAR-009: Add `td-meta` Workflow Validation

Repo: `td-meta`

Status: Not started

User story: As a maintainer, I want reusable workflow changes validated before rollout so cross-repo automation does not break silently.

Acceptance criteria:

- [ ] Add `actionlint` or equivalent workflow validation.
- [ ] Add fixture or dry-run tests for backlog automation event payloads.
- [ ] Resolve or parameterize GitHub Project status option IDs.
- [ ] Add pagination for project-item and issue GraphQL queries.
- [ ] Decide whether branch-created automation is supported and align ADR plus implementation.
- [ ] Replace default `@main` consumer guidance with a tagged versioning strategy once stable.

### AAR-010: Make `td-training` Runs Reproducible

Repo: `td-training`

Status: Not started

User story: As an ML maintainer, I want every model artifact traceable to data, code, parameters, and metrics so runtime model behavior is reproducible.

Acceptance criteria:

- [ ] Add dependency management and a minimal lint/test CI target.
- [ ] Move training parameters into versioned experiment config files.
- [ ] Record git SHA, dataset version, weights, seed, params, metrics, and artifact paths in a run manifest.
- [ ] Define the model artifact contract consumed by `td-edge`.
- [ ] Add golden tests for Stanford Cars mapping generation.
- [ ] Harden dataset extraction and record checksums.

### AAR-011: Remove `td-core` Placeholder and Stub Runtime Paths

Repo: `td-core`

Status: Not started

User story: As an operator, I want production-visible stubs, mock analytics, and no-op adapters removed or isolated so production behavior reflects real system state.

Acceptance criteria:

- [ ] Remove or isolate hardware adapter stub behavior from production paths.
- [ ] Remove production-visible analytics/mock fallbacks.
- [ ] Remove or guard debug/legacy routes called out in the audit.
- [ ] Add tests proving production mode fails explicitly when required dependencies are absent.

### AAR-012: Tighten `td-core` Error and Race Semantics

Repo: `td-core`

Status: Not started

User story: As an operator, I want failures and concurrent work to be explicit so data is not dropped, duplicated, or silently defaulted.

Acceptance criteria:

- [ ] Replace swallowed errors that return benign defaults in critical paths.
- [ ] Fix edge poller locking or replace self-requeue polling with safer scheduling.
- [ ] Re-enable or replace skipped tests covering known race/failure behavior.
- [ ] Add observable degraded-state events for recoverable failures.

## P2 Stories

### AAR-013: Strengthen `td-core` Static Analysis and Complexity Gates

Repo: `td-core`

Status: Not started

Acceptance criteria:

- [ ] Re-enable or replace disabled complexity cops where practical.
- [ ] Add explicit exceptions only where justified.
- [ ] Track skipped and WIP tests as an enforced budget.
- [ ] Make JS test execution meaningful or remove the no-op path.

### AAR-014: Strengthen `td-edge` Static Analysis and Security Gates

Repo: `td-edge`

Status: Not started

Acceptance criteria:

- [ ] Narrow Ruff and Bandit ignores to justified local exceptions.
- [ ] Re-enable mypy on new or extracted modules.
- [ ] Configure CORS from environment with safe production defaults.
- [ ] Raise coverage gates incrementally after hotspot refactors.

### AAR-015: Make `td-tailor` Deployment Safer and More Reproducible

Repo: `td-tailor`

Status: Not started

Acceptance criteria:

- [ ] Require typed destructive confirmation before disk writes.
- [ ] Pin Pi OS image versions and verify checksums.
- [ ] Replace raw GitHub `main` first-boot downloads with pinned or embedded setup scripts.
- [ ] Replace `sshpass` and host-key bypass with key-based known-host deployment.
- [ ] Stage remote releases before atomic activation.

### AAR-016: Remove or Quarantine `td-tailor` Archive Code

Repo: `td-tailor`

Status: Not started

Acceptance criteria:

- [ ] Delete obsolete executable archive scripts or move them into non-executable historical docs.
- [ ] Ensure active docs reference only active scripts.
- [ ] Add a repo rule that agents/operators should not use archived scripts.

### AAR-017: Split Provider Reachability from Business Health in `td-status`

Repo: `td-status`

Status: Not started

Acceptance criteria:

- [ ] Separate external provider reachability checks from authenticated business integration checks.
- [ ] Ensure status page labels make the distinction clear.
- [ ] Define alert thresholds per service class.
- [ ] Document expected time-to-detect for each class.

### AAR-018: Add Cross-Repo Architecture Synthesis

Repo: `td-meta`

Status: Not started

User story: As a maintainer, I want a cross-repo synthesis so we can see systemic themes instead of reading six reports independently.

Acceptance criteria:

- [ ] Write a synthesis PHEEL summarizing cross-repo patterns.
- [ ] Group findings by theme: security, tenant isolation, error handling, test discipline, package idiom, placeholder code, and observability.
- [ ] Link each theme back to the relevant repo reports.
- [ ] Recommend a 30/60/90-day execution order.

## Suggested Execution Order

- [ ] Start with AAR-001 because leaked plaintext secrets have immediate blast radius.
- [ ] Continue with AAR-002 because shared Pi credentials multiply the same blast radius.
- [ ] Run AAR-003 and AAR-004 in parallel only if separate owners can handle Rails tenant/API work and edge client migration.
- [ ] Complete AAR-005 before large `td-edge` refactors so failure semantics are protected by tests.
- [ ] Use AAR-018 after the first security stories are underway so the synthesis can reflect both audit findings and remediation decisions.
