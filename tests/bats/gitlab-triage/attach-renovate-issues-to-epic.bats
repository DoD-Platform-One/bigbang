#!/usr/bin/env bats
# =============================================================================
# BATS Tests for attach-renovate-issues-to-epic.sh
# =============================================================================
# Source: scripts/gitlab-triage/attach-renovate-issues-to-epic.sh
# Run with: bats tests/bats/doc-review/
# =============================================================================

setup() {
  export REPO_ROOT
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}" && git rev-parse --show-toplevel)"
  export SCRIPT_PATH="${REPO_ROOT}/scripts/gitlab-triage/attach-renovate-issues-to-epic.sh"

  export MOCK_POST_CALLS_FILE="${BATS_TEST_TMPDIR}/mock_post_calls.txt"
  : > "${MOCK_POST_CALLS_FILE}"

  export PATH="${BATS_TEST_TMPDIR}:${PATH}"
  cat > "${BATS_TEST_TMPDIR}/glab" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

cmd="${1:-}"
if [[ "$cmd" != "api" ]]; then
  echo "Unsupported mock command: $*" >&2
  exit 1
fi
shift

paginate="false"
if [[ "${1:-}" == "--paginate" ]]; then
  paginate="true"
  shift
fi

method="GET"
if [[ "${1:-}" == "-X" ]]; then
  method="${2:-GET}"
  shift 2
fi

endpoint="${1:-}"

if [[ "$method" == "POST" && "$endpoint" == groups/*/epics/*/issues/* ]]; then
  printf "%s\n" "$endpoint" >> "${MOCK_POST_CALLS_FILE}"
  if [[ "${MOCK_FAIL_POST:-false}" == "true" ]]; then
    exit 1
  fi
  echo '{}'
  exit 0
fi

if [[ "$endpoint" == groups/* && "$endpoint" != */issues* && "$endpoint" != */epics/* ]]; then
  printf '%s\n' "${MOCK_GROUP_JSON:-{\"id\":3988}}"
  exit 0
fi

if [[ "$endpoint" == groups/*/issues\?state=closed\&per_page=100 ]]; then
  printf '%s\n' "${MOCK_ISSUES_JSON:-[]}"
  exit 0
fi

if [[ "$endpoint" == groups/*/epics/*/issues\?per_page=100 ]]; then
  printf '%s\n' "${MOCK_EPIC_ISSUES_JSON:-[]}"
  exit 0
fi

echo '[]'
EOF
  chmod +x "${BATS_TEST_TMPDIR}/glab"
}

teardown() {
  rm -f "${BATS_TEST_TMPDIR}/glab" 2>/dev/null || true
}

@test "attach script --help shows usage and defaults" {
  run bash "$SCRIPT_PATH" --help
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Usage:" ]]
  [[ "$output" =~ "--start-date" ]]
  [[ "$output" =~ "2026-01-19" ]]
  [[ "$output" =~ "--epic-iid" ]]
}

@test "attach script defaults to dry run and exits when no matches" {
  export MOCK_ISSUES_JSON='[]'
  export MOCK_EPIC_ISSUES_JSON='[]'

  run bash "$SCRIPT_PATH"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Mode: DRY RUN" ]]
  [[ "$output" =~ "Matching closed issues: 0" ]]
  [[ "$output" =~ "No matching issues found." ]]
}

@test "attach script only matches strict Renovate: titles in date range" {
  export MOCK_ISSUES_JSON='[
    {"id": 1, "title": "Renovate: Upgrade foo", "closed_at": "2026-02-02T01:00:00Z", "web_url": "https://example/1", "references": {"full": "g/p#1"}},
    {"id": 2, "title": "renovate: lowercase", "closed_at": "2026-03-01T01:00:00Z", "web_url": "https://example/2", "references": {"full": "g/p#2"}},
    {"id": 3, "title": "Renovate update without colon", "closed_at": "2026-03-01T01:00:00Z", "web_url": "https://example/3", "references": {"full": "g/p#3"}},
    {"id": 4, "title": "Renovate: Too early", "closed_at": "2026-01-18T23:59:59Z", "web_url": "https://example/4", "references": {"full": "g/p#4"}}
  ]'
  export MOCK_EPIC_ISSUES_JSON='[]'

  run bash "$SCRIPT_PATH" --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" =~ "Matching closed issues: 1" ]]
  [[ "$output" =~ "https://example/1" ]]
  [[ ! "$output" =~ "https://example/2" ]]
  [[ ! "$output" =~ "https://example/3" ]]
  [[ ! "$output" =~ "https://example/4" ]]
}

@test "attach script in apply mode attaches only issues not already in epic" {
  export MOCK_ISSUES_JSON='[
    {"id": 11, "title": "Renovate: Upgrade alpha", "closed_at": "2026-03-10T01:00:00Z", "web_url": "https://example/11", "references": {"full": "g/p#11"}},
    {"id": 22, "title": "Renovate: Upgrade beta", "closed_at": "2026-03-11T01:00:00Z", "web_url": "https://example/22", "references": {"full": "g/p#22"}}
  ]'
  export MOCK_EPIC_ISSUES_JSON='[
    {"id": 11}
  ]'

  run bash "$SCRIPT_PATH" --apply
  [ "$status" -eq 0 ]
  [[ "$output" == *"SKIP (already attached): https://example/11"* ]]
  [[ "$output" == *"ATTACHED: https://example/22"* ]]

  run cat "$MOCK_POST_CALLS_FILE"
  [ "$status" -eq 0 ]
  [[ "$output" =~ "/issues/22" ]]
  [[ ! "$output" =~ "/issues/11" ]]
}

@test "attach script rejects unknown arguments" {
  run bash "$SCRIPT_PATH" --wat
  [ "$status" -eq 1 ]
  [[ "$output" =~ "Unknown argument" ]]
}
