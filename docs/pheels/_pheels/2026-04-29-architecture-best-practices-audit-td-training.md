---
layout: post
title: "Architecture Best Practices Audit: td-training"
date: '2026-04-29'
category: explorations
tags: [audit, architecture, dartantic, td-training, solid]
llm-relevance: high
---

Full audit notes for `td-training` against the supplied Architecture Best Practices rubric plus the full SOLID object-oriented principles.

## Scope

- Repo: `td-training`
- Worktree: `td-training/.claude/worktrees/arch-best-practices-code-audit`
- Branch: `arch-best-practices-code-audit`
- Audit date: 2026-04-30
- Report location: `td-meta/docs/pheels/_pheels/2026-04-29-architecture-best-practices-audit-td-training.md`
- Method: static review of training scripts, dataset scripts, Stanford Cars mapping/parser, Label Studio deployment files, README/CLAUDE guidance, and repository hygiene.
- Runtime note: this audit did not run training, dataset downloads, Docker, Render deployment, or tests. No `td-training` source files were changed.

The user rubric lists SRP separately and also asks for SOLID. I score SRP under SOLID-S to avoid double-counting, while still covering the other 19 supplied architecture practices.

## Executive Summary

`td-training` has a useful architectural boundary: model training and labeling infrastructure are separated from `td-edge` runtime inference and `td-core` business logic. The repo is small and understandable.

The implementation is script-oriented and not yet production-grade. There is no package/dependency lock, no tests, no static analysis, no reproducible experiment configuration, no seed/manifest discipline, and several scripts swallow errors. Training parameters are hardcoded into Python files. Generated mapping code is committed without golden tests. Label Studio deployment uses unpinned `latest` images and a shell script that parses API responses manually.

For an ML repo, the missing architecture primitive is reproducibility. The first remediation should be to make every training run describable by versioned config, pinned dependencies, dataset version, random seed, artifact manifest, and validation metrics.

## Rubric Scorecard

| Practice | Verdict | Audit result |
| --- | --- | --- |
| TDD | Fail | No test files or executable validation targets were found. |
| DRY | Mixed | Scripts are small, but dataset paths, training parameters, test-image logic, and model export behavior are duplicated/hardcoded. |
| Separation of Concerns | Mixed | Training is separated from runtime repos, but scripts combine config, training, validation, export, and console UX. |
| Clear Abstractions and Contracts | Fail | There is no explicit contract for dataset versions, model artifacts, metrics, class mapping, or td-edge consumption. |
| Low Coupling, High Cohesion | Mixed | Repo scope is cohesive; scripts are tightly coupled to directory names and local environment assumptions. |
| Scalability and Statelessness | Mixed-to-fail | Training work can run locally/cloud, but no reproducible config/manifest exists for scaling experiments or comparing runs. |
| Observability and Testability | Fail | No tests, no metrics schema, no structured run manifests, and broad exception catches reduce diagnosability. |
| KISS | Mixed | Direct scripts are simple to run, but hidden ML state makes results hard to reproduce. |
| YAGNI | Pass | The repo is small and avoids framework bloat. |
| Do Not Swallow Errors | Fail | Several scripts catch broad exceptions, print/log, and return `None` without failing the process. |
| No Placeholder Code | Mixed | No obvious toy placeholders in training, but hardcoded paths and manual instructions stand in for durable workflow contracts. |
| No Comments for Removed Functionality | Pass | No major dead-code/commented-history problem was found. |
| Layered Architecture | Mixed-to-fail | No shared library layer separates config parsing, data preparation, training, evaluation, and artifact export. |
| Prefer Non-Nullable Variables | Mixed-to-fail | Critical paths rely on hardcoded strings and implicit local files rather than required typed config. |
| Prefer Async Notifications | Not applicable | This is not a runtime service. |
| Consider First Principles | Mixed-to-fail | From scratch, an ML training repo would make reproducibility and artifact contracts first-class. |
| Eliminate Race Conditions | Mixed | Not a concurrent runtime repo, but generated source and overwritten training outputs create reproducibility hazards. |
| Maintainability | Mixed-to-fail | Small files are readable, but no dependency/tooling/test structure will make future changes brittle. |
| Arrange Project Idiomatically | Fail | Python ML projects should have dependency manifests, environment setup, tests, linting, ignored env files, and artifact manifests. |

## SOLID Scorecard

