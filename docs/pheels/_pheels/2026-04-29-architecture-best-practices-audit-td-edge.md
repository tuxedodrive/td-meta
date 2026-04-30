---
layout: post
title: "Architecture Best Practices Audit: td-edge"
date: '2026-04-29'
category: explorations
tags: [audit, architecture, dartantic, td-edge, solid]
llm-relevance: high
---

Full audit notes for `td-edge` against the supplied Architecture Best Practices rubric plus the full SOLID object-oriented principles.

## Scope

- Repo: `td-edge`
- Worktree: `td-edge/.claude/worktrees/arch-best-practices-code-audit`
- Branch: `arch-best-practices-code-audit`
- Audit date: 2026-04-30
- Report location: `td-meta/docs/pheels/_pheels/2026-04-29-architecture-best-practices-audit-td-edge.md`
- Method: static code review of Python service structure, FastAPI routers, CLI, edge orchestration services, sync/outbox paths, configuration, tests, contracts, and quality tooling.
- Runtime note: this audit did not run the application test suite. No `td-edge` source files were changed.

The user rubric lists SRP separately and also asks for SOLID. I score SRP under SOLID-S to avoid double-counting, while still covering the other 19 supplied architecture practices.

## Executive Summary

`td-edge` is the strongest implementation repo in the fleet from a tooling and test-surface perspective. It has a large pytest suite, contract tests, import-linter boundaries, Pydantic configuration validation, Ruff, Bandit, coverage, and a real outbox/retry mechanism. Those are meaningful positives.

The highest-risk architecture gaps are not absence of engineering discipline. They are enforcement drift around the largest files and operational edge cases. The 2,788-line `td_core` router, 2,422-line `ObjectTracker`, and 2,332-line CLI concentrate too many responsibilities. Several production paths turn failed I/O into empty lists, `None`, default config, or "synced" status. Some monitoring/control flows still depend on trust-based v1 APIs and polling contracts. Placeholder/mock behavior remains reachable in service and web paths.

This repo should be refactored in slices, not rewritten. Preserve the existing contract tests, import-linter intent, transactional outbox, and configuration validators; use them as the scaffold for extracting focused services and making failure states explicit.

## Rubric Scorecard

| Practice | Verdict | Audit result |
| --- | --- | --- |
| TDD | Mixed | The repo has 127 test files and roughly 1,270 test functions, but there are 45 skips/skipifs/xfails and several skipped tests explicitly cover not-yet-implemented or broken integration behavior. |
| DRY | Mixed-to-fail | API streaming, dashboard payload assembly, CLI orchestration, detector wiring, and v1/v2 sync paths have repeated patterns that should be service-backed. |
| Separation of Concerns | Fail in hotspots | `td_core.py`, `cli.py`, and `detection_tracker.py` combine transport, orchestration, presentation, state management, persistence, and hardware concerns. |
| Clear Abstractions and Contracts | Mixed | Import-linter and contract tests are strong; trust-based v1 APIs, mock services, and package/import drift weaken the runtime contracts. |
| Low Coupling, High Cohesion | Mixed-to-fail | Smaller services are cohesive, but the router/tracker/CLI hotspots are highly coupled to config, models, hardware, streams, and td-core payloads. |
| Scalability and Statelessness | Mixed | Edge devices require local state, but global trackers, in-process stream loops, and poll loops make scaling and restart behavior hard to reason about. |
| Observability and Testability | Mixed-to-fail | Logging and AppSignal/OpenTelemetry hooks exist, but several error paths report empty work, unknown frames, default config, or synced status instead of degraded/failing state. |
| KISS | Mixed-to-fail | There is a simple deployment target, but very large files, multiple compatibility paths, and inline rendering/streaming code make core flows hard to reason about. |
| YAGNI | Mixed-to-fail | Demo/mock/video-orchestrator behavior and unimplemented camera/network commands remain in the production tree. |
| Do Not Swallow Errors | Fail | Multiple service clients catch broad exceptions and return empty lists, `None`, or fallback config; this can hide broken APIs, cameras, and config. |
| No Placeholder Code | Fail | Detection, video processing, R2 upload, and motorist web paths still contain placeholder/mock behavior. |
| No Comments for Removed Functionality | Mixed-to-fail | Deprecated config aliases, compatibility imports, archived demos, and commented-out tooling keep old behavior active or visible in source. |
| Layered Architecture | Mixed | Import-linter contracts exist, but the API layer itself directly owns presentation, orchestration, streaming, database access, and hardware checks. |
| Prefer Non-Nullable Variables | Mixed | Core tenant/site/device settings are required and validated, but legacy optional aliases and nullable DB columns weaken the shape discipline. |
| Prefer Async Notifications | Mixed-to-fail | The outbox uses notify/wakeup to reduce polling latency, but moxa commands, wash sequences, safety status, and dashboard health rely on polling loops. |
| Consider First Principles | Mixed | The package has good primitives, but from scratch the main routers/trackers would likely be split around camera, detection, visit, moxa, sync, and presentation boundaries. |
| Eliminate Race Conditions | Mixed | There are explicit race-condition tests around CarCheck sightings and outbox wakeups, but global trackers and threaded pending-work coordination remain high-risk. |
| Maintainability | Mixed-to-fail | Tests and tooling are broad, but several files exceed 700-2,700 lines and major static-analysis gates are weakened or skipped. |
| Arrange Project Idiomatically | Fail | The package is declared as `src` and many imports use `src.td_edge.*`, which is not idiomatic Python packaging for a `td_edge` application. |

