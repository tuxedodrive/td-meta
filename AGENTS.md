ABOUTME: Guidelines for AI agents working on td-meta repository infrastructure.
ABOUTME: This file establishes practices for maintaining cross-repository infrastructure.

# TD-Meta Agent Guidelines

This repository contains cross-repository infrastructure for TuxedoDrive. Changes here can affect multiple repositories, so extra care is required.

## TuxedoDrive Platform Root

This file is also the versioned Claude entrypoint for sessions started from the
unversioned workspace container at `/Users/jpb/workspace/tuxedodrive`.

The container directory should stay disposable and should not own durable
instructions. Do not require a real `CLAUDE.md` at the workspace root. If a
local root shim exists, it should only point to `td-meta/AGENTS.md`.

### Sibling Repositories

- `td-core/` - Rails application for customer portals, operator UI, owner
  dashboards, billing, memberships, ingestion, and reporting.
- `td-edge/` - On-prem Python pipeline for ALPR, detection, camera handling,
  device services, and sighting emission.
- `td-tailor/` - Provisioning and fleet management for on-prem devices.
- `td-training/` - Model training and AI datasets that ship to TD customers.
- `td-meta/` - Cross-repo operational docs, contracts, ADRs, and workspace
  instructions.
- `td-status/` - Status and monitoring site.
- `operator-android-app/` - Operator Android client.
- `operator-ios-app/` - Operator iOS client.

Each sibling must have an `AGENTS.md`. `CLAUDE.md`, when present, should only
delegate to `AGENTS.md`; durable guidance belongs in `AGENTS.md`.

Enforce this locally with:

```bash
td-meta/scripts/check-agent-docs.sh /Users/jpb/workspace/tuxedodrive
```

### When to Work From the Parent

Use `/Users/jpb/workspace/tuxedodrive` for work that needs more than one
repository in view:

- td-edge to td-core API or payload contract changes.
- Device or incident investigations that cross on-prem and cloud code.
- Repo-wide search across TuxedoDrive projects.
- Cross-repo docs, operational policy, or coordination updates.

For single-repo implementation work, `cd` into that repository and follow its
local instructions. For td-core code-writing, use an isolated worktree instead
of mutating the canonical checkout.

### Agent Mail

Use `/Users/jpb/workspace` as the agent-mail `project_key`.

This stays deliberately broader than the TuxedoDrive container so TD agents can
coordinate with non-TD utility repos when needed.

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
- [td-tailor](https://github.com/tuxedodrive/td-tailor) - Fleet management
- [td-agent](https://github.com/tuxedodrive/td-agent) - AI Phone Customer Service Agent
- [td-training](https://github.com/tuxedodrive/td-training) - Training materials

Consult each repository's AGENTS.md for repo-specific guidelines.

## Remote Hardware Access

All td-* repos may need access to Raspberry Pi devices running td-edge at car wash locations.

### SSH via Cloudflare Tunnel

Requires `cloudflared` (`brew install cloudflared` on macOS):

```bash
ssh -o ProxyCommand='cloudflared access ssh --hostname %h' td-pi@ssh-metal-pi.tuxedodrive.dev
```

### Fleet

| Device | Environment | Location | SSH Host |
|--------|-------------|----------|----------|
| metal-pi | staging + production | Advance Car Wash, Jamaica Queens | `ssh-metal-pi.tuxedodrive.dev` |

See `td-tailor/ansible/inventory.yml` for the full fleet inventory.

### Live Data (td-core)

td-core's `bin/dev` starts a reverse SSH tunnel (`bin/pi-tunnel`) that routes Pi sighting data to localhost:3281. td-edge sends to three targets (configured in `td-edge/config/targets.yaml`): production, staging, and local dev (best-effort).

### Useful td-edge Endpoints (port 8001 on Pi)

| Endpoint | Purpose |
|----------|---------|
| `/health` | Service health |
| `/detections/live` | Live detection UI |
| `/detections/latest` | JSON feed of recent detections |
| `/cameras/` | Camera status and live frames |

<!-- BEGIN BEADS INTEGRATION v:1 profile:minimal hash:ccf33ec3 -->
## Beads Issue Tracker

This project uses **bd (beads)** for issue tracking. Run `bd prime` to see full workflow context and commands.

### Quick Reference

```bash
bd ready              # Find available work
bd show <id>          # View issue details
bd update <id> --claim  # Claim work
bd close <id>         # Complete work
```

### Rules

- Use `bd` for ALL task tracking — do NOT use TodoWrite, TaskCreate, or markdown TODO lists
- Run `bd prime` for detailed command reference and session close protocol
- Use `bd remember` for persistent knowledge — do NOT use MEMORY.md files

**Architecture in one line:** issues live in a local Dolt DB; sync uses `refs/dolt/data` on your git remote; `.beads/issues.jsonl` is a passive export. See https://github.com/gastownhall/beads/blob/main/docs/SYNC_CONCEPTS.md for details and anti-patterns.

## Session Completion

**When ending a work session**, you MUST complete ALL steps below. Work is NOT complete until `git push` succeeds.

**MANDATORY WORKFLOW:**

1. **File issues for remaining work** - Create issues for anything that needs follow-up
2. **Run quality gates** (if code changed) - Tests, linters, builds
3. **Update issue status** - Close finished work, update in-progress items
4. **PUSH TO REMOTE** - This is MANDATORY:
   ```bash
   git pull --rebase
   bd dolt push
   git push
   git status  # MUST show "up to date with origin"
   ```
5. **Clean up** - Clear stashes, prune remote branches
6. **Verify** - All changes committed AND pushed
7. **Hand off** - Provide context for next session

**CRITICAL RULES:**
- Work is NOT complete until `git push` succeeds
- NEVER stop before pushing - that leaves work stranded locally
- NEVER say "ready to push when you are" - YOU must push
- If push fails, resolve and retry until it succeeds
<!-- END BEADS INTEGRATION -->
