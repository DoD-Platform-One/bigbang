#!/usr/bin/env bash
set -euo pipefail

# Attach closed Renovate issues (strict title match) to a parent epic/work item.
#
# Strict match: title must start with "Renovate:"
# Defaults target:

START_DATE="2026-01-19"
END_DATE="2026-05-01"
GROUP_PATH="big-bang"
EPIC_IID="638"
DRY_RUN="true"

usage() {
  local default_mode
  if [[ "${DRY_RUN}" == "true" ]]; then
    default_mode="dry run"
  else
    default_mode="apply"
  fi

  cat <<EOF
Usage:
  scripts/attach-renovate-issues-to-epic.sh [options]

Options:
  --start-date YYYY-MM-DD   Start date (inclusive) for issue closed_at (current: ${START_DATE})
  --end-date YYYY-MM-DD     End date (inclusive) for issue closed_at (current: ${END_DATE})
  --group PATH              GitLab group path (current: ${GROUP_PATH})
  --epic-iid IID            Parent epic/work item IID (current: ${EPIC_IID})
  --apply                   Apply changes (current: ${default_mode})
  --dry-run                 Dry run mode (current: ${default_mode})
  -h, --help                Show this help text

Examples:
  scripts/attach-renovate-issues-to-epic.sh
  scripts/attach-renovate-issues-to-epic.sh --apply
  scripts/attach-renovate-issues-to-epic.sh --group big-bang --epic-iid 638 --apply
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
  --start-date)
    START_DATE="${2:-}"
    shift 2
    ;;
  --end-date)
    END_DATE="${2:-}"
    shift 2
    ;;
  --group)
    GROUP_PATH="${2:-}"
    shift 2
    ;;
  --epic-iid)
    EPIC_IID="${2:-}"
    shift 2
    ;;
  --apply)
    DRY_RUN="false"
    shift
    ;;
  --dry-run)
    DRY_RUN="true"
    shift
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    echo "Unknown argument: $1" >&2
    usage
    exit 1
    ;;
  esac
done

for cmd in glab jq; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Missing required command: $cmd" >&2
    exit 1
  fi
done

echo "Resolving group: ${GROUP_PATH}"
GROUP_ID="$(glab api "groups/${GROUP_PATH}" | jq -r '.id')"

if [[ -z "${GROUP_ID}" || "${GROUP_ID}" == "null" ]]; then
  echo "Unable to resolve group id for ${GROUP_PATH}" >&2
  exit 1
fi

echo "Group ID: ${GROUP_ID}"
echo "Epic IID: ${EPIC_IID}"
echo "Date range: ${START_DATE} -> ${END_DATE}"
echo "Mode: $([[ "${DRY_RUN}" == "true" ]] && echo "DRY RUN" || echo "APPLY")"
echo

echo "Fetching closed group issues..."
CANDIDATES_JSON="$(
  glab api --paginate "groups/${GROUP_ID}/issues?state=closed&per_page=100" |
    jq -s 'add // []'
)"

MATCHES_JSON="$(
  jq \
    --arg s "${START_DATE}" \
    --arg e "${END_DATE}" \
    '
    map(
      select(.closed_at != null)
      | select(.title | test("^Renovate:"))
      | select((.closed_at[0:10] >= $s) and (.closed_at[0:10] <= $e))
    )
    ' <<<"${CANDIDATES_JSON}"
)"

MATCH_COUNT="$(jq 'length' <<<"${MATCHES_JSON}")"
echo "Matching closed issues: ${MATCH_COUNT}"

if [[ "${MATCH_COUNT}" -eq 0 ]]; then
  echo "No matching issues found."
  exit 0
fi

echo
echo "Fetching issues already attached to epic ${EPIC_IID}..."
EXISTING_JSON="$(
  glab api --paginate "groups/${GROUP_ID}/epics/${EPIC_IID}/issues?per_page=100" |
    jq -s 'add // []'
)"

declare -A ATTACHED_IDS=()
while IFS= read -r id; do
  [[ -n "${id}" ]] && ATTACHED_IDS["${id}"]=1
done < <(jq -r 'map(.id)[]?' <<<"${EXISTING_JSON}")

echo
echo "Planned issue set:"
jq -r '.[] | "- \(.references.full) | \(.web_url) | closed_at=\(.closed_at[0:10])"' <<<"${MATCHES_JSON}"
echo

if [[ "${DRY_RUN}" == "true" ]]; then
  echo "Dry run complete. Use --apply to attach issues."
  exit 0
fi

echo "Applying changes..."
jq -c '.[]' <<<"${MATCHES_JSON}" | while IFS= read -r issue; do
  ISSUE_ID="$(jq -r '.id' <<<"${issue}")"
  ISSUE_URL="$(jq -r '.web_url' <<<"${issue}")"

  if [[ -n "${ATTACHED_IDS[${ISSUE_ID}]:-}" ]]; then
    echo "SKIP (already attached): ${ISSUE_URL}"
    continue
  fi

  if glab api -X POST "groups/${GROUP_ID}/epics/${EPIC_IID}/issues/${ISSUE_ID}" >/dev/null; then
    echo "ATTACHED: ${ISSUE_URL}"
  else
    echo "FAILED: ${ISSUE_URL}"
  fi
done

echo "Done."
