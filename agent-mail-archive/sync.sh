#!/usr/bin/env bash
# ABOUTME: Mirror the live MCP agent-mail mailbox for the /Users/jpb/workspace project_key into snapshot/.
# ABOUTME: One-way rsync with --delete so the snapshot reflects current state; git history is the append-only log.

set -euo pipefail

SRC="$HOME/.mcp_agent_mail_git_mailbox_repo/projects/users-jpb-workspace"
DEST_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST="$DEST_DIR/snapshot"

if [ ! -d "$SRC" ]; then
  echo "ERROR: agent-mail source not found at $SRC" >&2
  echo "       Is the MCP agent-mail server installed at ~/.mcp_agent_mail_git_mailbox_repo?" >&2
  exit 1
fi

mkdir -p "$DEST"

rsync -a --delete \
  --exclude='.git/' \
  "$SRC/" "$DEST/"

echo "Synced $SRC → $DEST"
echo
echo "Next:"
echo "  git -C $(git -C "$DEST_DIR" rev-parse --show-toplevel) add -A agent-mail-archive"
echo "  git -C $(git -C "$DEST_DIR" rev-parse --show-toplevel) commit -m 'archive: snapshot agent-mail state.'"
