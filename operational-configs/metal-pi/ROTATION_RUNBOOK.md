---
date: 2026-04-28
title: Metal-pi leaked-keys rotation runbook
author: agent prep for JPB
status: paste-and-go
tags: [security, secrets, rotation, runbook]
---

# Metal-pi leaked-keys rotation runbook

ABOUTME: Paste-and-go runbook for rotating the leaked Doppler prd token + dev/prd
ABOUTME: API keys on metal-pi, swapping the hardened td-edge.service in.

Source incident: `td-core/docs/plans/2026-04-28-leaked-keys-rotation.md`
Companion files in this directory:
- `td-edge.service.proposed` — replacement systemd unit
- `dev-api-key.conf.removed` — sentinel for the deleted drop-in
- `doppler-config-changes.md` — Doppler dashboard changes

## Pre-flight (before touching the Pi)

1. Open Doppler dashboard. Have it on screen alongside this runbook.
2. Open a terminal with `td-meta` checked out to the branch that has these files
   (so you can `scp` / paste the new unit straight from local disk).
3. Confirm the rotation list checklist (`td-core/docs/plans/2026-04-28-leaked-keys-rotation.md`)
   is the source of truth for which keys are getting rotated. This runbook
   handles items #1, #2, and Gaps A/B/C.

---

## Step 1 — Doppler: mint new `prd` service token

Doppler dashboard → `td-edge` project → **Access** → **Service Tokens**.

