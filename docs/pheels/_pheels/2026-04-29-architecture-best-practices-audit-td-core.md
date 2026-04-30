---
layout: post
title: "Architecture Best Practices Audit: td-core"
date: '2026-04-29'
category: explorations
tags: [audit, architecture, dartantic, td-core, solid]
llm-relevance: high
---

Full audit notes for `td-core` against the supplied Architecture Best Practices rubric plus the full SOLID object-oriented principles.

## Scope

- Repo: `td-core`
- Worktree: `td-core/.claude/worktrees/arch-best-practices-code-audit`
- Branch: `arch-best-practices-code-audit`
- Audit date: 2026-04-29
- Report location: `td-meta/docs/pheels/_pheels/2026-04-29-architecture-best-practices-audit-td-core.md`
- Method: static code review of architecture docs, Rails structure, controllers, services, models, jobs, contracts, schema, tests, features, routes, and quality tooling.
- Runtime note: this audit did not run the application test suite. No `td-core` source files were changed.

The user rubric includes SRP as an architecture item and also asks for SOLID. I score SRP under SOLID-S to avoid double-counting, while still covering every supplied architecture bullet.

## Executive Summary

`td-core` has strong written architectural intent and an unusually broad test surface, but the implementation is not consistently held to those standards. The highest-risk gaps are tenant-boundary enforcement, unauthenticated/trust-based edge control APIs, silent error/defaulting paths, production-visible stubs, timestamp data corruption, race-prone polling, and large controller/service hotspots that have grown past SRP.

The previous first-pass report was too shallow. A full audit finds multiple major architecture issues, not one. The root pattern is not lack of architecture. The root pattern is enforcement drift: the guidelines are good, but lint gates, DB constraints, API contracts, and decomposition boundaries do not consistently force the code to obey them.

## Rubric Scorecard

| Practice | Verdict | Audit result |
| --- | --- | --- |
| TDD | Mixed | There are 674 Minitest files and 6,565 `test` declarations, but 121 skipped tests, 70 `@wip` feature markers, and test naming does not follow the local "should" rule in most tests. |
| DRY | Mixed-to-fail | Duplicate/coexisting patterns exist in Stripe webhook routing, timestamp parsing, edge v1/v2 ingest, and route surfaces. |
| Separation of Concerns | Fail in hotspots | Controllers and services own orchestration, domain decisions, view data, API calls, and side effects in the same files. |
| Clear Abstractions and Contracts | Mixed | JSON contract tests and v2 edge validation are strong; production stubs, trust endpoints, and giant controllers weaken the contract boundary. |
| Low Coupling, High Cohesion | Mixed-to-fail | Newer edge/inference tables and contract code are cohesive; core dashboards, Stripe, routes, and ingestion services are highly coupled. |
| Scalability and Statelessness | Mixed | Rails/SolidQueue patterns are conventional, but self-requeue polling and cache-based locking create scaling and duplicate-work risks. |
| Observability and Testability | Mixed | Test volume is high, but observability is weakened by `rescue` paths that return zero, nil, "offline", "now", or mock data. |
| KISS | Mixed-to-fail | Several central files are too large to reason about simply, including 1,859-line operator dashboard and 1,751-line Stripe webhook controller. |
| YAGNI | Fail in some surfaces | Active debug routes, compatibility routes, mock analytics, and stubs are still in production code paths. |
| Do Not Swallow Errors | Fail | Multiple code paths convert operational failures into benign values instead of explicit failures or degraded-state events. |
| No Placeholder Code | Fail | Hardware adapter and analytics fallback code contain production-visible stub/mock behavior. |
| No Comments for Removed Functionality | Mixed-to-fail | Source contains active deprecated/legacy/commented compatibility branches rather than isolating history in ADRs or changelog material. |
| Layered Architecture | Mixed-to-fail | Rails layers exist, but several services/controllers bypass or combine layers, especially in Stripe, edge ingestion, and operator dashboard logic. |
| Prefer Non-Nullable Variables | Mixed-to-fail | Newer edge/inference tables are better, but legacy critical tables still allow null tenant IDs, statuses, and money fields. |
| Prefer Async Notifications | Mixed-to-fail | Some eventing exists, but edge and hardware flows still rely on polling loops. |
| Consider First Principles | Mixed | The docs do this well; implementation drift shows where current architecture differs from the architecture likely chosen from scratch. |
| Eliminate Race Conditions | Mixed-to-fail | There is good atomic vehicle creation code, but the edge poller lock is not a real concurrency lock and the relevant test is skipped. |
| Maintainability | Mixed-to-fail | Documentation is strong; disabled complexity cops and very large files make maintainability regressions easy. |
| Arrange Project Idiomatically | Mixed | Rails layout is recognizable and mature, but JS tests are a no-op and Ruby static analysis has disabled major complexity cops. |

