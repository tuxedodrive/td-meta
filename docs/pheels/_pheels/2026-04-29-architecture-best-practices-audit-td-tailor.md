---
layout: post
title: "Architecture Best Practices Audit: td-tailor"
date: '2026-04-29'
category: explorations
tags: [audit, architecture, dartantic, td-tailor, solid]
llm-relevance: high
---

Full audit notes for `td-tailor` against the supplied Architecture Best Practices rubric plus the full SOLID object-oriented principles.

## Scope

- Repo: `td-tailor`
- Worktree: `td-tailor/.claude/worktrees/arch-best-practices-code-audit`
- Branch: `arch-best-practices-code-audit`
- Audit date: 2026-04-30
- Report location: `td-meta/docs/pheels/_pheels/2026-04-29-architecture-best-practices-audit-td-tailor.md`
- Method: static review of deployment/flashing scripts, site config docs, secrets conventions, archive contents, repo guidance, and shell/Python tooling.
- Runtime note: this audit did not run deployment, flashing, SOPS, SSH, or disk commands. No `td-tailor` source files were changed.

The user rubric lists SRP separately and also asks for SOLID. I score SRP under SOLID-S to avoid double-counting, while still covering the other 19 supplied architecture practices.

## Executive Summary

`td-tailor` is operationally important because it provisions Raspberry Pi edge devices, deploys `td-edge`, and manages site configuration. Its intended architecture is good: keep site config in git, encrypt secrets with SOPS, and provide repeatable deployment scripts.

The implementation currently violates that intent in high-risk ways. Plaintext `.env.*` files with API keys, RTSP camera URLs, and R2 credentials are committed even though docs say they must be ignored/encrypted. Default Pi credentials are documented and hardcoded. Flashing and deployment scripts perform destructive or trust-weakening operations with limited guardrails. Legacy scripts remain under `archive/` and account for much of the repo's executable surface. There are no executable tests or shell lint gates.

This repo needs a security-first cleanup before architecture polish. Remove and rotate committed secrets, fix ignore rules, move active secrets to SOPS, and add validation around destructive scripts.

## Rubric Scorecard

| Practice | Verdict | Audit result |
| --- | --- | --- |
| TDD | Fail | No executable tests, shellcheck config, bats tests, Makefile, or pre-commit hooks were found. |
| DRY | Mixed-to-fail | Active and archived deployment/flashing scripts duplicate credentials, imaging, setup, and deployment logic. |
| Separation of Concerns | Mixed | The intended site/secrets/deploy separation is documented, but scripts combine discovery, download, disk writes, credentials, and remote install. |
| Clear Abstractions and Contracts | Fail | The SOPS secrets contract is clear in docs but violated by committed plaintext env files. |
| Low Coupling, High Cohesion | Mixed-to-fail | Site config and deployment are cohesive in purpose, but hardcoded credentials and remote clone/install logic tightly couple scripts to one Pi model and one operational flow. |
| Scalability and Statelessness | Mixed | Git-managed site config can scale, but manual scripts and default credentials do not scale safely across a fleet. |
| Observability and Testability | Fail | Deployment and imaging scripts have no dry-run/test suite beyond a limited flash preflight mode. |
| KISS | Mixed | The small active script set is understandable, but hidden complexity lives in archive and destructive shell flows. |
| YAGNI | Fail | Large archived/deprecated script trees remain in the repo and duplicate active behavior. |
| Do Not Swallow Errors | Mixed | Scripts often use shell exits, but curl/download/remote-install behavior is not consistently fail-fast or pinned. |
| No Placeholder Code | Mixed | No app placeholders, but script conventions and docs claim encrypted secrets while plaintext files remain committed. |
| No Comments for Removed Functionality | Fail | `archive/` keeps legacy/deprecated executable history in source instead of relying on git history or explicit docs. |
| Layered Architecture | Mixed-to-fail | There is no clean library/CLI layer; shell scripts directly perform orchestration, disk mutation, network fetch, and remote installation. |
| Prefer Non-Nullable Variables | Mixed-to-fail | Shell scripts use defaults for sensitive values instead of requiring explicit configured credentials. |
| Prefer Async Notifications | Not applicable | This is a deployment/config repo, not a runtime service. |
| Consider First Principles | Fail | From scratch, a fleet provisioning repo would start with secret hygiene, idempotent operations, dry-run validation, and non-default credentials. |
| Eliminate Race Conditions | Mixed | Not a concurrent service, but deployment scripts can race with partial remote state and destructive filesystem operations. |
| Maintainability | Mixed-to-fail | Docs are substantial, but duplicated scripts, archive bloat, plaintext envs, and missing test/lint gates make maintenance risky. |
| Arrange Project Idiomatically | Mixed-to-fail | The repo is recognizable as ops scripts plus docs, but lacks standard shell/Python tooling and has committed env files that docs say are ignored. |