| Principle | Verdict | Audit result |
| --- | --- | --- |
| Single Responsibility | Mixed-to-fail | Training scripts combine setup, model selection, hyperparameters, training, evaluation, export, and smoke testing. |
| Open/Closed | Fail | Adding datasets, models, or hyperparameter variants requires editing Python scripts rather than adding config. |
| Liskov Substitution | Not applicable | Little OO substitution surface. The operational analog is weak because model/dataset variants are not substitutable through a stable config interface. |
| Interface Segregation | Mixed-to-fail | Operators interact with broad scripts rather than focused commands for download, validate, train, evaluate, export, and publish. |
| Dependency Inversion | Fail | Scripts depend directly on concrete paths, YOLO weight names, local files, Render API, and Docker image tags. |

## Major Findings

### 1. The repo has no dependency, test, or static-analysis contract

CLAUDE guidance says scripts are run directly and there is no formal package manager setup. Evidence: [CLAUDE.md](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/CLAUDE.md:11), [CLAUDE.md](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/CLAUDE.md:54), and [CLAUDE.md](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/CLAUDE.md:60).

No `requirements.txt`, `pyproject.toml`, lockfile, test files, Makefile, pre-commit config, or environment file was found in the repo inventory.

Impact: new contributors and agents cannot reproduce a working environment reliably. CI cannot verify even syntax/import-level correctness before a training change lands.

Recommended direction: add a minimal `pyproject.toml` or `requirements.txt` plus lock strategy, then add `pytest`, `ruff`, and a lightweight CI target that validates imports, parsing, mapping generation, and deploy script syntax.

### 2. Training runs are not reproducible enough for production model work

`train_make_model.py` hardcodes dataset path, base YOLO weights, training parameters, overwrite behavior, and CPU device. Evidence: [train_make_model.py](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/train_make_model.py:20), [train_make_model.py](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/train_make_model.py:40), [train_make_model.py](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/train_make_model.py:53), [train_make_model.py](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/train_make_model.py:61), and [train_make_model.py](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/train_make_model.py:63).

`cloud_train_stanford.py` hardcodes `stanford_cars_yolo/data.yaml`, YOLOv8s weights, training parameters, and fresh training behavior. Evidence: [cloud_train_stanford.py](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/cloud_train_stanford.py:29), [cloud_train_stanford.py](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/cloud_train_stanford.py:42), [cloud_train_stanford.py](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/cloud_train_stanford.py:55), and [cloud_train_stanford.py](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/cloud_train_stanford.py:76).

No random seed, dataset version manifest, metrics schema, artifact manifest, or td-edge compatibility contract was found.

Impact: two successful training runs can produce different artifacts with no reliable explanation. A model copied into `td-edge` may not be traceable back to data, code, weights, params, or evaluation metrics.

Recommended direction: introduce versioned experiment config files, pin datasets and pretrained weights, set seeds where supported, write a run manifest with git SHA/data version/params/metrics, and define a model artifact contract for td-edge.

### 3. Error handling often prints and returns instead of failing the process

`train_make_model.py` catches broad exceptions and returns `None`. Evidence: [train_make_model.py](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/train_make_model.py:80) and [train_make_model.py](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/train_make_model.py:82).

`download_dataset.py` catches broad exceptions, prints the error, and returns `None`. Evidence: [download_dataset.py](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/download_dataset.py:53) and [download_dataset.py](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/download_dataset.py:55).

`cloud_train_stanford.py` catches broad exceptions and prints a traceback instead of explicitly failing with a nonzero exit contract. Evidence: [cloud_train_stanford.py](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/cloud_train_stanford.py:144), [cloud_train_stanford.py](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/cloud_train_stanford.py:146), and [cloud_train_stanford.py](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/cloud_train_stanford.py:147).

Impact: automation can treat failed training/download as a successful script exit unless every caller checks returned Python values. This violates the explicit "do not swallow errors" rubric item.

Recommended direction: let exceptions fail by default or convert them to domain-specific exceptions and `sys.exit(1)` at the CLI boundary.

### 4. Stanford Cars mapping generation writes source without tests or golden outputs

`stanford_cars_parser.py` generates and writes `stanford_cars_mapping.py`. Evidence: [stanford_cars_parser.py](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/stanford_cars_parser.py:69), [stanford_cars_parser.py](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/stanford_cars_parser.py:170), [stanford_cars_parser.py](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/stanford_cars_parser.py:189), and [stanford_cars_mapping.py](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/stanford_cars_mapping.py:1).