## SOLID Scorecard

| Principle | Verdict | Audit result |
| --- | --- | --- |
| Single Responsibility | Fail in hotspots | `OperatorDashboardController`, `StripeWebhooksController`, `Owner::DashboardsController`, `SightingIngestionService`, and several mailer/service files have multiple reasons to change. |
| Open/Closed | Fail in hotspots | Adding Stripe event behavior or visit lifecycle variations requires editing giant branching classes rather than adding handlers/rules behind stable extension points. |
| Liskov Substitution | Mixed-to-fail | `HardwareAdapters::MoxaAdapter` inherits from an adapter abstraction but returns no-op success for hardware operations and `false` for connection checks, which is not substitutable production behavior. |
| Interface Segregation | Fail in hotspots | Large controllers expose broad action/helper surfaces and force unrelated dependencies through the same objects. |
| Dependency Inversion | Mixed-to-fail | Some router/contract abstractions exist, but high-value controllers still call concrete models, Stripe APIs, and global state directly. |

## Major Findings

### 1. Tenant isolation has strong doctrine but incomplete enforcement

`GUIDELINES-ARCHITECTURE.md` says all database queries must be scoped to `current_tenant`; unscoped queries are explicitly called a security bug. Evidence: [GUIDELINES-ARCHITECTURE.md](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/GUIDELINES-ARCHITECTURE.md:25).

Several production paths bypass or depend on global uniqueness instead of tenant-first lookups:

- `WashifyTransactionImporter` sets `Current.tenant = @tenant`, then uses unscoped `Order.find_or_initialize_by(washify_invoice_number: invoice_number)`. Evidence: [app/services/washify_transaction_importer.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/services/washify_transaction_importer.rb:207).
- The same importer uses unscoped `Customer.where("name ILIKE ?", ...)`, which can link imported rows to another tenant's customer. Evidence: [app/services/washify_transaction_importer.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/services/washify_transaction_importer.rb:284).
- The edge dashboard falls back to `CarWashLocation.first` when no current tenant location exists. Evidence: [app/controllers/edge/edge_controller.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/controllers/edge/edge_controller.rb:14).
- `TdEdge::TenantResolver` resolves locations by ID, slug, or `edge_api_url` without a tenant parameter. This may be intentional for path-based edge APIs, but then those identifiers must be globally unique by contract. Evidence: [app/services/td_edge/tenant_resolver.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/services/td_edge/tenant_resolver.rb:31) and [app/services/td_edge/tenant_resolver.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/services/td_edge/tenant_resolver.rb:41).
- Stripe webhook tenant fallback resolves `CarWashLocation.find_by(slug: metadata["location_slug"])` before tenant scoping. Evidence: [app/controllers/stripe_webhooks_controller.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/controllers/stripe_webhooks_controller.rb:119).

Impact: cross-tenant reads/writes are possible if identifiers collide or if importer data is ambiguous. This is the highest-priority architecture gap because multi-tenancy is a core invariant.

