ABOUTME: Guidelines for AI agents working on td-meta repository infrastructure.
ABOUTME: This file establishes practices for maintaining cross-repository infrastructure.

# TD-Meta Agent Guidelines

This repository contains cross-repository infrastructure for TuxedoDrive. Changes here can affect multiple repositories, so extra care is required.

## Core Principles

1. **Coordination Required**: Changes to reusable workflows or cross-repo ADRs may impact multiple repositories. Always consider the blast radius.

2. **Clear Ownership**: Document which repository owns what. Per ADR-028, contracts typically live in the owning repository, not here.

3. **Backward Compatibility**: Breaking changes to reusable workflows require coordination across all consuming repositories.

4. **Immutable ADRs**: Cross-repo ADRs follow the same immutability rules as repo-specific ADRs.

5. **Agent Worktrees by Default**: Agents doing feature work use git worktrees by default. See `docs/policies/agent-worktrees.md` for the cross-repo policy, including the Claude symlink strategy, Codex helper workflow, and Gas City `.gc/worktrees` exception.

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
