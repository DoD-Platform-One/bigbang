#!/usr/bin/env bats
# =============================================================================
# BATS Tests for remove-stale.sh
# =============================================================================
# Source: scripts/doc-review/remove-stale.sh
# Run with: bats tests/bats/doc-review/
#
# These tests verify remove-stale.sh argument parsing and logic.
# No real GitLab API calls are made - glab is mocked.
# =============================================================================

# Setup runs before each test
setup() {
    export REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}" && git rev-parse --show-toplevel)"
    export SCRIPT_PATH="${REPO_ROOT}/scripts/doc-review/remove-stale.sh"
    
    # Create a mock glab command that doesn't hit GitLab
    export PATH="${BATS_TEST_TMPDIR}:${PATH}"
    cat > "${BATS_TEST_TMPDIR}/glab" << 'EOF'
#!/bin/bash
# Mock glab that returns empty results
case "$*" in
    *"groups/"*"/projects"*)
        echo '[]'
        ;;
    *"/issues"*)
        echo '[]'
        ;;
    *)
        echo '[]'
        ;;
esac
EOF
    chmod +x "${BATS_TEST_TMPDIR}/glab"
}

# Cleanup after each test
teardown() {
    rm -f "${BATS_TEST_TMPDIR}/glab" 2>/dev/null || true
}

# =============================================================================
# Help and Usage Tests
# =============================================================================

@test "remove-stale.sh --help shows usage" {
    run bash "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Remove stale labels" ]]
}

@test "remove-stale.sh -h shows usage" {
    run bash "$SCRIPT_PATH" -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

# =============================================================================
# Argument Parsing Tests
# =============================================================================

@test "remove-stale.sh accepts -d flag for dry run" {
    run timeout 5 bash "$SCRIPT_PATH" -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DRY RUN" ]]
}

@test "remove-stale.sh accepts --dry-run flag" {
    run timeout 5 bash "$SCRIPT_PATH" --dry-run --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DRY RUN" ]]
}

@test "remove-stale.sh accepts -a flag for all issues" {
    run timeout 5 bash "$SCRIPT_PATH" -a -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "All documentation issues" ]]
}

@test "remove-stale.sh accepts --all flag" {
    run timeout 5 bash "$SCRIPT_PATH" --all -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "All documentation issues" ]]
}

@test "remove-stale.sh accepts -l flag for custom label" {
    run timeout 5 bash "$SCRIPT_PATH" -l "Status::Stale" -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Status::Stale" ]]
}

@test "remove-stale.sh accepts --label flag" {
    run timeout 5 bash "$SCRIPT_PATH" --label "custom-label" -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "custom-label" ]]
}

@test "remove-stale.sh accepts --packages flag" {
    run timeout 5 bash "$SCRIPT_PATH" -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "packages" ]]
}

@test "remove-stale.sh accepts --maintained flag" {
    run timeout 5 bash "$SCRIPT_PATH" -d --maintained
    [ "$status" -eq 0 ]
    [[ "$output" =~ "maintained" ]]
}

@test "remove-stale.sh accepts --sandbox flag" {
    run timeout 5 bash "$SCRIPT_PATH" -d --sandbox
    [ "$status" -eq 0 ]
    [[ "$output" =~ "sandbox" ]]
}

@test "remove-stale.sh accepts --umbrella flag" {
    run timeout 5 bash "$SCRIPT_PATH" -d --umbrella
    [ "$status" -eq 0 ]
    [[ "$output" =~ "umbrella" ]]
}

@test "remove-stale.sh accepts multiple project flags" {
    run timeout 5 bash "$SCRIPT_PATH" -d --packages --maintained
    [ "$status" -eq 0 ]
    [[ "$output" =~ "packages" ]]
    [[ "$output" =~ "maintained" ]]
}

@test "remove-stale.sh rejects unknown flag" {
    run bash "$SCRIPT_PATH" --unknown-flag
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown option" ]]
}

# =============================================================================
# Default Behavior Tests
# =============================================================================

@test "remove-stale.sh defaults to script-created issues only" {
    run timeout 5 bash "$SCRIPT_PATH" -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Script-created issues only" ]]
    [[ "$output" =~ "(default)" ]]
}

