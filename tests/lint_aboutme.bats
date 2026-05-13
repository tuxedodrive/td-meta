# ABOUTME: Bats tests for bin/lint-aboutme: header presence, comment-prefix tolerance, verdict shape.
# ABOUTME: Run with: bats tests/lint_aboutme.bats

setup() {
  REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  LINT="$REPO_ROOT/bin/lint-aboutme"
  TEST_TMP="$(mktemp -d)"
  cd "$TEST_TMP"
  git init -q
  git config user.email test@example.com
  git config user.name 'Test User'
  git commit --allow-empty -q -m 'init'
  cp "$REPO_ROOT/bin/verdict-write" ./verdict-write-helper
  export PATH="$REPO_ROOT/bin:$PATH"
}

teardown() {
  rm -rf "$TEST_TMP"
}

@test "lint-aboutme exists and is executable" {
  [ -x "$LINT" ]
}

@test "passes on a Ruby file with ABOUTME header" {
  cat > good.rb <<'EOF'
# ABOUTME: This is a good ruby file.
# ABOUTME: It has the header on the right lines.
class Foo; end
EOF
  run "$LINT" good.rb
  [ "$status" -eq 0 ]
  [ "$(cat tmp/lint-aboutme/LAST_STATUS)" = "PASSED" ]
}

@test "passes on a JS file with // ABOUTME comment style" {
  cat > good.js <<'EOF'
// ABOUTME: A JS file with the correct header.
// ABOUTME: Line two also says ABOUTME.
console.log('hi');
EOF
  run "$LINT" good.js
  [ "$status" -eq 0 ]
}

@test "fails on a Ruby file missing ABOUTME entirely" {
  cat > bad.rb <<'EOF'
class Foo
end
EOF
  run "$LINT" bad.rb
  [ "$status" -ne 0 ]
  [ "$(cat tmp/lint-aboutme/LAST_STATUS)" = "FAILED" ]
  json_file="$(ls tmp/lint-aboutme/*.json | head -1)"
  jq -e '.findings | length >= 1' "$json_file"
  jq -e '.findings[0].rule == "aboutme-missing"' "$json_file"
  jq -e '.findings[0].file == "bad.rb"' "$json_file"
}

@test "fails on a Ruby file with only one ABOUTME line" {
  cat > onlyone.rb <<'EOF'
# ABOUTME: Just the first line is ABOUTME.
class Foo; end
EOF
  run "$LINT" onlyone.rb
  [ "$status" -ne 0 ]
  json_file="$(ls tmp/lint-aboutme/*.json | head -1)"
  jq -e '.findings[0].rule == "aboutme-incomplete"' "$json_file"
}

@test "skips shebang and treats lines 2-3 as the header location" {
  cat > script.sh <<'EOF'
#!/usr/bin/env bash
# ABOUTME: A shell script with shebang.
# ABOUTME: Header on lines 2-3 is acceptable.
echo hi
EOF
  chmod +x script.sh
  run "$LINT" script.sh
  [ "$status" -eq 0 ]
}

@test "fails on shebang file with no ABOUTME" {
  cat > noheader.sh <<'EOF'
#!/usr/bin/env bash
echo hi
EOF
  run "$LINT" noheader.sh
  [ "$status" -ne 0 ]
}

@test "skips known exempt file types (binary, image)" {
  printf '\x89PNG\r\n\x1a\n' > image.png
  run "$LINT" image.png
  [ "$status" -eq 0 ]
}

@test "skips unknown file types without comment syntax (e.g., .json)" {
  cat > config.json <<'EOF'
{"hello": "world"}
EOF
  run "$LINT" config.json
  [ "$status" -eq 0 ]
}

@test "handles XML/HTML <!-- ABOUTME --> style" {
  cat > page.html <<'EOF'
<!-- ABOUTME: An HTML file with the right header. -->
<!-- ABOUTME: Line two. -->
<html></html>
EOF
  run "$LINT" page.html
  [ "$status" -eq 0 ]
}

@test "exits 2 on usage error when no paths given" {
  run "$LINT"
  [ "$status" -eq 2 ]
}

@test "reads paths from CLAUDE_FILE_PATHS when no argv given" {
  cat > a.rb <<'EOF'
# ABOUTME: line one.
# ABOUTME: line two.
EOF
  cat > b.rb <<'EOF'
class Bare; end
EOF
  run env CLAUDE_FILE_PATHS="a.rb b.rb" "$LINT"
  [ "$status" -ne 0 ]
  json_file="$(ls tmp/lint-aboutme/*.json | head -1)"
  jq -e '.findings | length == 1' "$json_file"
  jq -e '.findings[0].file == "b.rb"' "$json_file"
}

@test "verdict json includes git_sha and command_hash" {
  cat > good.rb <<'EOF'
# ABOUTME: ok.
# ABOUTME: ok.
EOF
  run "$LINT" good.rb
  [ "$status" -eq 0 ]
  json_file="$(ls tmp/lint-aboutme/*.json | head -1)"
  jq -e 'has("git_sha")' "$json_file"
  jq -e 'has("command_hash")' "$json_file"
  jq -e '.command == "lint-aboutme"' "$json_file"
}

@test "skips missing files silently and reports them as a finding" {
  run "$LINT" nope.rb
  [ "$status" -ne 0 ]
  json_file="$(ls tmp/lint-aboutme/*.json | head -1)"
  jq -e '.findings[0].rule == "path-not-found"' "$json_file"
}
