# Verdict File Schema (schema_version 1)

Lint formulas across td-* repos emit verdict files via `bin/verdict-write` so
hooks and reviewers can read a single, structured artifact instead of parsing
ad-hoc script output. Verdicts live under `tmp/<formula>/` and are ephemeral:
each run overwrites `LAST_STATUS`; per-run JSON and Markdown files accumulate
under the same directory until the next `rm -rf tmp/`.

## Files written per run

| Path | Purpose |
|------|---------|
| `tmp/<formula>/LAST_STATUS` | one-line `PASSED`, `FAILED`, or `WARN`. Hooks read this for fast gating. |
| `tmp/<formula>/<run-id>.json` | structured verdict for tooling. `<run-id>` is `<iso8601-utc>-<pid>`. |
| `tmp/<formula>/<run-id>.md` | human-readable summary. |

## JSON shape

```json
{
  "schema_version": 1,
  "command": "lint-aboutme",
  "argv": "lint-aboutme src/foo.rb",
  "git_sha": "abc123...",
  "command_hash": "deadbeef...",
  "run_started_at": "2026-05-12T03:14:15Z",
  "run_finished_at": "2026-05-12T03:14:16Z",
  "status": "FAILED",
  "findings": [
    {
      "file": "src/foo.rb",
      "line": 1,
      "rule": "aboutme-missing",
      "fix": "add ABOUTME header to first two lines",
      "reference": "AGENTS.md#aboutme"
    }
  ]
}
```

### Field reference

- `schema_version` (integer, required): currently `1`. Bump on any
  breaking change to consumer-visible field semantics; additive fields do
  not require a bump.
- `command` (string, required): the formula name, e.g. `lint-aboutme`.
- `argv` (string, required): the original argv string (passed via `--argv`,
  or defaulted to the formula name). Used to compute `command_hash`.
- `git_sha` (string, required): output of `git rev-parse HEAD` at write time,
  or `unknown` when not inside a git working tree.
- `command_hash` (string, required): SHA-256 of `argv`. Deterministic per
  invocation shape; lets hooks recognise repeat runs.
- `run_started_at` (string, required): caller-supplied ISO 8601 UTC
  timestamp indicating when the formula began work.
- `run_finished_at` (string, required): set by `bin/verdict-write` itself
  at write time, ISO 8601 UTC.
- `status` (string, required): one of `PASSED`, `FAILED`, `WARN`.
- `findings` (array, required): zero or more finding objects. Empty array
  for `PASSED` is normal.

### Finding shape

Findings are open objects. Recommended keys:

- `file` (string): path the finding refers to.
- `line` (integer): line number, `0` if not applicable.
- `rule` (string): short rule identifier (e.g. `aboutme-missing`).
- `fix` (string): human-readable remediation hint.
- `reference` (string): URL or doc path explaining the rule.

Additional keys are preserved verbatim — formulas may emit extra context
without changing the schema.

## Forgery resistance

The provenance fields (`git_sha`, `command_hash`, `run_started_at`,
`run_finished_at`) let hooks detect `echo PASSED > tmp/<formula>/LAST_STATUS`
forgery: a stale `LAST_STATUS` with no companion JSON, or a JSON whose
`git_sha` does not match `HEAD`, or whose `run_started_at` is older than
the current session, signals tampering. Hooks SHOULD treat missing or
inconsistent provenance as `FAILED`.

## Usage

```bash
# No findings, all clean
bin/verdict-write \
  --formula lint-aboutme \
  --status PASSED \
  --started-at "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# With findings on stdin
jq -n '[{file:"src/a.rb",line:1,rule:"aboutme-missing",fix:"add header",reference:"AGENTS.md"}]' \
  | bin/verdict-write \
      --formula lint-aboutme \
      --status FAILED \
      --started-at "$STARTED_AT" \
      --argv "lint-aboutme src/a.rb"
```
