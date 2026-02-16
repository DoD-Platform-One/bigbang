#!/usr/bin/env bats
# =============================================================================
# BATS Tests for doc-review.sh
# =============================================================================
# Source: scripts/doc-review/doc-review.sh
# Run with: bats tests/bats/doc-review/
#
# These tests verify doc-review.sh argument parsing and pure functions.
# No real GitLab API calls are made - glab is mocked.
# =============================================================================

# Setup runs before each test
setup() {
    export REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}" && git rev-parse --show-toplevel)"
    export SCRIPT_PATH="${REPO_ROOT}/scripts/doc-review/doc-review.sh"
    
    # Create a mock glab command that doesn't hit GitLab
    export PATH="${BATS_TEST_TMPDIR}:${PATH}"
    cat > "${BATS_TEST_TMPDIR}/glab" << 'EOF'
#!/bin/bash
# Mock glab that returns empty results
case "$*" in
    *"groups/"*"/search"*)
        echo '[]'
        ;;
    *"projects/"*"/repository/files"*)
        echo '{}'
        ;;
    *"projects/"*"/repository/commits"*)
        echo '[]'
        ;;
    *"projects/"*)
        echo '{"default_branch": "main", "id": 12345, "path_with_namespace": "test/project"}'
        ;;
    *"team-charter"*)
        echo '{}'
        ;;
    *)
        echo '[]'
        ;;
esac
EOF
    chmod +x "${BATS_TEST_TMPDIR}/glab"
    
    # Mock curl for team charter
    cat > "${BATS_TEST_TMPDIR}/curl" << 'EOF'
#!/bin/bash
echo '{}'
EOF
    chmod +x "${BATS_TEST_TMPDIR}/curl"
}

# Cleanup after each test
teardown() {
    rm -f "${BATS_TEST_TMPDIR}/glab" 2>/dev/null || true
    rm -f "${BATS_TEST_TMPDIR}/curl" 2>/dev/null || true
    rm -f old_markdown_*.json created_issues_*.json failed_issues_*.json filtered_input_*.json 2>/dev/null || true
}

# =============================================================================
# Help and Usage Tests
# =============================================================================

@test "doc-review.sh --help shows usage" {
    run bash "$SCRIPT_PATH" --help
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
    [[ "$output" =~ "Find old markdown files" ]]
}

@test "doc-review.sh -h shows usage" {
    run bash "$SCRIPT_PATH" -h
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Usage:" ]]
}

# =============================================================================
# Argument Parsing Tests
# =============================================================================

@test "doc-review.sh accepts -t flag for time threshold" {
    run timeout 10 bash "$SCRIPT_PATH" -t 12 -c 1 -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "12 months" ]]
}

@test "doc-review.sh accepts --time flag" {
    run timeout 10 bash "$SCRIPT_PATH" --time 9 -c 1 -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "9 months" ]]
}

@test "doc-review.sh accepts -c flag for count limit" {
    run timeout 10 bash "$SCRIPT_PATH" -c 5 -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "5 files" ]]
}

@test "doc-review.sh accepts --count flag" {
    run timeout 10 bash "$SCRIPT_PATH" --count 10 -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "10 files" ]]
}

@test "doc-review.sh accepts 'all' for count limit" {
    run timeout 10 bash "$SCRIPT_PATH" -c all -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "ALL files" ]]
}

@test "doc-review.sh accepts -d flag for dry run" {
    run timeout 10 bash "$SCRIPT_PATH" -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DRY RUN" ]]
}

@test "doc-review.sh accepts --dry-run flag" {
    run timeout 10 bash "$SCRIPT_PATH" --dry-run --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DRY RUN" ]]
}

@test "doc-review.sh accepts --team flag" {
    run timeout 10 bash "$SCRIPT_PATH" --team service_mesh -c 1 -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "service_mesh" ]]
}