Recommended direction: create tenant-first repository/query helpers for imports, webhook lookups, and edge resolution; add regression tests with duplicate slugs/invoice numbers/customers across tenants; add a custom RuboCop cop or review gate for unscoped model queries in tenant-sensitive namespaces.

### 2. Trust-based v1 edge APIs can create or fetch physical-control commands without credentials

`Api::V1::MoxaController` explicitly documents a trust-based API, allows unauthenticated access, skips CSRF, skips tenant middleware, and accepts tenant identity by query parameter. Evidence: [app/controllers/api/v1/moxa_controller.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/controllers/api/v1/moxa_controller.rb:8), [app/controllers/api/v1/moxa_controller.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/controllers/api/v1/moxa_controller.rb:19), and [app/controllers/api/v1/moxa_controller.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/controllers/api/v1/moxa_controller.rb:46).

`Api::V1::WashSequencesController` uses the same trust model for pending/executable wash sequence flows. Evidence: [app/controllers/api/v1/wash_sequences_controller.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/controllers/api/v1/wash_sequences_controller.rb:17), [app/controllers/api/v1/wash_sequences_controller.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/controllers/api/v1/wash_sequences_controller.rb:66), and [app/controllers/api/v1/wash_sequences_controller.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/controllers/api/v1/wash_sequences_controller.rb:165).

This conflicts with newer, stronger patterns already present:

- `Api::V2::Edge::EdgeDataController` uses bearer authentication and JSON contract validation. Evidence: [app/controllers/api/v2/edge/edge_data_controller.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/controllers/api/v2/edge/edge_data_controller.rb:9) and [app/controllers/api/v2/edge/edge_data_controller.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/controllers/api/v2/edge/edge_data_controller.rb:25).
- Newer ingest controllers verify HMAC signatures. Evidence: [app/controllers/ingest/visits_controller.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/controllers/ingest/visits_controller.rb:10) and [app/controllers/ingest/detections_controller.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/controllers/ingest/detections_controller.rb:8).

Impact: physical output commands and wash execution surfaces depend on network trust and tenant query parameters. That is a weak first-principles boundary for on-prem devices controlling real equipment.

Recommended direction: migrate v1 edge/hardware endpoints behind the same device authentication model as v2/HMAC; require signed commands or per-device bearer tokens; include tenant/site/device in authenticated claims instead of query parameters; deprecate trust endpoints with explicit sunset tests.

### 3. Central controllers and services violate SRP, separation of concerns, KISS, and ISP

The largest living files are large enough to be architecture risks by themselves:

- `OperatorDashboardController`: 1,859 lines, 73 method definitions, inline `Data.define` view models, and 13 `before_action` loaders. Evidence: [app/controllers/operator_dashboard_controller.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/controllers/operator_dashboard_controller.rb:13), [app/controllers/operator_dashboard_controller.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/controllers/operator_dashboard_controller.rb:51), and [app/controllers/operator_dashboard_controller.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/controllers/operator_dashboard_controller.rb:54).
- `StripeWebhooksController`: 1,751 lines, giant event dispatch, payment logic, tenant context switching, Stripe API calls, receipt data, and recovery behavior. Evidence: [app/controllers/stripe_webhooks_controller.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/controllers/stripe_webhooks_controller.rb:36).
- `Owner::DashboardsController`: 1,225 lines. Evidence: [app/controllers/owner/dashboards_controller.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/controllers/owner/dashboards_controller.rb:1).
- `config/routes.rb`: 1,190 lines with marketing, owner, API, edge, debug, compatibility, and tenant/non-tenant routes in one file. Evidence: [config/routes.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/config/routes.rb:1).

Impact: these files resist local reasoning, make regression review expensive, and force unrelated dependencies through the same objects. That breaks SRP and interface segregation, and it also weakens Open/Closed because new behavior is added by editing giant branching classes.

Recommended direction: split by stable seams, not just by file size. For `OperatorDashboardController`, extract page/query presenters and command handlers. For Stripe, route all events through handler classes. For routes, split route files or mounted constraints by public/root, tenant, owner, API, edge, and debug/dev.

