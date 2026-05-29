#!/usr/bin/env bash
set -euo pipefail

root="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
status=0

expected_body='Please refer to `AGENTS.md` and treat it as you would treat `CLAUDE.md`.'

while IFS= read -r git_dir; do
  repo="$(dirname "$git_dir")"
  name="$(basename "$repo")"

  if [[ ! -f "$repo/AGENTS.md" ]]; then
    echo "missing AGENTS.md: $name"
    status=1
  fi

  if [[ -f "$repo/CLAUDE.md" ]]; then
    if [[ -L "$repo/CLAUDE.md" ]] && [[ "$(readlink "$repo/CLAUDE.md")" == "AGENTS.md" ]]; then
      continue
    fi

    body="$(tr -d '\r' < "$repo/CLAUDE.md")"
    if [[ "$body" != *"$expected_body"* ]]; then
      echo "CLAUDE.md must only delegate to AGENTS.md: $name"
      status=1
    fi
  fi
done < <(find "$root" -mindepth 2 -maxdepth 2 -name .git -type d | sort)

exit "$status"
