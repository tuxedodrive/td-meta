ABOUTME: Cross-repo guide for SSH access to td-edge Raspberry Pi devices via Cloudflare Tunnel.
ABOUTME: Covers fleet inventory, SSH commands, live data tunneling, and what each repo needs to know.

# Remote Pi Access

TuxedoDrive runs Raspberry Pi 5 devices at car wash locations running td-edge. All td-* repos may need access for development, debugging, or data collection.

## Fleet Inventory

| Device | Environment | Location | SSH Host |
|--------|-------------|----------|----------|
| metal-pi | staging + production | Advance Car Wash, Jamaica Queens | `ssh-metal-pi.tuxedodrive.dev` |

See `td-tailor/ansible/inventory.yml` for the full fleet inventory.

## SSH Access

Requires `cloudflared` (`brew install cloudflared` on macOS):

```bash
ssh -o ProxyCommand='cloudflared access ssh --hostname %h' td-pi@ssh-metal-pi.tuxedodrive.dev
```

## Live Data Tunnel (td-core)

td-core's `bin/dev` automatically starts a reverse SSH tunnel that routes the Pi's sighting data to your local Rails server on port 3281. The tunnel is defined in `bin/pi-tunnel` and referenced in `Procfile.dev`.

To run the tunnel standalone (without the full dev stack):

```bash
cd ~/workspace/td-core && bin/pi-tunnel
```

When the tunnel is active, td-edge sends sighting data to three targets (configured in `td-edge/config/targets.yaml`):
1. **production** (required) — `api.tuxedodrive.com`
2. **staging** (required) — `api.staging.tuxedodrive.com`
3. **development** (optional, best-effort) — `localhost:3281` via tunnel

## What Each Repo Needs to Know

### td-core
- `bin/dev` starts the Pi tunnel automatically
- Live sightings flow into your local dev database when the tunnel is up
- Use `bin/pi-tunnel` standalone for debugging without the full dev stack

### td-edge
- Source code runs on the Pi at `/home/td-pi/td-edge`
- Logs at `/home/td-pi/td-edge/logs/td-edge.log`
- Process managed by systemd: `sudo systemctl status td-edge`
- Config at `/home/td-pi/td-edge/config/` and Doppler for secrets
- `git pull` on the Pi updates the code; restart the service to apply

### td-tailor
- Ansible playbooks for provisioning and fleet management
- SSH access guide at `docs/SSH_ACCESS_GUIDE.md`
- Cloudflare Tunnel setup at `scripts/setup_cloudflare_tunnel.sh`

### td-training
- Can SSH in to collect sample frames for model training
- Frame buffer and detection data available via td-edge's FastAPI endpoints on port 8001

## Useful td-edge Endpoints (on Pi, port 8001)

| Endpoint | Purpose |
|----------|---------|
| `/health` | Service health check |
| `/detections/live` | Live detection UI |
| `/detections/latest` | JSON feed of recent detections |
| `/cameras/` | Camera status and live frames |
| `/docs` | FastAPI auto-generated docs |
