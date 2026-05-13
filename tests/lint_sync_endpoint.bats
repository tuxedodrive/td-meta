# ABOUTME: Bats tests for bin/lint-sync-endpoint: advisory WARN on direct posts to deprecated edge sync endpoints.
# ABOUTME: Run with: bats tests/lint_sync_endpoint.bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  LINT="$REPO_ROOT/bin/lint-sync-endpoint"
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

@test "lint-sync-endpoint exists and is executable" {
  [ -x "$LINT" ]
}

@test "passes (PASSED) when no deprecated post/put calls appear" {
  echo "client.get('/health')" > clean.py
  run "$LINT" clean.py
  [ "$status" -eq 0 ]
  [ "$(cat tmp/lint-sync-endpoint/LAST_STATUS)" = "PASSED" ]
}

@test "WARNs on requests.post to api/v1/edge_data" {
  echo "requests.post('https://example.com/api/v1/edge_data', json=payload)" > dirty.py
  run "$LINT" dirty.py
  [ "$status" -eq 0 ]
  [ "$(cat tmp/lint-sync-endpoint/LAST_STATUS)" = "WARN" ]
  json_file="$(ls tmp/lint-sync-endpoint/*.json | head -1)"
  jq -e '.status == "WARN"' "$json_file"
  jq -e '.findings | length >= 1' "$json_file"
  jq -e '.findings[0].rule == "deprecated-sync-endpoint"' "$json_file"
}

@test "WARNs on requests.put to ingest/" {
  echo "requests.put('https://example.com/ingest/visits', data=payload)" > dirty.py
  run "$LINT" dirty.py
  [ "$status" -eq 0 ]
  [ "$(cat tmp/lint-sync-endpoint/LAST_STATUS)" = "WARN" ]
}

@test "skips paths under tests/" {
  mkdir -p tests
  echo "requests.post('/api/v1/edge_data')" > tests/test_thing.py
  run "$LINT" tests/test_thing.py
  [ "$status" -eq 0 ]
  [ "$(cat tmp/lint-sync-endpoint/LAST_STATUS)" = "PASSED" ]
}

@test "still PASSES with non-matching post calls" {
  echo "requests.post('https://example.com/api/v2/canonical_sync', json=p)" > new.py
  run "$LINT" new.py
  [ "$status" -eq 0 ]
  [ "$(cat tmp/lint-sync-endpoint/LAST_STATUS)" = "PASSED" ]
}

@test "exits 2 on usage error when no paths given" {
  run "$LINT"
  [ "$status" -eq 2 ]
}

@test "reads paths from CLAUDE_FILE_PATHS when no argv given" {
  echo "requests.post('/api/v1/edge_data', data=p)" > dirty.py
  run env CLAUDE_FILE_PATHS="dirty.py" "$LINT"
  [ "$status" -eq 0 ]
  [ "$(cat tmp/lint-sync-endpoint/LAST_STATUS)" = "WARN" ]
}

@test "finding includes reference field pointing to a contract doc" {
  echo "requests.post('/api/v1/edge_data')" > d.py
  run "$LINT" d.py
  [ "$status" -eq 0 ]
  json_file="$(ls tmp/lint-sync-endpoint/*.json | head -1)"
  jq -e '.findings[0].reference | length > 0' "$json_file"
}

@test "finding records correct line number across multi-line files" {
  printf 'first line ok\nrequests.post("/api/v1/edge_data")\nthird\n' > multi.py
  run "$LINT" multi.py
  [ "$status" -eq 0 ]
  json_file="$(ls tmp/lint-sync-endpoint/*.json | head -1)"
  jq -e '.findings[0].line == 2' "$json_file"
}
