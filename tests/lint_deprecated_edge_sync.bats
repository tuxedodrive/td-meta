# ABOUTME: Bats tests for bin/lint-deprecated-edge-sync: blocks references to retired sync APIs/secrets.
# ABOUTME: Run with: bats tests/lint_deprecated_edge_sync.bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  LINT="$REPO_ROOT/bin/lint-deprecated-edge-sync"
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

@test "lint-deprecated-edge-sync exists and is executable" {
  [ -x "$LINT" ]
}

@test "passes when none of the retired tokens appear" {
  echo "client.sync(payload)" > clean.py
  run "$LINT" clean.py
  [ "$status" -eq 0 ]
  [ "$(cat tmp/lint-deprecated-edge-sync/LAST_STATUS)" = "PASSED" ]
}

@test "fails on sync_visits_multi reference" {
  echo "client.sync_visits_multi(records)" > dirty.py
  run "$LINT" dirty.py
  [ "$status" -ne 0 ]
  json_file="$(ls tmp/lint-deprecated-edge-sync/*.json | head -1)"
  jq -e '.findings[0].rule == "retired-sync-api"' "$json_file"
}

@test "fails on sync_detections_multi reference" {
  echo "client.sync_detections_multi(records)" > dirty.py
  run "$LINT" dirty.py
  [ "$status" -ne 0 ]
}

@test "WARNs (not FAILED) on pi_key in env-var loader context" {
  echo "PI_KEY = os.environ.get('pi_key')" > loader.py
  run "$LINT" loader.py
  [ "$status" -eq 0 ]
  [ "$(cat tmp/lint-deprecated-edge-sync/LAST_STATUS)" = "WARN" ]
  json_file="$(ls tmp/lint-deprecated-edge-sync/*.json | head -1)"
  jq -e '.findings[0].rule == "retired-secret-name"' "$json_file"
}

@test "WARNs on pi_secret as well" {
  echo "secret = config.get('pi_secret')" > sec.py
  run "$LINT" sec.py
  [ "$status" -eq 0 ]
  [ "$(cat tmp/lint-deprecated-edge-sync/LAST_STATUS)" = "WARN" ]
}

@test "skips paths under db/migrate/" {
  mkdir -p db/migrate
  echo "execute 'DROP FUNCTION sync_visits_multi();'" > db/migrate/20260101_drop_sync.rb
  run "$LINT" db/migrate/20260101_drop_sync.rb
  [ "$status" -eq 0 ]
  [ "$(cat tmp/lint-deprecated-edge-sync/LAST_STATUS)" = "PASSED" ]
}

@test "skips tests/ paths" {
  mkdir -p tests
  echo "client.sync_visits_multi(fixture)" > tests/test_legacy.py
  run "$LINT" tests/test_legacy.py
  [ "$status" -eq 0 ]
}

@test "FAILED takes precedence over WARN when both appear" {
  cat > mix.py <<'EOF'
client.sync_visits_multi(records)
secret = os.environ['pi_secret']
EOF
  run "$LINT" mix.py
  [ "$status" -ne 0 ]
  [ "$(cat tmp/lint-deprecated-edge-sync/LAST_STATUS)" = "FAILED" ]
  json_file="$(ls tmp/lint-deprecated-edge-sync/*.json | head -1)"
  jq -e '.findings | length == 2' "$json_file"
}

@test "exits 2 on usage error when no paths given" {
  run "$LINT"
  [ "$status" -eq 2 ]
}

@test "reads paths from CLAUDE_FILE_PATHS when no argv given" {
  echo "x = sync_visits_multi(records)" > dirty.py
  run env CLAUDE_FILE_PATHS="dirty.py" "$LINT"
  [ "$status" -ne 0 ]
}

@test "finding records correct line number" {
  printf 'first line ok\nx = sync_detections_multi()\n' > multi.py
  run "$LINT" multi.py
  [ "$status" -ne 0 ]
  json_file="$(ls tmp/lint-deprecated-edge-sync/*.json | head -1)"
  jq -e '.findings[0].line == 2' "$json_file"
}
