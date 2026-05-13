# ABOUTME: Bats tests for bin/lint-td-namespace: detects 'tunnelvision' drift outside allowlisted paths.
# ABOUTME: Run with: bats tests/lint_td_namespace.bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  LINT="$REPO_ROOT/bin/lint-td-namespace"
  TEST_TMP="$(mktemp -d)"
  cd "$TEST_TMP"
  git init -q
  git config user.email test@example.com
  git config user.name 'Test User'
  git commit --allow-empty -q -m 'init'
}

teardown() {
  rm -rf "$TEST_TMP"
}

@test "lint-td-namespace exists and is executable" {
  [ -x "$LINT" ]
}

@test "passes when the word does not appear" {
  echo "TuxedoDrive forever" > clean.rb
  run "$LINT" clean.rb
  [ "$status" -eq 0 ]
  [ "$(cat tmp/lint-td-namespace/LAST_STATUS)" = "PASSED" ]
}

@test "fails when 'tunnelvision' appears in a source file" {
  echo "require 'tunnelvision/foo'" > dirty.rb
  run "$LINT" dirty.rb
  [ "$status" -ne 0 ]
  [ "$(cat tmp/lint-td-namespace/LAST_STATUS)" = "FAILED" ]
  json_file="$(ls tmp/lint-td-namespace/*.json | head -1)"
  jq -e '.findings | length >= 1' "$json_file"
  jq -e '.findings[0].rule == "tunnelvision-reference"' "$json_file"
  jq -e '.findings[0].file == "dirty.rb"' "$json_file"
  jq -e '.findings[0].line == 1' "$json_file"
}

@test "case-insensitive: catches TunnelVision and TUNNELVISION" {
  cat > camel.rb <<'EOF'
class TunnelVision; end
EOF
  cat > shout.rb <<'EOF'
# TUNNELVISION is the old name
EOF
  run "$LINT" camel.rb
  [ "$status" -ne 0 ]
  rm -rf tmp
  run "$LINT" shout.rb
  [ "$status" -ne 0 ]
}

@test "skips paths under archives/" {
  mkdir -p archives/legacy
  echo "tunnelvision lives forever" > archives/legacy/old.rb
  run "$LINT" archives/legacy/old.rb
  [ "$status" -eq 0 ]
}

@test "skips paths under docs/" {
  mkdir -p docs
  echo "Historical mention of tunnelvision is fine in docs" > docs/history.md
  run "$LINT" docs/history.md
  [ "$status" -eq 0 ]
}

@test "flags occurrences across multiple files and lines" {
  echo "tunnelvision" > a.rb
  printf 'first line\nsecond line tunnelvision here\n' > b.rb
  run "$LINT" a.rb b.rb
  [ "$status" -ne 0 ]
  json_file="$(ls tmp/lint-td-namespace/*.json | head -1)"
  jq -e '.findings | length == 2' "$json_file"
  jq -e '.findings | map(.file) | sort == ["a.rb","b.rb"]' "$json_file"
  jq -e '.findings | map(select(.file == "b.rb")) | .[0].line == 2' "$json_file"
}

@test "exits 2 on usage error when no paths given" {
  run "$LINT"
  [ "$status" -eq 2 ]
}

@test "reads paths from CLAUDE_FILE_PATHS when no argv given" {
  echo "tunnelvision" > dirty.rb
  run env CLAUDE_FILE_PATHS="dirty.rb" "$LINT"
  [ "$status" -ne 0 ]
}

@test "handles paths that do not exist as findings, not crashes" {
  run "$LINT" missing.rb
  [ "$status" -ne 0 ]
  json_file="$(ls tmp/lint-td-namespace/*.json | head -1)"
  jq -e '.findings[0].rule == "path-not-found"' "$json_file"
}

@test "matches 'Tunnel_Vision' with underscore" {
  echo "Tunnel_Vision::Config" > snake.rb
  run "$LINT" snake.rb
  [ "$status" -ne 0 ]
}