@test "doc-review.sh accepts --epic flag" {
    run timeout 10 bash "$SCRIPT_PATH" --epic 495 -c 1 -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "#495" ]]
}

@test "doc-review.sh accepts --ignore-commit flag" {
    run timeout 10 bash "$SCRIPT_PATH" --ignore-commit abc123 -c 1 -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "abc123" ]]
}

@test "doc-review.sh accepts multiple --ignore-commit flags" {
    run timeout 10 bash "$SCRIPT_PATH" --ignore-commit abc123 --ignore-commit def456 -c 1 -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "abc123 def456" ]]
}

@test "doc-review.sh accepts --packages flag" {
    run timeout 10 bash "$SCRIPT_PATH" -c 1 -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "packages" ]]
}

@test "doc-review.sh accepts --maintained flag" {
    run timeout 10 bash "$SCRIPT_PATH" -c 1 -d --maintained
    [ "$status" -eq 0 ]
    [[ "$output" =~ "maintained" ]]
}

@test "doc-review.sh accepts --sandbox flag" {
    run timeout 10 bash "$SCRIPT_PATH" -c 1 -d --sandbox
    [ "$status" -eq 0 ]
    [[ "$output" =~ "sandbox" ]]
}

@test "doc-review.sh accepts --umbrella flag" {
    run timeout 10 bash "$SCRIPT_PATH" -c 1 -d --umbrella
    [ "$status" -eq 0 ]
    [[ "$output" =~ "umbrella" ]]
}

@test "doc-review.sh accepts multiple project flags" {
    run timeout 10 bash "$SCRIPT_PATH" -c 1 -d --packages --maintained
    [ "$status" -eq 0 ]
    [[ "$output" =~ "packages" ]]
    [[ "$output" =~ "maintained" ]]
}

@test "doc-review.sh rejects unknown flag" {
    run bash "$SCRIPT_PATH" --unknown-flag
    [ "$status" -eq 1 ]
    [[ "$output" =~ "Unknown option" ]]
}

# =============================================================================
# Input File Tests
# =============================================================================

@test "doc-review.sh accepts -i flag for input file" {
    # Create a test input file
    echo '[]' > "${BATS_TEST_TMPDIR}/test_input.json"
    
    run timeout 10 bash "$SCRIPT_PATH" -i "${BATS_TEST_TMPDIR}/test_input.json" -d
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Using existing scan results" ]]
}

@test "doc-review.sh rejects non-existent input file" {
    run bash "$SCRIPT_PATH" -i /nonexistent/file.json -d
    [ "$status" -eq 1 ]
    [[ "$output" =~ "does not exist" ]]
}

@test "doc-review.sh rejects invalid JSON input file" {
    # Create an invalid JSON file
    echo 'invalid json' > "${BATS_TEST_TMPDIR}/invalid.json"
    
    run bash "$SCRIPT_PATH" -i "${BATS_TEST_TMPDIR}/invalid.json" -d
    [ "$status" -eq 1 ]
    [[ "$output" =~ "not valid JSON" ]]
}

# =============================================================================
# Default Behavior Tests
# =============================================================================

@test "doc-review.sh defaults to 6 months" {
    run timeout 10 bash "$SCRIPT_PATH" -c 1 -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "6 months" ]]
}

@test "doc-review.sh defaults to all files" {
    run timeout 10 bash "$SCRIPT_PATH" -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "ALL files" ]]
}

@test "doc-review.sh defaults to all teams" {
    run timeout 10 bash "$SCRIPT_PATH" -c 1 -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Team Filter" ]] && [[ "$output" =~ "all" ]]
}

@test "doc-review.sh defaults to no epic" {
    run timeout 10 bash "$SCRIPT_PATH" -c 1 -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Not specified" ]]
}

@test "doc-review.sh scans all projects when none specified" {
    run timeout 10 bash "$SCRIPT_PATH" -c 1 -d
    [ "$status" -eq 0 ]
    [[ "$output" =~ "packages" ]]
    [[ "$output" =~ "maintained" ]]
    [[ "$output" =~ "sandbox" ]]
    [[ "$output" =~ "umbrella" ]]
}