## SOLID Scorecard

| Principle | Verdict | Audit result |
| --- | --- | --- |
| Single Responsibility | Fail in hotspots | `td_core.py`, `cli.py`, and `ObjectTracker` each have many independent reasons to change. |
| Open/Closed | Mixed-to-fail | Adding new dashboard surfaces, stream modes, camera modes, or detector behaviors often requires editing large branching modules instead of adding handlers behind stable interfaces. |
| Liskov Substitution | Mixed | Some classes expose clear behavior, but mock detection, placeholder processors, and stubbed R2 sync are not substitutable for production implementations. |
| Interface Segregation | Fail in hotspots | Large routers and services expose broad surfaces that force unrelated dependencies and behaviors through the same objects. |
| Dependency Inversion | Mixed | Import-linter intends to enforce direction, but major modules still depend directly on concrete services, config, globals, HTTP clients, and hardware abstractions. |

## Major Findings

### 1. Python package structure is not idiomatic and weakens tooling boundaries

`pyproject.toml` declares `packages = [{include = "src"}]`, and import-linter uses `root_package = "src"`. Evidence: [pyproject.toml](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/pyproject.toml:7) and [pyproject.toml](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/pyproject.toml:133).

The project guidance says modules should be imported as `td_edge.*`, but static search found hundreds of imports using `src.td_edge.*`. Examples include [tests/api/test_new_endpoints.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/tests/api/test_new_endpoints.py:7) and [src/td_edge/services/outbox_helper.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/outbox_helper.py:10).

Impact: import-linter, packaging, test imports, and runtime imports are enforcing the wrong abstraction boundary. It also makes cross-repo consumers more likely to cargo-cult the nonstandard `src.` package path.

Recommended direction: change packaging to include `td_edge`, update imports to `td_edge.*`, and move import-linter contracts to `root_package = "td_edge"`. Do this as a mechanical migration with tests and import-linter in the same PR.

### 2. `td_core.py` is a transport, presenter, stream server, dashboard API, and hardware facade in one file

`src/td_edge/api/routers/td_core.py` is 2,788 lines. It defines health, detection, stream, camera, zone, tracked-object, sighting, and redirect endpoints in the same router. Evidence: [td_core.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/api/routers/td_core.py:19), [td_core.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/api/routers/td_core.py:125), [td_core.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/api/routers/td_core.py:180), [td_core.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/api/routers/td_core.py:506), [td_core.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/api/routers/td_core.py:966), [td_core.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/api/routers/td_core.py:1536), and [td_core.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/api/routers/td_core.py:2396).

The file also contains long-running streaming loops with `while True` and repeated sleep/backoff patterns. Evidence: [td_core.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/api/routers/td_core.py:583), [td_core.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/api/routers/td_core.py:854), [td_core.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/api/routers/td_core.py:1283), and [td_core.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/api/routers/td_core.py:1483).

Impact: SRP, interface segregation, testability, and layering all degrade. Any dashboard, camera, zone-editor, stream, or td-core contract change risks this file.

Recommended direction: split into focused routers and presenters: health/status, detections, streams, cameras, zones, tracked objects, sightings, and visit redirects. Keep FastAPI handlers thin and move payload assembly into typed service/presenter objects.

### 3. The CLI owns runtime orchestration instead of being a command facade

`src/td_edge/cli.py` is 2,332 lines and contains runtime loops, camera display behavior, detection orchestration, database groups, setup groups, multicam groups, and camera commands. Evidence: [cli.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/cli.py:345), [cli.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/cli.py:483), [cli.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/cli.py:1248), [cli.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/cli.py:1428), [cli.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/cli.py:1552), and [cli.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/cli.py:1959).

It also contains not-yet-implemented camera/network behavior. Evidence: [cli.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/cli.py:2205), [cli.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/cli.py:2317), and [cli.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/cli.py:2328).