## SOLID Scorecard

| Principle | Verdict | Audit result |
| --- | --- | --- |
| Single Responsibility | Mixed-to-fail | Active scripts combine argument parsing, download, disk mutation, credentials, remote execution, dependency install, and service setup. |
| Open/Closed | Fail | Adding new Pi images, auth modes, locations, or deployment strategies requires editing large shell scripts instead of adding configuration. |
| Liskov Substitution | Not applicable | Little OO surface. The operational analog fails because plaintext env files are not substitutable for encrypted SOPS secrets. |
| Interface Segregation | Mixed-to-fail | Operators get broad scripts that do many actions rather than small commands with explicit contracts and dry-run modes. |
| Dependency Inversion | Fail | Scripts depend on concrete hosts, passwords, raw GitHub `main`, latest Pi OS, sshpass, and remote mutable state. |

## Major Findings

### 1. Plaintext secrets are committed despite the SOPS contract

Repo docs say per-site secrets must be encrypted with SOPS and that plaintext secrets must never be committed. Evidence: [CLAUDE.md](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/CLAUDE.md:68), [CLAUDE.md](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/CLAUDE.md:86), [configs/README.md](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/configs/README.md:46), and [.gitignore](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/.gitignore:16).

But committed `.env.*` files contain sensitive key names for API keys, CarCheck keys, RTSP camera URLs, Pi credentials, and R2 credentials. I am intentionally not quoting the secret values here. Evidence by key location: [configs/.env.jamaica-queens-staging](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/configs/.env.jamaica-queens-staging:35), [configs/.env.jamaica-queens-staging](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/configs/.env.jamaica-queens-staging:42), [configs/.env.jamaica-queens-staging](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/configs/.env.jamaica-queens-staging:52), [configs/.env.jamaica-queens-staging](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/configs/.env.jamaica-queens-staging:78), [configs/.env.jamaica-queens-staging](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/configs/.env.jamaica-queens-staging:79), [configs/.env.jamaica-queens-production](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/configs/.env.jamaica-queens-production:33), [configs/.env.jamaica-queens-production](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/configs/.env.jamaica-queens-production:45), [configs/.env.coruscant](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/configs/.env.coruscant:32), and [configs/.env.mustafar](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/configs/.env.mustafar:26).

The root ignore rule ignores `*.env`, but not `.env.*`, so the documented convention is not enforced. Evidence: [.gitignore](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/.gitignore:16) and [.gitignore](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/.gitignore:17).

Impact: this is the top risk in the repo. It violates clear contracts, security architecture, maintainability, and production readiness.

Recommended direction: rotate all exposed credentials, remove plaintext env files from git history or at least from the current tree, add `.env.*` ignore rules with an exception for `.env.example`, commit only SOPS-encrypted `secrets.env.enc`, and add a secret-scan CI gate.

### 2. Default Pi credentials are hardcoded and documented

The default credentials are visible in README, CLAUDE guidance, deployment script defaults, and image setup output. Evidence: [README.md](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/README.md:50), [README.md](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/README.md:70), [CLAUDE.md](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/CLAUDE.md:187), [deploy-td-edge.sh](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/deploy-td-edge.sh:10), [deploy-td-edge.sh](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/deploy-td-edge.sh:11), and [flash-pi.sh](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/flash-pi.sh:296).

Impact: fleet devices start from a known shared credential. If any device, network, or repo clone leaks, every similarly provisioned Pi is easier to compromise.

Recommended direction: generate per-device credentials during imaging, require an explicit credential file or SOPS secret, and reject deployment when defaults are still present outside a declared lab mode.

### 3. Disk flashing can write to a detected disk without a typed destructive confirmation

`flash-pi.sh` detects the latest Pi OS dynamically, downloads it, auto-detects the disk by looking for a boot partition, and writes with `sudo dd`. Evidence: [flash-pi.sh](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/flash-pi.sh:19), [flash-pi.sh](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/flash-pi.sh:22), [flash-pi.sh](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/flash-pi.sh:209), and [flash-pi.sh](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/flash-pi.sh:223).

Impact: a wrong disk detection or operator mistake can wipe the wrong device. Dynamic "latest" images also reduce reproducibility.

Recommended direction: require a typed confirmation including the exact disk identifier, display disk size/vendor before writing, pin Pi OS versions by default, and record image checksum/version in a generated manifest.

### 4. First-boot setup curls a raw GitHub `main` path that does not match the active repo layout

The flashing script writes a first-boot script that downloads setup code from a raw GitHub path under `pi-setup/` on `main`. Evidence: [flash-pi.sh](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/flash-pi.sh:259).

