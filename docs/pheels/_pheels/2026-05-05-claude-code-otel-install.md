---
layout: post
title: "claude-code-otel install"
date: '2026-05-05'
category: setup
tags: [tooling, observability, claude-code, otel, grafana]
authors: [JPB, MistyCrane sub]
llm-relevance: medium
---

# claude-code-otel install

ColeMurray/claude-code-otel — OTel Collector + Prometheus + Loki + Grafana stack
that ingests Claude Code telemetry (cost, tokens, tool usage, sessions) and
visualizes it in a pre-built Grafana dashboard.

Repo: https://github.com/ColeMurray/claude-code-otel

## What's installed where

| Thing | Path |
|---|---|
| Stack repo (cloned) | `/Users/jpb/workspace/claude-code-otel/` |
| Containers | OrbStack — `otel-collector`, `prometheus`, `loki`, `grafana` |
| Env-vars helper | `/Users/jpb/workspace/claude-code-otel/claude-otel.env` |

Containers run via `docker compose` (see `Makefile` targets `up`/`down`/`status`/`logs`).

## How to view telemetry

| URL | Purpose | Creds |
|---|---|---|
| http://localhost:3000/d/claude-code-obs/claude-code-observability | Pre-built dashboard | admin / admin |
| http://localhost:3000 | Grafana home | admin / admin |
| http://localhost:9090 | Prometheus query UI | none |
| http://localhost:8889/metrics | Raw collector exposition | none |

## How to point a Claude Code session at the stack

Two options:

### Option A (recommended, persistent) — global settings env

Add this to `~/.claude/settings.json` inside the existing `env` block. The
sandbox blocks Claude from editing this file itself, so JPB has to paste it:

```json
"env": {
  "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1",
  "CLAUDE_CODE_ENABLE_TELEMETRY": "1",
  "OTEL_METRICS_EXPORTER": "otlp",
  "OTEL_LOGS_EXPORTER": "otlp",
  "OTEL_EXPORTER_OTLP_PROTOCOL": "grpc",
  "OTEL_EXPORTER_OTLP_ENDPOINT": "http://localhost:4317",
  "OTEL_METRIC_EXPORT_INTERVAL": "10000",
  "OTEL_LOGS_EXPORT_INTERVAL": "5000"
},
```

Restart any `claude` sessions that should report telemetry — env vars are read
at startup. The currently-running mayor session won't pick this up until next
launch (which is fine; no breakage either way).

### Option B (ad hoc) — source the env helper before `claude`

```bash
source /Users/jpb/workspace/claude-code-otel/claude-otel.env
claude
```

Useful for one-off sessions or testing. Same env vars, just shell-scoped.

## Stack lifecycle

```bash
cd /Users/jpb/workspace/claude-code-otel
make up        # bring up
make status    # see container state
make down      # stop (preserves volumes)
make clean     # stop + wipe volumes
make logs-collector  # tail the OTel collector
```

OrbStack must be running. All four services use `restart: unless-stopped`, so
they'll come back after laptop reboot as long as OrbStack is up.

## Verification

End-to-end pipeline confirmed working at install time:

```bash
# Send a synthetic OTLP metric via HTTP
curl -sS -X POST http://localhost:4318/v1/metrics \
  -H 'Content-Type: application/json' \
  -d '{"resourceMetrics":[{"resource":{"attributes":[{"key":"service.name","value":{"stringValue":"probe"}}]},"scopeMetrics":[{"scope":{"name":"probe"},"metrics":[{"name":"claude_code.install_probe","sum":{"aggregationTemporality":2,"isMonotonic":true,"dataPoints":[{"asInt":1,"timeUnixNano":"'"$(date +%s)"'000000000","startTimeUnixNano":"'"$(date +%s)"'000000000"}]}}]}]}]}'

# Confirm Prometheus picked it up
curl -sS 'http://localhost:9090/api/v1/query?query=claude_code_install_probe_total'
```

Once `claude` is running with the env vars set, real metrics start at
`claude_code_session_count_total`, `claude_code_token_usage_tokens_total`,
`claude_code_cost_usage_USD_total`, etc. (see the README's "Available Metrics"
section).

## Why this stack vs. Honeycomb / Datadog / etc.

- 100% local — no creds, no per-token billing, no PII leaving the laptop
- Pre-built dashboard for the exact Claude Code metric schema
- Ports don't conflict with td-* dev (verified at install)

## Token-burn relevance

The mayor-session token-burn investigation (2026-04-28) needs visibility into
tool-use patterns and per-model spend. This dashboard surfaces both:
- "Cost & Usage Analysis" panel breaks spend by model
- "Tool Usage & Performance" panel shows tool frequency + success rate
- "Event Logs" panel (Loki) captures `claude_code.user_prompt` and
  `claude_code.tool_result` events for forensic replay

## Caveats

- The currently-running mayor session won't emit telemetry until restarted
  with env vars in place
- The collector listens only on localhost (4317 gRPC, 4318 HTTP) — fine for
  single-laptop use, would need TLS + auth for shared/remote
- `OTEL_LOG_USER_PROMPTS=1` is **not** set — full prompt content is NOT logged.
  Add it to the env block if you want prompt corpora in Loki
- Log retention defaults are Loki/Prometheus defaults (multi-week). If laptop
  disk pressure shows up, tune `prometheus.yml` retention and Loki
  `local-config.yaml`