### 4. Stripe webhooks have two architectures, and the better one is not driving the controller

The codebase has a `Stripe::Router` with a handler map. Evidence: [app/services/stripe/router.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/services/stripe/router.rb:3) and [app/services/stripe/router.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/services/stripe/router.rb:30).

The active controller still owns its own large `case event["type"]` dispatch and dozens of `handle_*` methods. Evidence: [app/controllers/stripe_webhooks_controller.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/controllers/stripe_webhooks_controller.rb:36), [app/controllers/stripe_webhooks_controller.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/controllers/stripe_webhooks_controller.rb:92), and [app/controllers/stripe_webhooks_controller.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/controllers/stripe_webhooks_controller.rb:799).

The audit grep found `Stripe::Router` only in the service/tests, not in the webhook controller path. This means handler-based architecture and monolithic controller architecture coexist.

Impact: Stripe event behavior is not Open/Closed. Adding or changing an event means editing a giant controller with tenant, API, money, order, membership, and receipt concerns mixed together.

Recommended direction: make the controller authenticate/parse/idempotency-log only, then delegate to `Stripe::Router`. Move tenant resolution to a narrow policy object. Move each event into a handler with explicit idempotency, tenant, and failure semantics.

### 5. The edge/inference pipeline violates its own documented doctrine

`SightingIngestionService` begins with an ABOUTME warning that it still contains routing code that violates the doctrine. Evidence: [app/services/sighting_ingestion_service.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/services/sighting_ingestion_service.rb:4).

The service then handles visit lifecycle decisions directly after drawing inferences, branching on `end_visit`, `camera_role == "ingress"`, `create_visit`, and fallback visit creation. Evidence: [app/services/sighting_ingestion_service.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/services/sighting_ingestion_service.rb:165), [app/services/sighting_ingestion_service.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/services/sighting_ingestion_service.rb:177), and [app/services/sighting_ingestion_service.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/services/sighting_ingestion_service.rb:179).

This conflicts with the architecture guide's model: observations feed the inference engine, which produces inferences/audit trail, and status transitions happen through inference rules. Evidence: [GUIDELINES-ARCHITECTURE.md](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/GUIDELINES-ARCHITECTURE.md:161), [GUIDELINES-ARCHITECTURE.md](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/GUIDELINES-ARCHITECTURE.md:207), and [GUIDELINES-ARCHITECTURE.md](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/GUIDELINES-ARCHITECTURE.md:239).

Impact: new camera roles or visit lifecycle rules require changing ingestion routing code, not just configuration/rules. That weakens Open/Closed and makes audit trails less authoritative.

Recommended direction: move visit side effects behind inference/result handlers; make ingestion responsible for validating, normalizing, and recording observations only; add engine integration tests that prove no side path creates/modifies/completes visits without producing the required inference record.

### 6. Invalid timestamps are silently converted to "now"

Timestamp parse failures fall back to current time in several ingestion/aggregation paths:

- Shared timestamp concern returns `Time.current` for blank values and rescues parse failures to `Time.current`. Evidence: [app/services/concerns/timestamp_parsing.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/services/concerns/timestamp_parsing.rb:10) and [app/services/concerns/timestamp_parsing.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/services/concerns/timestamp_parsing.rb:16).
- Detection aggregation compares timestamps after `Time.parse(...) rescue Time.current`. Evidence: [app/services/detection_aggregator_service.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/services/detection_aggregator_service.rb:108).
- TD edge detection ingestion falls back to `Time.current` on parse errors. Evidence: [app/services/td_edge_detection_ingestion_service.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/services/td_edge_detection_ingestion_service.rb:70).
- Edge poller drops malformed timestamps from rate calculations with `rescue nil`. Evidence: [app/jobs/edge_poller_job.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/jobs/edge_poller_job.rb:378).

Impact: malformed or missing event times become plausible current events. This can corrupt visit timelines, make synchronization checks falsely pass, and hide edge clock or payload defects.