Impact: commands are hard to test without executing orchestration, and new runtime behavior requires editing a command file rather than composing application services.

Recommended direction: keep Click functions as argument parsers and move command bodies into `commands/` or `services/` objects with unit tests. Split setup, db, detection, camera, and multicam command modules.

### 4. `ObjectTracker` is a high-risk stateful god object

`src/td_edge/services/detection_tracker.py` is 2,422 lines. `ObjectTracker` owns tracking, CarCheck pending-work coordination, thumbnail emission, visit proposal interactions, tracked object state, locks, and global tracker helpers. Evidence: [detection_tracker.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/detection_tracker.py:137), [detection_tracker.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/detection_tracker.py:194), [detection_tracker.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/detection_tracker.py:830), and [detection_tracker.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/detection_tracker.py:2392).

Impact: this is the central correctness hotspot for sightings, visits, thumbnails, and asynchronous CarCheck updates. The repo has race-condition tests around this area, which is a positive signal, but the object is still too broad for confident change.

Recommended direction: split tracking state, visit proposal, thumbnail publishing, and CarCheck lifecycle coordination behind explicit interfaces. Preserve the existing race tests and add tests around each extracted boundary.

### 5. Production code hides operational failures as empty work, missing data, or defaults

`WashSequenceApiClient.fetch_pending_sequences` documents that it returns an empty list on error and does so for HTTP and broad exception failures. Evidence: [wash_sequence_api.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/wash_sequence_api.py:62), [wash_sequence_api.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/wash_sequence_api.py:83), and [wash_sequence_api.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/wash_sequence_api.py:87).

`MoxaCommandExecutor.fetch_pending_commands` returns an empty list on API or exception failure while incrementing stats. Evidence: [moxa_command_executor.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/moxa_command_executor.py:179), [moxa_command_executor.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/moxa_command_executor.py:182), and [moxa_command_executor.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/moxa_command_executor.py:185).

`snapshot_capture.py` catches broad exceptions around capture paths, and configuration loading falls back to `{}` when pipeline config is missing or invalid. Evidence: [snapshot_capture.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/snapshot_capture.py:49), [settings.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/config/settings.py:235), [settings.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/config/settings.py:253), and [settings.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/config/settings.py:267).

Impact: a broken td-core API, broken camera, or broken pipeline config can look like "no commands", "no sequences", "no frame", or "default config". That violates the explicit rubric item to not swallow errors.

Recommended direction: return typed degraded-state results or raise domain exceptions that caller loops convert into observable failure events. Empty work should mean td-core explicitly returned no work, not that the network failed.

### 6. Placeholder and mock behavior remains reachable in production packages

`DetectionService` defaults to mock mode and has a TODO for loading real models. Evidence: [detection_service.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/detection_service.py:40) and [detection_service.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/detection_service.py:57).

`VideoProcessor` explicitly says it is placeholder behavior and returns empty results for unimplemented processing. Evidence: [video_processor.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/processors/video_processor.py:179), [video_processor.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/processors/video_processor.py:187), and [video_processor.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/processors/video_processor.py:220).

`OutboxFlushService` marks R2 items as synced even though upload is not implemented. Evidence: [outbox_flush_service.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/outbox_flush_service.py:281), [outbox_flush_service.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/outbox_flush_service.py:295), and [outbox_flush_service.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/outbox_flush_service.py:297).

The motorist web route constructs `DetectionService(mock_mode=True)` and returns a placeholder vehicle image. Evidence: [motorist.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/web/routes/motorist.py:47), [motorist.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/web/routes/motorist.py:83), and [motorist.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/web/routes/motorist.py:96).

Impact: test/demo behavior can leak into production and create false confidence that work was processed or synced.

Recommended direction: isolate demos and mocks under explicit test/demo entrypoints. Production services should fail fast if a real detector, processor, or R2 uploader is required but not configured.

### 7. Polling is overused where event contracts should exist

The repo has a good positive example: the outbox flush service preserves notify wakeups and reduces latency via `notify()`. Evidence: [outbox_flush_service.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/outbox_flush_service.py:65), [outbox_flush_service.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/outbox_flush_service.py:308), and [outbox_helper.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/outbox_helper.py:92).

Other production flows still poll: wash sequences poll td-core, moxa commands poll td-core, safety monitor polls hardware inputs, and the td-core dashboard is optimized for frequent polling. Evidence: [wash_sequence_runner.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/wash_sequence_runner.py:40), [wash_sequence_runner.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/wash_sequence_runner.py:168), [moxa_command_executor.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/moxa_command_executor.py:117), [moxa_command_executor.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/moxa_command_executor.py:877), [safety_monitor.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/safety_monitor.py:130), and [td_core.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/api/routers/td_core.py:109).

