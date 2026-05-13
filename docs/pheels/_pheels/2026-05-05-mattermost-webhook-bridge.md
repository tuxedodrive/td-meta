---
layout: post
title: "Mattermost → Mayor Webhook Bridge"
date: '2026-05-05'
category: setup
tags: [tooling, mattermost, mayor, webhooks, cloudflared]
status: live
author: MistyCrane (mayor) via dispatched implementer
llm-relevance: medium
---

# Mattermost → Mayor Webhook Bridge

JPB sends a message in Mattermost. A file lands in `/tmp/mm-mayor-inbox/` on
JPB's laptop in ~200ms. The mayor session's `/loop` picks it up next tick.

## Two ways to send

### 1. Post in `#mistycrane-coord` with a trigger word

Trigger words: `m:`, `mayor`, `misty`, `mistycrane`, `@mistycrane`. The post
must START with one of these (Mattermost's `trigger_when=start` semantics).

Example: `mayor: deploy advance to prod`.

### 2. Run `/mayor <message>` in any channel (including DMs)

Slash commands work in DMs, unlike outgoing webhooks. Type `/mayor pull
groundhog day footage from cam2` in a DM with mistycrane, the inbox file
shows up the same way.

## What lands in the inbox

```json
{
  "received_at_utc": "20260505T154604_788714Z",
  "received_at_epoch": 1777995964.788841,
  "channel_id": "98geuhbkyjgbigg1entbn6qzuo",
  "channel_name": "mistycrane-coord",
  "team_domain": "tuxedodrive",
  "user_id": "8htsqdnddf899qnsms49t3rt6y",
  "user_name": "mistycrane",
  "post_id": "z7y35zositbjtmkiszo7wmjq6h",
  "trigger_word": "mayor",
  "text": "mayor: webhook auth-multi test",
  "raw": { ... full Mattermost payload ... }
}
```

## Architecture

```
JPB types in MM    →  MM server (Hetzner 178.105.8.44:8065) fires:
                       - outgoing webhook  (channel post)
                       - slash command     (DM or any channel)
                  →  POST https://<quick-tunnel>.trycloudflare.com/mm-mayor-bridge
                  →  cloudflared on JPB's laptop forwards to localhost:8766
                  →  mm-mayor-bridge.py validates token, writes inbox file
                  →  /loop scans /tmp/mm-mayor-inbox/ each tick
```

## Components

| Piece | Path |
|---|---|
| Listener daemon | `~/.local/bin/mm-mayor-bridge.py` |
| Listener token allowlist | `~/.config/mm-mayor-bridge/tokens` |
| Listener launchd plist | `~/Library/LaunchAgents/com.tuxedodrive.mm-mayor-bridge.plist` |
| Tunnel launchd plist | `~/Library/LaunchAgents/com.tuxedodrive.mm-mayor-bridge-tunnel.plist` |
| Listener logs | `~/Library/Logs/mm-mayor-bridge/listener.{log,err.log}` |
| Tunnel logs | `~/Library/Logs/mm-mayor-bridge/tunnel.{log,err.log}` |
| Inbox | `/tmp/mm-mayor-inbox/<utcstamp>.json` |
| URL rotation script | `~/.local/bin/mm-mayor-bridge-rotate-url.sh` |

## Mattermost-side IDs

| Item | ID | Notes |
|---|---|---|
| Team `tuxedodrive` | `b6u4u4bzn3gjbnfk318ywwuiuh` | |
| Channel `mistycrane-coord` | `98geuhbkyjgbigg1entbn6qzuo` | public, created 2026-05-05 |
| Outgoing webhook `MistyCrane Mayor Bridge` | `854kwgbe3jbh8xgwif85xm857o` | trigger words bound to team, not channel |
| Slash command `/mayor` | `ogxq516yji8ajyj7dn9m9pznzr` | works in DMs |
| Bot user `mistycrane` | `8htsqdnddf899qnsms49t3rt6y` | bearer token used by REST + MCP |

Tokens are stored in `~/.config/mm-mayor-bridge/tokens` (chmod 600). Mattermost
sends its own token in every webhook payload; the listener checks it against
this allowlist. Tokens are not committed to git.

## Quick-tunnel URL is ephemeral

The bridge uses a Cloudflare quick tunnel (`cloudflared tunnel --url
http://localhost:8766`). Each `cloudflared` start picks a fresh random URL like
`https://loads-organizer-servers-etc.trycloudflare.com`. As long as the launchd
agent stays up the URL is stable, but on laptop reboot the URL changes and
Mattermost can't reach the listener.

After a reboot, run:

```bash
~/.local/bin/mm-mayor-bridge-rotate-url.sh
```

The script reads the new URL from the tunnel log and updates both the outgoing
webhook callback URL and the slash command URL via the Mattermost REST API.

## Future work — stable hostname

Migrate the bridge onto the existing named tunnel
(`914f6c00-d566-4c15-81b0-7462e521367f`) by adding an ingress rule for
`mm-mayor.tuxedodrive.dev` → `http://localhost:8766` and routing the DNS
record. That kills the rotation hassle but requires a Cloudflare DNS update
and a tunnel restart that briefly drops `td-core-local.tuxedodrive.dev`. Not
done yet — the laptop hasn't rebooted in the lifetime of this bridge so the
ephemeral URL has been fine.

## Verifying

```bash
# 1. Health check the listener locally
curl http://127.0.0.1:8766/health

# 2. Health check via the public URL (find it in the tunnel log)
PUBLIC=$(grep -oE 'https://[a-z0-9-]+\.trycloudflare\.com' \
  ~/Library/Logs/mm-mayor-bridge/tunnel.err.log | tail -1)
curl "$PUBLIC/health"

# 3. End-to-end: post in #mistycrane-coord
curl -s -X POST \
  -H "Authorization: Bearer ox7akq1oejda8nfjqra8wkwmuh" \
  -H "Content-Type: application/json" \
  http://178.105.8.44:8065/api/v4/posts \
  -d '{"channel_id":"98geuhbkyjgbigg1entbn6qzuo","message":"mayor: ping"}'

# 4. Inspect the inbox
ls -lt /tmp/mm-mayor-inbox/ | head -3
```

## Operational checks

- `launchctl list | grep mm-mayor-bridge` shows two entries with PID > 0.
- Inbox files arrive within 1 second of the Mattermost post (verified ~210ms in
  smoke tests on 2026-05-05).
- Rejecting wrong-token POSTs returns 401 (verified).
- Tokens file is mode 0600 (verified).