@test "remove-stale.sh uses 'stale' label by default" {
    run timeout 5 bash "$SCRIPT_PATH" -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "stale" ]]
}

@test "remove-stale.sh scans all projects when none specified" {
    run timeout 5 bash "$SCRIPT_PATH" -d
    [ "$status" -eq 0 ]
    [[ "$output" =~ "packages" ]]
    [[ "$output" =~ "maintained" ]]
    [[ "$output" =~ "sandbox" ]]
    [[ "$output" =~ "umbrella" ]]
}

# =============================================================================
# Logic Tests (using mock data)
# =============================================================================

@test "remove-stale.sh filters script-created issues by title" {
    # Create a mock glab that returns test data
    cat > "${BATS_TEST_TMPDIR}/glab" << 'EOF'
#!/bin/bash
if [[ "$*" =~ "issues" ]]; then
    cat << 'JSON'
[
  {"iid": 1, "title": "Documentation Review Needed for file1.md", "labels": ["kind::docs", "stale"]},
  {"iid": 2, "title": "Update docs manually", "labels": ["kind::docs", "stale"]},
  {"iid": 3, "title": "Documentation Review Needed for file2.md", "labels": ["kind::docs", "stale"]}
]
JSON
elif [[ "$*" =~ "projects" ]]; then
    echo '[{"path_with_namespace": "test/project"}]'
else
    echo '[]'
fi
EOF
    chmod +x "${BATS_TEST_TMPDIR}/glab"
    
    run timeout 10 bash "$SCRIPT_PATH" -d --packages
    [ "$status" -eq 0 ]
    # Should find 2 script-created issues (not the manual one)
    [[ "$output" =~ "Issue #1:" ]]
    [[ "$output" =~ "Issue #3:" ]]
    [[ ! "$output" =~ "Issue #2:" ]]
}

@test "remove-stale.sh processes all docs issues with -a flag" {
    # Create a mock glab that returns test data
    cat > "${BATS_TEST_TMPDIR}/glab" << 'EOF'
#!/bin/bash
if [[ "$*" =~ "issues" ]]; then
    cat << 'JSON'
[
  {"iid": 1, "title": "Documentation Review Needed for file1.md", "labels": ["kind::docs", "stale"]},
  {"iid": 2, "title": "Update docs manually", "labels": ["kind::docs", "stale"]},
  {"iid": 3, "title": "Documentation Review Needed for file2.md", "labels": ["kind::docs", "stale"]}
]
JSON
elif [[ "$*" =~ "projects" ]]; then
    echo '[{"path_with_namespace": "test/project"}]'
else
    echo '[]'
fi
EOF
    chmod +x "${BATS_TEST_TMPDIR}/glab"
    
    run timeout 10 bash "$SCRIPT_PATH" -a -d --packages
    [ "$status" -eq 0 ]
    # Should find all 3 issues with -a flag
    [[ "$output" =~ "Issue #1:" ]]
    [[ "$output" =~ "Issue #2:" ]]
    [[ "$output" =~ "Issue #3:" ]]
}

# =============================================================================
# Output Tests
# =============================================================================

@test "remove-stale.sh shows summary statistics" {
    run timeout 5 bash "$SCRIPT_PATH" -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "FINAL SUMMARY" ]]
    [[ "$output" =~ "Statistics:" ]]
}

@test "remove-stale.sh dry run indicates no changes made" {
    run timeout 5 bash "$SCRIPT_PATH" -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "This was a DRY RUN" ]]
    [[ "$output" =~ "No changes were made" ]]
}

@test "remove-stale.sh shows project groups being scanned" {
    run timeout 5 bash "$SCRIPT_PATH" -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "big-bang/product/packages" ]]
}

# =============================================================================
# Validation Tests
# =============================================================================

@test "remove-stale.sh syntax is valid" {
    run bash -n "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "remove-stale.sh has executable permissions" {
    [ -x "$SCRIPT_PATH" ]
}

@test "remove-stale.sh requires jq (mock check)" {
    # Verify script would check for jq
    run grep -q "jq" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "remove-stale.sh requires glab (mock check)" {
    # Verify script uses glab
    run grep -q "glab" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}