The current repo has `setup-tuxedodrive-pi.sh` at the root and an archived `archive/pi-setup/setup-tuxedodrive-pi.sh`, not an active root `pi-setup/` directory. Evidence: [setup-tuxedodrive-pi.sh](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/setup-tuxedodrive-pi.sh:1) and [archive/pi-setup/setup-tuxedodrive-pi.sh](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/archive/pi-setup/setup-tuxedodrive-pi.sh:1).

Impact: newly flashed devices can fail first boot or execute unexpected future `main` behavior. This violates reproducibility and clear deployment contracts.

Recommended direction: embed the exact setup script in the image or download a pinned tag/commit with checksum verification. Fix the path if remote download remains necessary.

### 5. Remote deployment uses weak SSH practices and destructive remote replacement

`deploy-td-edge.sh` defaults to password auth, requires `sshpass`, disables strict host key checking, removes the remote checkout, and clones from a user-provided repo URL. Evidence: [deploy-td-edge.sh](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/deploy-td-edge.sh:10), [deploy-td-edge.sh](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/deploy-td-edge.sh:98), [deploy-td-edge.sh](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/deploy-td-edge.sh:111), [deploy-td-edge.sh](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/deploy-td-edge.sh:125), [deploy-td-edge.sh](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/deploy-td-edge.sh:142), and [deploy-td-edge.sh](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/deploy-td-edge.sh:147).

Impact: deployments are hard to audit, hard to roll back, and vulnerable to host-key bypass. A partial failure can leave the Pi with no checkout or a partially installed environment.

Recommended direction: use SSH keys and known-host verification, deploy pinned td-edge refs, stage into a new release directory, then atomically switch a symlink or systemd target after validation.

### 6. `archive/` is large enough to act like active source

`archive/` contains 26 files, including old flashing, deployment, network, hotspot, and setup scripts. The repo guidance labels it as legacy/deprecated. Evidence: [CLAUDE.md](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/CLAUDE.md:174), [archive/deploy_to_pi.sh](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/archive/deploy_to_pi.sh:1), [archive/network-modes-experiment/flash-pi-complex.sh](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/archive/network-modes-experiment/flash-pi-complex.sh:1), and [archive/scripts/first-boot-setup.sh](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/archive/scripts/first-boot-setup.sh:1).

Impact: deprecated executable code stays searchable and copyable, and can drift from active scripts while still influencing future agents or operators. This directly conflicts with the rubric's "no comments for removed functionality" principle at repo scale.

Recommended direction: either delete archive content and rely on git history, or move historical material into a non-executable docs narrative that states it is not to be used.

### 7. There is no executable quality gate for shell-heavy fleet tooling

The repo has 24 shell scripts and substantial operational docs, but no shellcheck config, bats tests, Makefile, pre-commit hooks, package metadata, or test files were found. Evidence: [flash-pi.sh](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/flash-pi.sh:1), [deploy-td-edge.sh](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/deploy-td-edge.sh:1), [CLAUDE.md](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/CLAUDE.md:130), and [CLAUDE.md](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/CLAUDE.md:145).

Impact: the riskiest repo operationally has the least executable verification. Manual testing instructions are not a substitute for guards around disk writes, secrets, and remote execution.

Recommended direction: add `shellcheck` first, then bats or shellspec tests for argument parsing, disk confirmation, secret detection, path construction, and dry-run deployment behavior.

## Positive Controls To Preserve

- Keep the SOPS architecture; fix enforcement rather than abandoning it. Evidence: [docs/adr/003-sops-encrypted-secrets-management.md](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/docs/adr/003-sops-encrypted-secrets-management.md:1) and [CLAUDE.md](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/CLAUDE.md:86).
- Keep site config in git, but separate non-secret config from encrypted secrets. Evidence: [CLAUDE.md](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/CLAUDE.md:73).
- Keep a `--test` or dry-run mode for flashing and expand that pattern to deployment. Evidence: [flash-pi.sh](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/flash-pi.sh:117) and [flash-pi.sh](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/flash-pi.sh:177).
- Keep the goal of repeatable site reconstruction from repo plus age key, but make it true by removing plaintext secret drift. Evidence: [CLAUDE.md](/Users/jpb/workspace/tuxedodrive/td-tailor/.claude/worktrees/arch-best-practices-code-audit/CLAUDE.md:105).

## Remediation Priority

1. Rotate all exposed credentials and remove plaintext `.env.*` files from the current tree.
2. Fix `.gitignore` to ignore `.env.*` while keeping `.env.example`.
3. Enforce SOPS-only per-site secrets with a secret-scan CI gate.
4. Replace shared default Pi credentials with per-device credentials.
5. Add destructive confirmation, pinned image versions, and checksums to `flash-pi.sh`.
6. Fix or remove raw GitHub `main` first-boot download behavior.
7. Replace `sshpass`/host-key bypass deployment with key-based, pinned, staged releases.
8. Remove or quarantine `archive/` so deprecated scripts do not behave like active source.
9. Add shellcheck plus basic bats/shellspec coverage for active scripts.