1. Click **Generate Service Token**.
2. Name: `metal-pi-prd-2026-04-28` (date-stamped so we can revoke the old one cleanly).
3. Config: `prd_advance-jamaica_queens-lane_1` (or `prd` base if you don't branch).
4. Access: **Read-only**.
5. Expiration: **None**.
6. Click **Generate**, copy the token (starts with `dp.st.prd.`).
7. Paste it into a temporary `~/Desktop/new-prd-token.txt` on your laptop. Do NOT paste it into chat.

### Expected output
- New token visible in the Doppler tokens list named `metal-pi-prd-2026-04-28`.
- Old token (`dp.st.prd.l3bOaxY6...`) still in the list — DO NOT REVOKE YET.

---

## Step 2 — Doppler: split dev and prd API keys

Old `TD_EDGE_DEV_API_KEY` and `TD_EDGE_PRODUCTION_API_KEY` were identical
(`599d51f6...19b7`). Rotation generates two distinct values.

In td-core, generate two new device API keys (64 char hex each):

```bash
# On your laptop, in td-core
cd ~/workspace/td-core
bin/rails runner 'puts SecureRandom.hex(32)'   # NEW dev key
bin/rails runner 'puts SecureRandom.hex(32)'   # NEW prd key
```

Then in td-core, update the `Device.api_key_digest` for the dev device and the
prd device to the SHA256 of the respective new key. (How that's done depends
on the current device admin UI / console — out of scope for this runbook;
follow whatever the rotation list calls out for `Device.api_key_digest`.)

In Doppler:

- `td-edge` → `dev` config → set `TD_EDGE_DEV_API_KEY=<new dev key>`.
- `td-edge` → `prd` config (or `prd_advance-jamaica_queens-lane_1`) → set
  `TD_EDGE_PRODUCTION_API_KEY=<new prd key>`.

### Expected output
- Both Doppler configs show new values.
- `td-core` console confirms the dev device's `api_key_digest` matches the new
  dev key, and same for prd.

---

## Step 3 — SSH into metal-pi

```bash
ssh metal-pi
```

### Expected output
- Prompt looks like `td-pi@metal-pi:~$` (or whatever the canonical hostname is).
- `systemctl is-active td-edge` returns `active`.

---

## Step 4 — Stop td-edge

```bash
sudo systemctl stop td-edge
sudo systemctl is-active td-edge
```

### Expected output
- `is-active` returns `inactive` (or exits non-zero — that's fine for `inactive`).
- `journalctl -u td-edge -n 5` shows clean shutdown lines, no error spew.

---

## Step 5 — Back up the current unit and drop-in

```bash
sudo mkdir -p /root/td-edge-rotation-2026-04-28
sudo cp /etc/systemd/system/td-edge.service /root/td-edge-rotation-2026-04-28/
sudo cp -r /etc/systemd/system/td-edge.service.d /root/td-edge-rotation-2026-04-28/ 2>/dev/null || true
sudo ls -la /root/td-edge-rotation-2026-04-28/
```

### Expected output
- Directory listing shows `td-edge.service` and (if it exists) `td-edge.service.d/dev-api-key.conf`.
- This is your rollback. Do not delete it until the new unit is verified green for at least one full day.

---

## Step 6 — Install the new doppler.env

On your laptop:

```bash
scp ~/Desktop/new-prd-token.txt metal-pi:/tmp/new-prd-token.txt
```

On the Pi:

```bash
sudo install -m 600 -o root -g root /dev/null /etc/td-edge/doppler.env
echo "DOPPLER_TOKEN=$(cat /tmp/new-prd-token.txt)" | sudo tee /etc/td-edge/doppler.env > /dev/null
sudo chmod 600 /etc/td-edge/doppler.env
sudo chown root:root /etc/td-edge/doppler.env
sudo ls -la /etc/td-edge/doppler.env
shred -u /tmp/new-prd-token.txt
```

### Expected output
- `ls -la` shows `-rw------- 1 root root` and a recent timestamp.
- `sudo head -c 20 /etc/td-edge/doppler.env` prints `DOPPLER_TOKEN=dp.st.p` (don't print more — keep the token redacted in your scrollback).

---

## Step 7 — Install the new td-edge.service

On your laptop:

```bash
scp ~/workspace/tuxedodrive/td-meta/operational-configs/metal-pi/td-edge.service.proposed \
    metal-pi:/tmp/td-edge.service.proposed
```

On the Pi:

```bash
sudo install -m 644 -o root -g root /tmp/td-edge.service.proposed /etc/systemd/system/td-edge.service
sudo rm -f /tmp/td-edge.service.proposed
sudo cat /etc/systemd/system/td-edge.service | head -5
```

### Expected output
- First five lines show the ABOUTME comment block.
- `ls -la /etc/systemd/system/td-edge.service` shows `-rw-r--r-- 1 root root`.

---

## Step 8 — Delete the leaked dev-api-key drop-in

```bash
sudo rm -f /etc/systemd/system/td-edge.service.d/dev-api-key.conf
sudo rmdir /etc/systemd/system/td-edge.service.d 2>/dev/null || true
sudo ls -la /etc/systemd/system/td-edge.service.d 2>&1 | head -3
```

### Expected output
- Either `No such file or directory` (drop-in directory removed entirely) or
  the directory exists but contains NO `dev-api-key.conf`.
- `sudo systemctl cat td-edge | grep -i TD_EDGE_DEV_API_KEY` returns nothing.

---

## Step 9 — Reload systemd and start td-edge

```bash
sudo systemctl daemon-reload
sudo systemctl start td-edge
sudo systemctl is-active td-edge
```

### Expected output
- `is-active` returns `active`.
- No errors in `sudo systemctl status td-edge` — `Active: active (running)` and PID listed.

---

## Step 10 — Verify the token is NOT in argv

This is the whole point of the rotation. Confirm.

```bash
ps -p $(systemctl show -p MainPID --value td-edge) -o command= | head -c 200
```

### Expected output
- A line that starts with `/bin/bash -c doppler run -- /home/td-pi/td-edge/venv/bin/td-edge run --api-port 8001` and contains NO `dp.st.` substring.
- Cross-check: `ps -eo command | grep dp.st` returns nothing.

---

## Step 11 — Verify the dev API key is NOT in the unit

```bash
sudo systemctl cat td-edge | grep -iE 'TD_EDGE_DEV_API_KEY|599d51f6'
```

### Expected output
- No matches. Empty output.
- If anything matches, STOP and investigate — the drop-in or unit is still leaking.

---

## Step 12 — Tail logs and confirm Doppler injection works

```bash
sudo journalctl -u td-edge -n 50 --no-pager
tail -n 50 /home/td-pi/td-edge/logs/td-edge.log
```

### Expected output
- Service starts cleanly.
- No `Doppler authentication failed` or `403` errors.
- td-edge picks up its env (look for `TD_EDGE_ENVIRONMENT=production` in startup banner if present, or successful sync to td-core).
- Heartbeat to td-core is green within ~60s.

---

## Step 13 — Confirm td-core sees the heartbeat with the NEW prd key

On your laptop:

```bash
gh api repos/tuxedodrive/td-core   # smoke check that gh is alive
# Then in td-core admin / console:
cd ~/workspace/td-core
bin/rails runner '
  d = Device.find_by(slug: "td-edge-jamaica_queens")
  puts "last_heartbeat_at=#{d.last_heartbeat_at}"
  puts "now=#{Time.current}"
  puts "delta=#{(Time.current - d.last_heartbeat_at).to_i}s"
'
```

### Expected output
- `delta` is under 120 seconds.
- If `delta` is large or `last_heartbeat_at` is nil, the new prd API key isn't matching what's in `Device.api_key_digest`. Roll back via Step 16.

---

## Step 14 — Revoke the OLD prd Doppler token

ONLY after Step 13 confirms the new token is working in production.

Doppler dashboard → `td-edge` → **Access** → **Service Tokens** →
find the old token (`dp.st.prd.l3bOaxY6...`) → **Revoke**.

### Expected output
- Old token disappears from the list.
- New token (`metal-pi-prd-2026-04-28`) remains.
- Pi continues running fine for at least 5 minutes after revoke (proving it's using the new token in memory, not re-fetching the old one).

---

## Step 15 — Tick the rotation checklist

Update `td-core/docs/plans/2026-04-28-leaked-keys-rotation.md`:

- [x] Rotate Doppler prd token (#1)
- [x] Rotate TD_EDGE_DEV_API_KEY + TD_EDGE_PRODUCTION_API_KEY (#2 + Gap C)
- [ ] (other items still pending: CarCheck, punxsutawney, GC token, bd tickets, hygiene rules)

Commit the checked boxes with a message like `docs(rotation): mark Doppler prd token + dev/prd API key rotations complete.`

---

## Step 16 — Rollback (only if something went wrong)

If td-edge is broken after the swap:

```bash
sudo systemctl stop td-edge
sudo cp /root/td-edge-rotation-2026-04-28/td-edge.service /etc/systemd/system/td-edge.service
sudo cp -r /root/td-edge-rotation-2026-04-28/td-edge.service.d /etc/systemd/system/ 2>/dev/null || true
sudo rm -f /etc/td-edge/doppler.env
sudo systemctl daemon-reload
sudo systemctl start td-edge
sudo systemctl is-active td-edge
```

### Expected output
- Service back to `active` on the OLD unit.
- The old (leaked) Doppler token is back in argv. Yes, that means we're back
  to leaking — but service availability beats hardening during a rollback.
  Re-attempt the rotation once the failure is understood.

---

## Step 17 — Cleanup (1 day later, if still green)

```bash
sudo rm -rf /root/td-edge-rotation-2026-04-28
```

### Expected output
- Backup directory gone.
- td-edge has been green for 24+ hours on the new unit.

---

## Out of scope for this runbook

- CarCheck API key rotations (#3, #4) — separate flow, doesn't touch systemd.
- Punxsutawney device key (#5) — touches groundhog-day, not metal-pi.
- GC_INSTANCE_TOKEN triage (#6) — JPB's local laptop, no Pi involvement.
- bd tickets for Gaps A–E — file separately after rotation is verified.
- Hygiene rules in mayor agent memory + global CLAUDE.md — separate doc edit.