Recommended direction: distinguish `received_at` from `observed_at`; reject or quarantine invalid observed timestamps; emit structured contract errors; require explicit caller choice for fallback behavior.

### 7. Error swallowing turns real failures into zero, nil, offline, or mock data

Examples:

- Owner sidebar uses inline `rescue 0` for pending cash drops and daily reports. Evidence: [app/views/layouts/owner/_sidebar.html.erb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/views/layouts/owner/_sidebar.html.erb:122) and [app/views/layouts/owner/_sidebar.html.erb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/views/layouts/owner/_sidebar.html.erb:149).
- `Analytics::RealTimeBridge` rescues cache/client/timestamp failures to empty arrays, nil, or demo data. Evidence: [app/services/analytics/real_time_bridge.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/services/analytics/real_time_bridge.rb:173), [app/services/analytics/real_time_bridge.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/services/analytics/real_time_bridge.rb:193), [app/services/analytics/real_time_bridge.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/services/analytics/real_time_bridge.rb:337), and [app/services/analytics/real_time_bridge.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/services/analytics/real_time_bridge.rb:446).
- `Edge::HealthMonitor` maps several inspection failures to "offline" and uses `rescue 0` style behavior for ActionCable connections. Evidence: [app/services/edge/health_monitor.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/services/edge/health_monitor.rb:101), [app/services/edge/health_monitor.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/services/edge/health_monitor.rb:137), and [app/services/edge/health_monitor.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/services/edge/health_monitor.rb:142).

Impact: operators and developers can see "nothing pending", "offline", or realistic demo data instead of seeing the actual failing subsystem. That violates the rubric's explicit "Do not swallow errors" rule and weakens observability.

Recommended direction: use explicit degraded-state result objects with error cause, severity, source, and correlation ID; report unexpected exceptions to AppSignal; never replace production telemetry with demo numbers unless the environment is explicitly demo.

### 8. Edge polling has a race-prone lock and a skipped concurrency test

`EdgePollerJob` uses `Rails.cache.fetch(LOCK_KEY, ...) { execute_poll; "locked" }` as a lock. Evidence: [app/jobs/edge_poller_job.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/jobs/edge_poller_job.rb:6) and [app/jobs/edge_poller_job.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/jobs/edge_poller_job.rb:11).

The same job self-schedules additional polls. Evidence: [app/jobs/edge_poller_job.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/jobs/edge_poller_job.rb:32) and [app/jobs/edge_poller_job.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/jobs/edge_poller_job.rb:35).

The test that should prove concurrent execution is prevented is skipped because cache writes are no-ops under NullStore. Evidence: [test/jobs/edge_poller_job_test.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/test/jobs/edge_poller_job_test.rb:81).

Impact: concurrent cache misses can execute multiple polls. In a physical/edge pipeline, duplicate polling and broadcasting can corrupt operator state, double-schedule work, or mask timing bugs.

Recommended direction: replace `Rails.cache.fetch` with an atomic database advisory lock, SolidQueue concurrency controls, or `Rails.cache.write(..., unless_exist: true)` where the backend supports it; add a non-NullStore test backend for lock behavior; treat polling as transitional and prefer edge-pushed notifications where practical.

### 9. Money and nullability rules are not enforced consistently at the database boundary

The architecture guide says money is stored as integer cents and never floats. Evidence: [GUIDELINES-ARCHITECTURE.md](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/GUIDELINES-ARCHITECTURE.md:67) and [GUIDELINES-ARCHITECTURE.md](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/GUIDELINES-ARCHITECTURE.md:74).

Legacy/core tables still have weaker constraints:

- `orders.tenant_id` and `orders.total_cents` are nullable; legacy `orders.amount` still exists. Evidence: [db/schema.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/db/schema.rb:2216), [db/schema.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/db/schema.rb:2250), and [db/schema.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/db/schema.rb:2252).
- `Order` allows nil `total_cents` and converts nil to `0.0` in display/math helpers. Evidence: [app/models/order.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/models/order.rb:67), [app/models/order.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/models/order.rb:186), and [app/models/order.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/models/order.rb:190).
- `visits.amount_paid` is a decimal dollars field with an explicit comment saying it is dollars, and `visits.tenant_id`/`visit_status` are nullable. Evidence: [db/schema.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/db/schema.rb:3692), [db/schema.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/db/schema.rb:3714), and [db/schema.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/db/schema.rb:3719).
- `vehicles.license_plate` and `vehicles.tenant_id` are nullable. Evidence: [db/schema.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/db/schema.rb:3607) and [db/schema.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/db/schema.rb:3612).
- Membership price/subscription/tenant fields are nullable even though model-level logic likely depends on them. Evidence: [db/schema.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/db/schema.rb:1875), [db/schema.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/db/schema.rb:1894), and [db/schema.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/db/schema.rb:1895).

There are positive newer examples: detection events, observations, and sightings require `tenant_id` at the DB level. Evidence: [db/schema.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/db/schema.rb:1100), [db/schema.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/db/schema.rb:1983), and [db/schema.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/db/schema.rb:2967).

Impact: application validations can be bypassed by migrations, imports, console scripts, race conditions, or partial writes. Critical invariants should live in the database where possible.

Recommended direction: plan backwards-compatible migrations to make tenant and money fields non-null; migrate visit money to cents fields; keep legacy fields read-only behind compatibility adapters until fully removed.

### 10. Production-visible placeholder/stub behavior remains active

`HardwareAdapters::MoxaAdapter` says it handles Modbus TCP, but the implementation is explicitly stubbed:

- Connection validation is "stub until actual Modbus is implemented". Evidence: [lib/hardware_adapters/moxa_adapter.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/lib/hardware_adapters/moxa_adapter.rb:7).
- `poll_io_status` returns success with empty I/O maps. Evidence: [lib/hardware_adapters/moxa_adapter.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/lib/hardware_adapters/moxa_adapter.rb:27).
- `check_connection` always returns false. Evidence: [lib/hardware_adapters/moxa_adapter.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/lib/hardware_adapters/moxa_adapter.rb:40).
- `set_digital_output` returns success without writing to hardware. Evidence: [lib/hardware_adapters/moxa_adapter.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/lib/hardware_adapters/moxa_adapter.rb:64).

Other production-visible placeholder surfaces include public agent query stub routes, minimal test routes, non-tenant edge routes, and edge debug routes. Evidence: [config/routes.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/config/routes.rb:232), [config/routes.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/config/routes.rb:1168), [config/routes.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/config/routes.rb:1171), and [config/routes.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/config/routes.rb:1187).

Impact: placeholders in production code paths make behavior harder to reason about and violate the "No Placeholder Code" rule. For hardware paths, false success is especially dangerous.

Recommended direction: move unimplemented adapters behind explicit feature flags or raise `NotImplementedError` in non-test environments; remove public test/debug routes or constrain them to development; make demo analytics impossible outside demo tenants/environments.

### 11. Static analysis and security-warning baselines contain high-signal ignored risks

The repo has Brakeman ignored warnings for redirects, mass assignment, XSS, command injection, SQL injection, and other categories. Evidence: [config/brakeman.ignore](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/config/brakeman.ignore:4), [config/brakeman.ignore](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/config/brakeman.ignore:44), [config/brakeman.ignore](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/config/brakeman.ignore:228), and [config/brakeman.ignore](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/config/brakeman.ignore:268).

Concrete examples:

- Email campaign views render `raw @email_campaign.body_html`. Evidence: [app/views/owner/campaigns/email_campaigns/show.html.erb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/views/owner/campaigns/email_campaigns/show.html.erb:37) and [app/views/owner/campaigns/email_campaigns/edit.html.erb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/views/owner/campaigns/email_campaigns/edit.html.erb:242).
- Short URL controller allows redirects to other hosts. Evidence: [app/controllers/short_urls_controller.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/controllers/short_urls_controller.rb:18).
- Admin user params permit `:role`. Evidence: [app/controllers/admin/users_controller.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/controllers/admin/users_controller.rb:52).