Impact: generated source can drift silently from its parser, input metadata, or expected class count. Without a golden test, class-ID changes can break td-edge interpretation of model outputs.

Recommended direction: add a fixture/golden test for generated mapping shape, expected class count, representative make/model pairs, and stable ID ordering. Prefer generating artifacts into a build output directory unless committed source is required.

### 5. Dataset extraction and downloads are not hardened

`download_dataset_manual.py` extracts zip contents with `extractall` and returns `None` in manual paths. Evidence: [download_dataset_manual.py](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/download_dataset_manual.py:37), [download_dataset_manual.py](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/download_dataset_manual.py:78), and [download_dataset_manual.py](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/download_dataset_manual.py:80).

Impact: if this ever extracts untrusted zip files, it is vulnerable to path traversal. Even with trusted data, no checksum or dataset manifest means the training data cannot be verified later.

Recommended direction: validate zip member paths before extraction, record checksum/source/version, and fail loudly when expected dataset structure is missing.

### 6. Label Studio deployment is not pinned or strongly validated

The Dockerfile and Render API deployment use `heartexlabs/label-studio:latest`. Evidence: [Dockerfile](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/deploy/label-studio/Dockerfile:4) and [deploy.sh](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/deploy/label-studio/deploy.sh:83).

The deployment script uses `curl -s` without `--fail`, parses JSON through inline Python snippets, and creates JSON payloads in shell. Evidence: [deploy.sh](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/deploy/label-studio/deploy.sh:27), [deploy.sh](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/deploy/label-studio/deploy.sh:32), [deploy.sh](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/deploy/label-studio/deploy.sh:44), [deploy.sh](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/deploy/label-studio/deploy.sh:73), and [deploy.sh](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/deploy/label-studio/deploy.sh:104).

`render.yaml` is better on secrets because Render generates the Label Studio password and marks cloud credentials as manually synced. Evidence: [render.yaml](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/deploy/label-studio/render.yaml:21), [render.yaml](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/deploy/label-studio/render.yaml:34), and [render.yaml](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/deploy/label-studio/render.yaml:36).

Impact: a new Label Studio version can change behavior unexpectedly, and API failures can be harder to diagnose.

Recommended direction: pin Label Studio by version or digest, add `curl --fail-with-body`, validate API responses, and prefer Render blueprint management over ad hoc shell JSON when possible.

### 7. `.gitignore` is incomplete for a Python/ML repo

The ignore file covers datasets, training outputs, logs, caches, and OS files. Evidence: [.gitignore](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/.gitignore:1), [.gitignore](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/.gitignore:6), [.gitignore](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/.gitignore:11), and [.gitignore](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/.gitignore:15).

It does not cover common Python environments and secret files such as `.venv/`, `venv/`, `.env`, `.env.*`, notebooks checkpoints, or large model formats beyond `models/*.pt`.

Impact: the repo can accidentally commit local environments, secrets, notebooks, or non-`.pt` artifacts as it matures.

Recommended direction: extend `.gitignore` using standard Python/ML patterns and add a secret-scan/pre-commit gate before adding cloud/API workflows.

## Positive Controls To Preserve

- Keep training separated from `td-edge` runtime inference. This is a good system boundary.
- Keep the repo small and script-readable while adding only enough packaging to make runs reproducible.
- Keep Render-managed/generated secrets for Label Studio rather than committing passwords. Evidence: [render.yaml](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/deploy/label-studio/render.yaml:21).
- Keep `.gitignore` coverage for large datasets and training outputs, then expand it. Evidence: [.gitignore](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/.gitignore:1) and [.gitignore](/Users/jpb/workspace/tuxedodrive/td-training/.claude/worktrees/arch-best-practices-code-audit/.gitignore:6).

## Remediation Priority

1. Add dependency management and a minimal test/lint CI target.
2. Move training parameters into versioned experiment config files.
3. Write run manifests with git SHA, dataset version, weights, seed, params, metrics, and artifact paths.
4. Define a model artifact contract consumed by `td-edge`.
5. Replace broad exception returns with explicit failure semantics.
6. Add golden tests for Stanford Cars mapping generation.
7. Harden dataset extraction and record checksums.
8. Pin Label Studio images and strengthen Render API deployment error handling.
9. Expand `.gitignore` for Python environments, secrets, notebooks, and model artifact formats.
