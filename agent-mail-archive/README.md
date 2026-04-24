🌌 Why does agent-mail-archive exist?
=============================

MCP agent-mail routes every message between our cooperating Claude sessions through a local git-backed mailbox at `~/.mcp_agent_mail_git_mailbox_repo/`. That directory lives outside any project repo, has no backup, and gets garbage-collected when we retire agents. We keep losing research-grade signal — handoff quality, coordination patterns, incident timelines — because it only ever lived in that volatile spot. This archive is the durable copy.


🌌🌌 Who benefits from this archive?
=============================

- JPB, when he wants to retrace a multi-agent incident ("how did the DMV-guard hand-off actually go?")
- Whoever runs kaizen on agent coordination — handoff quality, message latency, dropped threads
- Future mayor sessions rehydrating context after their own history compacts away
- Anyone auditing the sequence of decisions on a cross-repo change


🌌🌌🌌 What exactly is in here?
=============================

- `sync.sh` — one-way rsync that mirrors the live mailbox for the `/Users/jpb/workspace` project_key into `snapshot/`. Uses `--delete` so the mirror reflects actual current state.
- `snapshot/` — the mirrored tree. Contains `agents/<Identity>/...` and `messages/...` exactly as the MCP server lays them out.
- This `README.md`.

Scope is the shared `/Users/jpb/workspace` project_key only (every td-* repo plus the non-TD utilities that share the same project). Other project_keys are not mirrored here.


🌌🌌🌌🌌 How do I use it?
=============================

Take a snapshot:

```
cd agent-mail-archive
./sync.sh
git add -A snapshot
git commit -m "archive: snapshot agent-mail state."
git push
```

Read a thread:

```
ls snapshot/agents/MistyCrane/
cat snapshot/messages/<id>.json
```

Scheduling (cron, launchd, session hook) is an open question — for now the archive gets refreshed on demand when JPB or the mayor wants a new cut.


🌌🌌🌌🌌🌌 Extras
=============================

- Why td-meta, not td-core: the archive spans every `~/workspace/*` agent, including non-TD repos. td-meta is our cross-repo home.
- The `--delete` flag in `sync.sh` is deliberate: the mirror shows *current* mailbox state, not an append-only log. Git history is the append-only log.