This audit does not claim each ignored warning is exploitable. The architecture issue is that high-risk categories are ignored without an obvious living control that forces re-review.

Recommended direction: expire Brakeman ignores with dates/owners; move safe raw HTML through sanitization policies; restrict redirects with allowlists; treat role assignment as a separate authorization command, not a permitted user attribute.

### 12. Complexity guardrails are disabled where they are needed most

`.rubocop.yml` disables major complexity/size cops and sets new cops to disabled:

- `NewCops: disable`. Evidence: [.rubocop.yml](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/.rubocop.yml:10).
- Disabled metric cops include method length, class length, module length, block length, ABC size, cyclomatic complexity, perceived complexity, and parameter list. Evidence: [.rubocop.yml](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/.rubocop.yml:22).
- Line length is set to 200. Evidence: [.rubocop.yml](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/.rubocop.yml:48).

The frontend package has a no-op JS test script despite dependencies like ActionCable and D3. Evidence: [package.json](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/package.json:10) and [package.json](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/package.json:18).

Impact: architecture drift is not just possible; it is structurally permitted. The largest files found in this audit are exactly what disabled metric cops are meant to prevent.

Recommended direction: re-enable metrics gradually with excludes for known debt; set "ratchet" thresholds that prevent files from getting worse; add JS lint/test coverage for Stimulus/ActionCable/D3 behavior that affects operators.

### 13. Test surface is broad, but skip/WIP debt and convention drift reduce TDD signal

Positive baseline:

- 674 Ruby test files.
- 6,565 `test` declarations.
- Contract tests exist for detection, sighting, visit, and wash sequence payloads. Evidence: [test/contracts/detection_push_contract_test.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/test/contracts/detection_push_contract_test.rb:9), [test/contracts/sighting_push_contract_test.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/test/contracts/sighting_push_contract_test.rb:9), [test/contracts/visit_push_contract_test.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/test/contracts/visit_push_contract_test.rb:9), and [test/contracts/wash_sequence_contract_test.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/test/contracts/wash_sequence_contract_test.rb:3).

Debt:

- 121 skipped Ruby tests.
- 70 `@wip` markers in feature files.
- Only 369 of 6,565 Ruby test declarations include "should", while the local testing guide says test names must include "should". Evidence: [GUIDELINES-TESTING_PRACTICES.md](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/GUIDELINES-TESTING_PRACTICES.md:32) and [GUIDELINES-TESTING_PRACTICES.md](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/GUIDELINES-TESTING_PRACTICES.md:59).
- Critical architecture tests are skipped, including the edge poller concurrency test. Evidence: [test/jobs/edge_poller_job_test.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/test/jobs/edge_poller_job_test.rb:81).

Impact: test count is high, but the TDD signal is uneven. Skipped and WIP tests are acceptable only when tracked as explicit debt with owners and dates.

Recommended direction: classify skips into "intentional integration guard" vs "broken architecture"; create CI visibility for skip/WIP count; require architecture-sensitive skipped tests to be linked to issues and fail after a sunset date.

### 14. Legacy/debug/commented compatibility code has accumulated in active source

Examples:

- Backwards-compatible edge heartbeat route remains active until td-edge changes. Evidence: [config/routes.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/config/routes.rb:1066).
- Minimal test and edge debug routes remain active at the end of routes. Evidence: [config/routes.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/config/routes.rb:1168) and [config/routes.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/config/routes.rb:1187).
- Deprecated order transaction type is still present in the model. Evidence: [app/models/order.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/models/order.rb:117).
- Deprecated vehicle lookup method remains in the model. Evidence: [app/models/vehicle.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/models/vehicle.rb:167).

Impact: active source becomes a history log and compatibility sink. That violates the "No Comments for Removed Functionality" rule and increases YAGNI debt.

