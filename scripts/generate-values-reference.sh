#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
CHART_PATH="${REPO_ROOT}/chart"
REFERENCE_PATH="${REPO_ROOT}/docs/configuration/base-config.md"
TEMPLATE_PATH="${REPO_ROOT}/docs/configuration/base-config.md.gotmpl"
MODE=${1:---write}
HELM_DOCS_BIN=${HELM_DOCS_BIN:-helm-docs}

fail() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

if [[ $# -gt 1 || "$MODE" != "--write" && "$MODE" != "--check" ]]; then
  fail "usage: $(basename "$0") [--write|--check]"
fi

command -v "$HELM_DOCS_BIN" >/dev/null 2>&1 \
  || fail "helm-docs v1.14.2 is required; install it or set HELM_DOCS_BIN"

generate() {
  local chart_root=$1
  "$HELM_DOCS_BIN" \
    --chart-search-root "$chart_root" \
    --template-files ../docs/configuration/base-config.md.gotmpl \
    --output-file ../docs/configuration/base-config.md \
    --sort-values-order file \
    --skip-version-footer \
    --log-level warning
}

if [[ "$MODE" == "--check" ]]; then
  TASK_TMP=$(mktemp -d "${TMPDIR:-/tmp}/bigbang-values-reference.XXXXXX")
  cleanup() {
    rm -f "${TASK_TMP}/chart/Chart.yaml" "${TASK_TMP}/chart/values.yaml" \
      "${TASK_TMP}/docs/configuration/base-config.md" \
      "${TASK_TMP}/docs/configuration/base-config.md.gotmpl"
    rmdir "${TASK_TMP}/chart" "${TASK_TMP}/docs/configuration" \
      "${TASK_TMP}/docs" "$TASK_TMP"
  }
  trap cleanup EXIT

  mkdir -p "${TASK_TMP}/chart" "${TASK_TMP}/docs/configuration"
  cp "${CHART_PATH}/Chart.yaml" "${CHART_PATH}/values.yaml" "${TASK_TMP}/chart/"
  cp "$TEMPLATE_PATH" "${TASK_TMP}/docs/configuration/"
  generate "${TASK_TMP}/chart"

  cmp -s "$REFERENCE_PATH" "${TASK_TMP}/docs/configuration/base-config.md" \
    || fail "generated values reference is stale; run scripts/generate-values-reference.sh --write"

  printf '%s\n' 'Generated values reference is up to date.'
else
  generate "$CHART_PATH"
  printf '%s\n' 'Updated docs/configuration/base-config.md.'
fi
