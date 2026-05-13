# ABOUTME: Bats tests for bin/verdict-write: shape, provenance, and forgery-detection.
# ABOUTME: Run with: bats tests/verdict_write.bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  VERDICT_WRITE="$REPO_ROOT/bin/verdict-write"
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

@test "verdict-write exists and is executable" {
  [ -x "$VERDICT_WRITE" ]
}

@test "writes LAST_STATUS with the status string" {
  run "$VERDICT_WRITE" --formula lint-demo --status PASSED --started-at 2026-05-12T00:00:00Z
  [ "$status" -eq 0 ]
  [ "$(cat tmp/lint-demo/LAST_STATUS)" = "PASSED" ]
}

@test "writes a JSON file with required schema fields" {
  run "$VERDICT_WRITE" --formula lint-demo --status FAILED --started-at 2026-05-12T00:00:00Z
  [ "$status" -eq 0 ]
  json_file="$(ls tmp/lint-demo/*.json | head -1)"
  [ -f "$json_file" ]
  jq -e '.schema_version == 1' "$json_file"
  jq -e '.status == "FAILED"' "$json_file"
  jq -e '.command == "lint-demo"' "$json_file"
  jq -e 'has("git_sha")' "$json_file"
  jq -e 'has("command_hash")' "$json_file"
  jq -e '.run_started_at == "2026-05-12T00:00:00Z"' "$json_file"
  jq -e 'has("run_finished_at")' "$json_file"
  jq -e '.findings | type == "array"' "$json_file"
}

@test "writes a markdown summary file" {
  run "$VERDICT_WRITE" --formula lint-demo --status WARN --started-at 2026-05-12T00:00:00Z
  [ "$status" -eq 0 ]
  md_file="$(ls tmp/lint-demo/*.md | head -1)"
  [ -f "$md_file" ]
  grep -q "lint-demo" "$md_file"
  grep -q "WARN" "$md_file"
}

@test "rejects unknown status values" {
  run "$VERDICT_WRITE" --formula lint-demo --status BOGUS --started-at 2026-05-12T00:00:00Z
  [ "$status" -ne 0 ]
}

@test "requires --formula" {
  run "$VERDICT_WRITE" --status PASSED --started-at 2026-05-12T00:00:00Z
  [ "$status" -ne 0 ]
}

@test "requires --status" {
  run "$VERDICT_WRITE" --formula lint-demo --started-at 2026-05-12T00:00:00Z
  [ "$status" -ne 0 ]
}

@test "requires --started-at" {
  run "$VERDICT_WRITE" --formula lint-demo --status PASSED
  [ "$status" -ne 0 ]
}

@test "accepts findings JSON array on stdin" {
  findings='[{"file":"a.rb","line":1,"rule":"aboutme-missing","fix":"add ABOUTME header","reference":"AGENTS.md"}]'
  run bash -c "echo '$findings' | '$VERDICT_WRITE' --formula lint-demo --status FAILED --started-at 2026-05-12T00:00:00Z"
  [ "$status" -eq 0 ]
  json_file="$(ls tmp/lint-demo/*.json | head -1)"
  jq -e '.findings | length == 1' "$json_file"
  jq -e '.findings[0].file == "a.rb"' "$json_file"
  jq -e '.findings[0].rule == "aboutme-missing"' "$json_file"
}

@test "rejects malformed stdin JSON" {
  run bash -c "echo 'not json' | '$VERDICT_WRITE' --formula lint-demo --status FAILED --started-at 2026-05-12T00:00:00Z"
  [ "$status" -ne 0 ]
}

@test "rejects findings stdin that isn't an array" {
  run bash -c "echo '{\"not\":\"an array\"}' | '$VERDICT_WRITE' --formula lint-demo --status FAILED --started-at 2026-05-12T00:00:00Z"
  [ "$status" -ne 0 ]
}

@test "git_sha matches HEAD when inside a repo" {
  expected_sha="$(git rev-parse HEAD)"
  run "$VERDICT_WRITE" --formula lint-demo --status PASSED --started-at 2026-05-12T00:00:00Z
  [ "$status" -eq 0 ]
  json_file="$(ls tmp/lint-demo/*.json | head -1)"
  jq -e --arg s "$expected_sha" '.git_sha == $s' "$json_file"
}

@test "command_hash is deterministic across identical runs and differs across distinct argv" {
  "$VERDICT_WRITE" --formula lint-demo --status PASSED --started-at 2026-05-12T00:00:00Z --argv 'lint-demo --foo'
  h1=$(jq -r '.command_hash' tmp/lint-demo/*.json | head -1)
  rm -rf tmp
  "$VERDICT_WRITE" --formula lint-demo --status PASSED --started-at 2026-05-12T00:00:00Z --argv 'lint-demo --foo'
  h2=$(jq -r '.command_hash' tmp/lint-demo/*.json | head -1)
  rm -rf tmp
  "$VERDICT_WRITE" --formula lint-demo --status PASSED --started-at 2026-05-12T00:00:00Z --argv 'lint-demo --bar'
  h3=$(jq -r '.command_hash' tmp/lint-demo/*.json | head -1)
  [ "$h1" = "$h2" ]
  [ "$h1" != "$h3" ]
}

@test "run_finished_at is ISO8601 UTC and after run_started_at" {
  started="2026-05-12T00:00:00Z"
  run "$VERDICT_WRITE" --formula lint-demo --status PASSED --started-at "$started"
  [ "$status" -eq 0 ]
  json_file="$(ls tmp/lint-demo/*.json | head -1)"
  finished=$(jq -r '.run_finished_at' "$json_file")
  [[ "$finished" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}Z$ ]]
}

@test "subsequent run overwrites LAST_STATUS but preserves prior run JSON" {
  "$VERDICT_WRITE" --formula lint-demo --status PASSED --started-at 2026-05-12T00:00:00Z
  sleep 1
  "$VERDICT_WRITE" --formula lint-demo --status FAILED --started-at 2026-05-12T00:00:01Z
  [ "$(cat tmp/lint-demo/LAST_STATUS)" = "FAILED" ]
  count=$(ls tmp/lint-demo/*.json | wc -l | tr -d ' ')
  [ "$count" -eq 2 ]
}
