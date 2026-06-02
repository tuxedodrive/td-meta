🌌 Why td-dolt-sync exists
=============================

Beads (the `bd` issue tracker) is backed by Dolt. Each td-* repo has its own Dolt database under `.beads/embeddeddolt/`, and the canonical multi-machine store lives at `https://doltremoteapi.dolthub.com/tuxedodrive/<repo>`. Without a sync loop, machines drift: agents and humans write beads locally, the next `bd ready` on another machine misses them, and short-id fuzzy matching starts to misresolve onto unrelated issues.

`td-dolt-sync` is a small launchd agent that runs `bd dolt pull` (and optionally `push`) across every td-* repo every 5 minutes. When you clone a td-* repo on a new Mac, run `scripts/install-td-dolt-sync` once and the rest is automatic.


🌌🌌 Who benefits from td-dolt-sync?
=============================

- Anyone who works on td-* across more than one machine.
- Background agents (gastown.mayor, polecats) that depend on `bd ready` reflecting work other machines did.
- Future-you setting up a fresh laptop — install once and beads sync without thinking about it.


🌌🌌🌌 What exactly does td-dolt-sync do?
=============================

`scripts/td-dolt-sync` walks `$TD_REPOS_ROOT` (default `~/workspace/tuxedodrive`), finds every directory matching `td-*` that has a `.beads/metadata.json`, starts the per-repo Dolt server if it is not running, and calls `bd dolt pull` (and `push` if configured).

`scripts/install-td-dolt-sync` writes `~/Library/LaunchAgents/com.tuxedodrive.td-dolt-sync.plist`, registers it with `launchctl`, and triggers an immediate first run via `launchctl kickstart`.

`scripts/uninstall-td-dolt-sync` removes the launchd plist and leaves the script + log file in place.

Defaults:
- `TD_DOLT_SYNC_INTERVAL=300` (every 5 minutes)
- `TD_DOLT_SYNC_MODE=pull` (set to `push` or `both` to also push local changes)
- `TD_DOLT_SYNC_LOG=$HOME/Library/Logs/td-dolt-sync.log`
- `TD_REPOS_ROOT=$HOME/workspace/tuxedodrive`


🌌🌌🌌🌌 How do I use td-dolt-sync?
=============================

## Install

```bash
cd ~/workspace/tuxedodrive/td-meta
scripts/install-td-dolt-sync
```

That is it. The agent runs once immediately, then every 5 minutes. Survives reboot.

## Verify

```bash
launchctl list | grep td-dolt-sync
tail -f ~/Library/Logs/td-dolt-sync.log
```

## Push as well as pull

```bash
TD_DOLT_SYNC_MODE=both scripts/install-td-dolt-sync
```

Re-running `install-td-dolt-sync` is safe — it reloads the plist with the new env.

## Uninstall

```bash
scripts/uninstall-td-dolt-sync
```

## One-shot manual sync

```bash
scripts/td-dolt-sync
```


🌌🌌🌌🌌🌌 Extras
=============================

## Mac-only today

This uses `launchctl` and Apple's launchd. A Linux equivalent (systemd user timer) is straightforward but not packaged here yet — file an issue if you need it.

## Cross-machine recovery

If a fresh checkout shows `database "td_<repo>" not found` from `bd dolt pull`, the local Dolt data directory has not been seeded yet. Run `bd bootstrap` from the repo to pull the database from the GitHub-backed `sync.remote` (see `.beads/config.yaml`), then `td-dolt-sync` keeps it fresh from DoltHub.
