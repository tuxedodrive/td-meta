#!/usr/bin/env bash
# ABOUTME: One-shot setup for a fresh td-meta clone. Idempotent — re-run any time.
# ABOUTME: Currently: installs the td-dolt-sync launchd agent. Add more steps here.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> td-dolt-sync"
"$SCRIPT_DIR/install-td-dolt-sync"

echo ""
echo "Setup complete."