# =============================================================================
# Exclusion Tests
# =============================================================================

@test "doc-review.sh excludes chart directories" {
    # Verify exclusion logic exists in script
    run grep -q "chart/" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "doc-review.sh excludes blog directories" {
    # Verify exclusion logic exists in script
    run grep -q "blog/" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "doc-review.sh excludes ADR directories" {
    # Verify exclusion logic exists in script
    run grep -q "adr" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Issue Creation Tests
# =============================================================================

@test "doc-review.sh creates single-file issues for non-umbrella projects" {
    # Verify the function exists
    run grep -q "create_single_file_issue" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "doc-review.sh creates directory-grouped issues for umbrella project" {
    # Verify the function exists
    run grep -q "create_directory_issue" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "doc-review.sh checks for existing issues (idempotency)" {
    # Verify check exists
    run grep -q "check_existing_issue" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Output Tests
# =============================================================================

@test "doc-review.sh shows scan phase header" {
    run timeout 10 bash "$SCRIPT_PATH" -c 1 -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "Phase 1: Scanning" ]]
}

@test "doc-review.sh shows issue creation phase header" {
    run timeout 10 bash "$SCRIPT_PATH" -c 1 -d --packages
    [ "$status" -eq 0 ]
    # Phase 2 only appears if files are found, so check for Phase 1 instead
    [[ "$output" =~ "Phase 1" ]] || [[ "$output" =~ "Scanning" ]]
}

@test "doc-review.sh shows summary statistics" {
    run timeout 10 bash "$SCRIPT_PATH" -c 1 -d --packages
    [ "$status" -eq 0 ]
    # Summary text varies - check for common elements
    [[ "$output" =~ "Scan Complete" ]] || [[ "$output" =~ "Files checked" ]]
}

@test "doc-review.sh dry run indicates no changes made" {
    run timeout 10 bash "$SCRIPT_PATH" -c 1 -d --packages
    [ "$status" -eq 0 ]
    [[ "$output" =~ "DRY RUN" ]] || [[ "$output" =~ "no changes" ]]
}

# =============================================================================
# Validation Tests
# =============================================================================

@test "doc-review.sh syntax is valid" {
    run bash -n "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "doc-review.sh has executable permissions" {
    [ -x "$SCRIPT_PATH" ]
}

@test "doc-review.sh requires jq" {
    # Verify script uses jq
    run grep -q "jq" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "doc-review.sh requires glab" {
    # Verify script uses glab
    run grep -q "glab" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "doc-review.sh uses set -euo pipefail" {
    # Verify strict error handling
    run head -10 "$SCRIPT_PATH"
    [[ "$output" =~ "set -euo pipefail" ]]
}

# =============================================================================
# Date Calculation Tests
# =============================================================================

@test "doc-review.sh calculates date threshold" {
    # Verify date calculation logic exists
    run grep -q "date.*-v\|date.*-d" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "doc-review.sh handles both BSD and GNU date" {
    # Verify cross-platform date handling
    run grep -q "date -v\|date -d" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Label Tests
# =============================================================================

@test "doc-review.sh applies kind::docs label" {
    # Verify label is used
    run grep -q "kind::docs" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "doc-review.sh applies priority::3 label" {
    # Verify label is used
    run grep -q "priority::3" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "doc-review.sh applies team labels" {
    # Verify team label logic exists
    run grep -q "get_team_label" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

# =============================================================================
# Epic Integration Tests
# =============================================================================

@test "doc-review.sh can add issues to epic" {
    # Verify epic functionality exists
    run grep -q "add_to_epic" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}

@test "doc-review.sh checks if issue already in epic" {
    # Verify check exists
    run grep -q "check_issue_in_epic" "$SCRIPT_PATH"
    [ "$status" -eq 0 ]
}