Recommended direction: convert compatibility paths into dated deprecation tickets with removal criteria; remove debug/test routes from production route loading; keep history in ADR/PHEEL posts, not inline implementation comments.

## Positive Controls Worth Preserving

- The architecture guide is unusually concrete about tenant scoping, money, time zones, visit inference, and edge/inference patterns. Evidence: [GUIDELINES-ARCHITECTURE.md](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/GUIDELINES-ARCHITECTURE.md:2).
- The testing guide is concrete about outside-in TDD, tenant-scoped tests, and inference pipeline expectations. Evidence: [GUIDELINES-TESTING_PRACTICES.md](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/GUIDELINES-TESTING_PRACTICES.md:23) and [GUIDELINES-TESTING_PRACTICES.md](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/GUIDELINES-TESTING_PRACTICES.md:282).
- Contract tests exist for the edge payload boundary. Evidence: [test/contracts/detection_push_contract_test.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/test/contracts/detection_push_contract_test.rb:9).
- Newer edge/inference tables show stronger DB-level tenant discipline than legacy tables. Evidence: [db/schema.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/db/schema.rb:1100), [db/schema.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/db/schema.rb:1983), and [db/schema.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/db/schema.rb:2967).
- `Vehicle.find_or_create_by_plate!` uses a transaction and `RecordNotUnique` recovery to handle race conditions. Evidence: [app/models/vehicle.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/models/vehicle.rb:123), [app/models/vehicle.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/models/vehicle.rb:129), and [app/models/vehicle.rb](/Users/jpb/workspace/tuxedodrive/td-core/.claude/worktrees/arch-best-practices-code-audit/app/models/vehicle.rb:149).

## First-Principles Target Architecture

If starting from scratch, the td-core shape implied by the written guidelines would likely be:

- Tenant boundary: every tenant-sensitive operation enters through an authenticated tenant/site/device context object; DB constraints enforce tenant and money invariants.
- Edge boundary: devices authenticate with bearer/HMAC credentials; device identity supplies tenant/site; observations are pushed as events where possible; commands are durable, signed, and acknowledged.
- Domain pipeline: controllers validate/authenticate/dispatch only; observations feed the inference engine; inference result handlers own visit side effects; audit records are authoritative.
- Error model: unexpected exceptions are reported; expected degraded states are explicit result objects; production UI never replaces failure with zero, nil, now, or demo data without a visible degraded-state marker.
- Extension model: Stripe events, edge event types, hardware adapters, and dashboard widgets extend through small handlers/presenters/adapters rather than growing monolithic controllers.

## Remediation Priority

1. Fix tenant and auth boundaries first: Washify importer, edge dashboard fallback, tenant resolver contracts, Stripe location fallback, and trust-based v1 edge APIs.
2. Stop data corruption defaults: replace timestamp-to-now fallbacks and high-risk `rescue` defaults with explicit invalid/degraded results.
3. Fix concurrency: replace `EdgePollerJob` cache-fetch locking and unskip the concurrency test with a real lock backend.
4. Remove or isolate placeholders: Moxa no-op adapter, demo analytics, public stubs, test/debug routes, and legacy compatibility routes.
5. Decompose hotspots: Stripe webhook, operator dashboard, owner dashboard, routes, and ingestion services.
6. Restore guardrails: ratchet RuboCop metrics, add JS test/lint coverage, and make Brakeman ignores owned/reviewable.
7. Harden schema contracts: non-null tenant/money/status fields, cents-only visit money, and compatibility migrations for legacy data.
8. Make test debt visible: skip/WIP dashboard, owner/date metadata for skips, and fail-on-new-skips for architecture-sensitive areas.

## Bottom Line

`td-core` is not architecturally naive. It has strong doctrine and several good newer patterns. The audit concern is that the codebase has outgrown its enforcement mechanisms. The next architecture work should focus less on writing new guidelines and more on making existing guidelines mechanically hard to violate.