Impact: some polling is unavoidable for edge hardware, but td-core command/control and dashboard integration should have an explicit rationale. Polling expands race windows and makes latency/failure behavior harder to prove.

Recommended direction: keep hardware polling where the device protocol requires it; move td-core command and dashboard contracts toward push, long-poll, webhook, SSE, or MQTT-style notification where feasible.

### 8. Trust-based v1 command/control contracts conflict with the rest of the architecture

Moxa command execution explicitly treats API key as optional and relies on tenant/site identifiers. Evidence: [moxa_command_executor.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/moxa_command_executor.py:85), [moxa_command_executor.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/moxa_command_executor.py:121), and [moxa_command_executor.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/moxa_command_executor.py:136).

Wash sequence polling uses a v1 endpoint filtered by tenant and site. Evidence: [wash_sequence_api.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/wash_sequence_api.py:13), [wash_sequence_api.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/wash_sequence_api.py:59), and [wash_sequence_api.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/wash_sequence_api.py:65).

Impact: the td-core audit already identified trust-based edge APIs as high-risk. The edge client side confirms those contracts are active. For physical control surfaces, tenant/site query parameters are not a sufficient security contract.

Recommended direction: migrate physical-control APIs to signed, device-scoped v2 contracts with replay protection, explicit command leasing, idempotency keys, and ack/fail semantics.

### 9. CORS and static-analysis exceptions create avoidable security drift

FastAPI CORS allows all origins while credentials are enabled. Evidence: [app.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/api/app.py:83), [app.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/api/app.py:84), and [app.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/api/app.py:85).

Ruff ignores include `E722` for bare exceptions and `F401` for unused imports; Bandit skips include network certificate validation, shell subprocess, and hardcoded SQL classes. Evidence: [pyproject.toml](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/pyproject.toml:83), [pyproject.toml](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/pyproject.toml:108), and [pyproject.toml](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/pyproject.toml:170).

Mypy is present in dependencies but commented out in pre-commit. Evidence: [.pre-commit-config.yaml](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/.pre-commit-config.yaml:73).

Impact: the repo has good tools, but important guardrails are disabled exactly where edge software needs them most.

Recommended direction: convert broad skips into narrow per-line justifications, re-enable mypy on at least new/extracted modules, and move CORS to configured origins with a safe local-dev default.

### 10. Tests are broad, but skips and placeholders weaken TDD discipline

The suite is substantial, but there are explicit skipped tests for not-yet-implemented behavior, database-isolation failures, pre-existing failures, and hanging tests. Evidence: [test_new_endpoints.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/tests/api/test_new_endpoints.py:97), [test_video_to_visit_pipeline.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/tests/integration/test_video_to_visit_pipeline.py:516), [test_api_rails_routing.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/tests/integration/test_api_rails_routing.py:104), [test_visit_persistence.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/tests/unit/services/test_visit_persistence.py:15), and [test_pipeline_camera.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/tests/unit/services/test_pipeline_camera.py:13).

Impact: skipped integration and persistence tests are architecture signals, not just test hygiene issues. They mark seams where contracts are not stable enough to test.

Recommended direction: keep hardware/model/env skipifs, but eliminate skips for broken or missing behavior. Convert them into failing tests on feature branches, or move them into tracked PHEEL/TDD tasks outside the green default suite.

## Positive Controls To Preserve

- Keep the broad pytest investment and contract tests. They are the right foundation for refactoring.
- Keep import-linter, but retarget it from `src` to `td_edge` after the package import migration.
- Keep Pydantic validation for required tenant, site, and device settings. Evidence: [settings.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/config/settings.py:38), [settings.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/config/settings.py:190), and [settings.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/config/settings.py:209).
- Keep the transactional outbox model and wakeup semantics. Evidence: [outbox.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/models/outbox.py:11) and [outbox_flush_service.py](/Users/jpb/workspace/tuxedodrive/td-edge/.claude/worktrees/arch-best-practices-code-audit/src/td_edge/services/outbox_flush_service.py:322).
- Keep race-focused tests around CarCheck and outbox behavior while extracting smaller services.

## Remediation Priority

1. Replace trust-based v1 physical-control APIs with signed, device-scoped command contracts.
2. Stop marking unimplemented R2 uploads as synced and stop returning empty work on API failures.
3. Split `td_core.py` into focused routers/presenters and split `cli.py` into command modules.
4. Extract `ObjectTracker` responsibilities behind explicit interfaces and preserve race tests.
5. Fix packaging/imports from `src.td_edge.*` to `td_edge.*`.
6. Remove or isolate placeholder/mock production paths.
7. Tighten CORS, Ruff, Bandit, mypy, and coverage gates incrementally.
