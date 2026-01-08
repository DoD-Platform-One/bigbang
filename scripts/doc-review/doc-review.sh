#!/usr/bin/env bash

# Unified script to find old markdown files, create issues, and optionally add them to an epic
# Requires: glab, jq

set -euo pipefail

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Default values
MONTHS_AGO=6
MAX_FILES_ARG="all"
DRY_RUN=false
TEAM_FILTER="all"
EPIC_IID=""
EPIC_GROUP_ID="3988"  # big-bang group ID
MISSION_CHARTER_URL="https://repo1.dso.mil/big-bang/team/team-charter/-/raw/main/data/mission_team_charter.json"
INPUT_FILE=""

# Project/group flags (all false by default, if none specified all are enabled)
SCAN_PACKAGES=false
SCAN_MAINTAINED=false
SCAN_SANDBOX=false
SCAN_UMBRELLA=false

# Commits to ignore when determining file age (e.g., refactor commits)
IGNORE_COMMITS=()

# Function to show usage
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Find old markdown files in BigBang GitLab projects and create issues for review.
The script is idempotent - it will skip creating issues that already exist.

OPTIONS:
    -t, --time MONTHS     Files older than MONTHS (default: 6)
    -c, --count NUMBER    Maximum files to check, or "all" (default: all)
    -i, --input FILE     Use existing scan results JSON (skip Phase 1 scan)
    -d, --dry-run        Dry run mode - shows what would be done without making changes
    --team TEAM          Filter by team (default: all)
    --epic EPIC_IID      Add created issues to specified epic (optional)
    --ignore-commit SHA  Ignore this commit when determining file age (can be used multiple times)
    -h, --help           Show this help message

PROJECT SELECTION (if none specified, all are scanned):
    --packages           Scan big-bang/product/packages
    --maintained         Scan big-bang/product/maintained
    --sandbox            Scan big-bang/apps/sandbox
    --umbrella           Scan big-bang/bigbang (umbrella project)

OUTPUTS:
    old_markdown_*.json      All potentially outdated files found (scan mode only)
    created_issues_*.json    Successfully created issue URLs (real run only)
    failed_issues_*.json     Failed issues for retry (real run only)

EXAMPLES:
    $(basename "$0")                          # Scan all projects, create issues
    $(basename "$0") -d                        # Dry run (preview everything)
    $(basename "$0") --umbrella -d            # Dry run umbrella only
    $(basename "$0") --packages --maintained  # Scan packages and maintained only
    $(basename "$0") -t 12 --epic 495         # 12 months, add to epic 495
    $(basename "$0") --team service_mesh -d   # Dry run for service mesh team
    $(basename "$0") -i old_markdown.json -d  # Dry run using existing scan results
    $(basename "$0") -i old_markdown.json --epic 495  # Create issues from existing scan
EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -t|--time)
            MONTHS_AGO="$2"
            shift 2
            ;;
        -c|--count)
            MAX_FILES_ARG="$2"
            shift 2
            ;;
        -i|--input)
            INPUT_FILE="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        --team)
            TEAM_FILTER="$2"
            shift 2
            ;;
        --epic)
            EPIC_IID="$2"
            shift 2
            ;;
        --ignore-commit)
            IGNORE_COMMITS+=("$2")
            shift 2
            ;;
        --packages)
            SCAN_PACKAGES=true
            shift
            ;;
        --maintained)
            SCAN_MAINTAINED=true
            shift
            ;;
        --sandbox)
            SCAN_SANDBOX=true
            shift
            ;;
        --umbrella)
            SCAN_UMBRELLA=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# If no project flags specified, enable all
if [[ "$SCAN_PACKAGES" == false && "$SCAN_MAINTAINED" == false && "$SCAN_SANDBOX" == false && "$SCAN_UMBRELLA" == false ]]; then
    SCAN_PACKAGES=true
    SCAN_MAINTAINED=true
    SCAN_SANDBOX=true
    SCAN_UMBRELLA=true
fi

# Validate input file if provided
if [[ -n "$INPUT_FILE" ]]; then
    if [[ ! -f "$INPUT_FILE" ]]; then
        echo -e "${RED}Error: Input file does not exist: $INPUT_FILE${NC}"
        exit 1
    fi
    if ! jq empty "$INPUT_FILE" 2>/dev/null; then
        echo -e "${RED}Error: Input file is not valid JSON: $INPUT_FILE${NC}"
        exit 1
    fi
fi

# Handle "all" argument for scanning all files
if [[ "$MAX_FILES_ARG" == "all" || "$MAX_FILES_ARG" == "ALL" ]]; then
    MAX_FILES=99999
else
    MAX_FILES=$MAX_FILES_ARG
fi

# Calculate date threshold (works on both macOS and Linux)
# Test which date command syntax works (GNU vs BSD)
if date -v -1d +%Y-%m-%d >/dev/null 2>&1; then
    # BSD date (macOS)
    date_limit=$(date -v "-${MONTHS_AGO}m" -u +"%Y-%m-%dT%H:%M:%SZ")
    date_limit_short=$(date -v "-${MONTHS_AGO}m" +"%Y-%m-%d")
else
    # GNU date (Linux)
    date_limit=$(date -d "${MONTHS_AGO} months ago" -u +"%Y-%m-%dT%H:%M:%SZ")
    date_limit_short=$(date -d "${MONTHS_AGO} months ago" '+%Y-%m-%d')
fi

# Header
echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║            BigBang Documentation Review Tool                 ║${NC}"
echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Build list of selected projects for display
selected_projects=""
[[ "$SCAN_PACKAGES" == true ]] && selected_projects+="packages "
[[ "$SCAN_MAINTAINED" == true ]] && selected_projects+="maintained "
[[ "$SCAN_SANDBOX" == true ]] && selected_projects+="sandbox "
[[ "$SCAN_UMBRELLA" == true ]] && selected_projects+="umbrella "

# Display settings
echo -e "${CYAN}📋 Settings:${NC}"
if [[ -n "$INPUT_FILE" ]]; then
    echo -e "   • Input: ${BOLD}${CYAN}$INPUT_FILE${NC} (skipping scan)"
else
    echo -e "   • Threshold: Files older than ${BOLD}${YELLOW}${MONTHS_AGO} months${NC} (before ${date_limit_short})"
    if [[ "$MAX_FILES_ARG" == "all" || "$MAX_FILES_ARG" == "ALL" ]]; then
        echo -e "   • Limit: ${BOLD}ALL files${NC}"
    else
        echo -e "   • Limit: ${BOLD}${MAX_FILES} files${NC}"
    fi
    echo -e "   • Projects: ${BOLD}${CYAN}${selected_projects}${NC}"
fi
if [[ "$DRY_RUN" == true ]]; then
    echo -e "   • Mode: ${BOLD}${YELLOW}DRY RUN${NC} (no changes will be made)"
else
    echo -e "   • Mode: ${BOLD}${GREEN}REAL RUN${NC} (issues will be created)"
fi
echo -e "   • Team Filter: ${BOLD}${CYAN}$TEAM_FILTER${NC}"
if [[ -n "$EPIC_IID" ]]; then
    echo -e "   • Epic: ${BOLD}${CYAN}#$EPIC_IID${NC} (issues will be added)"
else
    echo -e "   • Epic: ${DIM}Not specified (issues created without epic)${NC}"
fi
if [[ ${#IGNORE_COMMITS[@]} -gt 0 ]]; then
    echo -e "   • Ignoring commits: ${BOLD}${YELLOW}${IGNORE_COMMITS[*]}${NC}"
fi
echo ""

# Build search groups based on flags
SEARCH_GROUPS=()
[[ "$SCAN_PACKAGES" == true ]] && SEARCH_GROUPS+=("group:big-bang/product/packages")
[[ "$SCAN_MAINTAINED" == true ]] && SEARCH_GROUPS+=("group:big-bang/product/maintained")
[[ "$SCAN_SANDBOX" == true ]] && SEARCH_GROUPS+=("group:big-bang/apps/sandbox")
[[ "$SCAN_UMBRELLA" == true ]] && SEARCH_GROUPS+=("project:big-bang/bigbang")

# Fetch mission team charter for team mapping
echo -e "${CYAN}📥 Fetching team charter...${NC}"
CHARTER_FILE=$(mktemp)

if glab api "projects/big-bang%2Fteam%2Fteam-charter/repository/files/data%2Fmission_team_charter.json/raw?ref=main" > "$CHARTER_FILE" 2>/dev/null; then
    echo -e "${GREEN}✅ Team charter fetched successfully${NC}"
elif curl -s -o "$CHARTER_FILE" "$MISSION_CHARTER_URL"; then
    echo -e "${GREEN}✅ Team charter fetched via curl${NC}"
else
    echo -e "${YELLOW}⚠️  Could not fetch team charter, proceeding without team mapping${NC}"
    echo "{}" > "$CHARTER_FILE"
fi

# Create project-to-team mapping
MAPPING_FILE=$(mktemp)
if jq empty "$CHARTER_FILE" 2>/dev/null; then
    jq -r '
        to_entries | .[] |
        .key as $team |
        .value.label as $label |
        .value.repos | to_entries | .[] |
        "\(.value.id)|\($team)|\($label)|\(.key)"
    ' "$CHARTER_FILE" > "$MAPPING_FILE" 2>/dev/null || true
fi

# Create cache file for project IDs
PROJECT_ID_CACHE=$(mktemp)

# Function to get team label for a project
get_team_label() {
    local project_path="$1"
    local cached_id=$(grep "^$project_path|" "$PROJECT_ID_CACHE" 2>/dev/null | cut -d'|' -f2)

    local project_id
    if [[ -n "$cached_id" ]]; then
        project_id="$cached_id"
    else
        local encoded_path=$(echo "$project_path" | sed 's/\//%2F/g')
        project_id=$(glab api "projects/$encoded_path" 2>/dev/null | jq -r '.id // empty')
        if [[ -n "$project_id" ]]; then
            echo "$project_path|$project_id" >> "$PROJECT_ID_CACHE"
        fi
    fi

    if [[ -z "$project_id" ]]; then
        return 1
    fi

    while IFS='|' read -r id team label proj_name; do
        if [[ "$id" == "$project_id" ]]; then
            if [[ "$TEAM_FILTER" == "all" ]] || [[ "$team" == "$TEAM_FILTER" ]]; then
                echo "$label"
                return 0
            fi
        fi
    done < "$MAPPING_FILE"

    return 1
}

# Cache for default branches
DEFAULT_BRANCH_CACHE=$(mktemp)

# Function to get default branch for a project (cached)
get_default_branch() {
    local project="$1"
    local cached=$(grep "^$project|" "$DEFAULT_BRANCH_CACHE" 2>/dev/null | cut -d'|' -f2)

    if [[ -n "$cached" ]]; then
        echo "$cached"
        return 0
    fi

    local encoded_path=$(echo "$project" | sed 's/\//%2F/g')
    local branch=$(glab api "projects/$encoded_path" 2>/dev/null | jq -r '.default_branch // "main"')

    echo "$project|$branch" >> "$DEFAULT_BRANCH_CACHE"
    echo "$branch"
}

# Function to check if issue already exists
check_existing_issue() {
    local project="$1"
    local issue_title="$2"

    local encoded_path=$(echo "$project" | sed 's/\//%2F/g')
    local existing_issue=$(glab api "projects/$encoded_path/issues?state=opened&per_page=100" 2>/dev/null | \
        jq -r --arg title "$issue_title" '.[] | select(.title == $title) | .iid' | head -1)

    if [[ -n "$existing_issue" ]]; then
        echo "$existing_issue"
        return 0
    fi
    return 1
}

# Function to check if issue is already in epic
check_issue_in_epic() {
    local issue_id="$1"

    if [[ -z "$EPIC_IID" ]]; then
        return 1
    fi

    local existing_issues=$(timeout 10 glab api "groups/$EPIC_GROUP_ID/epics/$EPIC_IID/issues" 2>/dev/null | jq -r '.[].id' 2>/dev/null)

    if echo "$existing_issues" | grep -q "^$issue_id$"; then
        return 0
    fi
    return 1
}

# Function to add issue to epic
add_to_epic() {
    local issue_url="$1"

    if [[ -z "$EPIC_IID" ]]; then
        return 0
    fi

    local project_path=$(echo "$issue_url" | sed 's|https://repo1.dso.mil/||' | sed 's|/-/issues/.*||')
    local issue_iid=$(echo "$issue_url" | sed 's|.*/issues/||')

    local encoded_path=$(echo "$project_path" | sed 's/\//%2F/g')
    local issue_data=$(timeout 10 glab api "projects/$encoded_path/issues/$issue_iid" 2>&1)

    if [[ $? -ne 0 ]]; then
        echo -e "      ${RED}❌ Failed to get issue details for epic${NC}"
        return 1
    fi

    local issue_id=$(echo "$issue_data" | jq -r '.id // empty')
    if [[ -z "$issue_id" ]]; then
        echo -e "      ${RED}❌ Could not extract issue ID${NC}"
        return 1
    fi

    # Check if already in epic
    if check_issue_in_epic "$issue_id"; then
        echo -e "      ${YELLOW}⚠️  Already in epic #$EPIC_IID${NC}"
        return 0
    fi

    local epic_response=$(timeout 10 glab api --method POST "groups/$EPIC_GROUP_ID/epics/$EPIC_IID/issues/$issue_id" 2>&1)

    if [[ $? -eq 0 ]]; then
        echo -e "      ${GREEN}✅ Added to epic #$EPIC_IID${NC}"
        return 0
    else
        echo -e "      ${RED}❌ Failed to add to epic${NC}"
        return 1
    fi
}

# Output files
timestamp=$(date +%Y%m%d_%H%M%S)
OUTPUT_JSON_FILE="created_issues_${timestamp}.json"
FAILURE_JSON_FILE="failed_issues_${timestamp}.json"

# Only create output files if not in dry run mode
if [[ "$DRY_RUN" == false ]]; then
    echo "[]" > "$OUTPUT_JSON_FILE"
    echo "[]" > "$FAILURE_JSON_FILE"
fi

# Statistics
issues_created=0
issues_would_create=0
issues_failed=0
duplicate_issues=0
skipped_team=0
added_to_epic=0
would_add_to_epic=0
already_in_epic=0

# Phase 1: Scan or use input file
if [[ -n "$INPUT_FILE" ]]; then
    # Use provided input file, but filter by selected project flags
    original_count=$(jq 'length' "$INPUT_FILE")

    # Build jq filter based on selected project flags
    jq_filter=""
    [[ "$SCAN_PACKAGES" == true ]] && jq_filter="${jq_filter}(.project | startswith(\"big-bang/product/packages\")) or "
    [[ "$SCAN_MAINTAINED" == true ]] && jq_filter="${jq_filter}(.project | startswith(\"big-bang/product/maintained\")) or "
    [[ "$SCAN_SANDBOX" == true ]] && jq_filter="${jq_filter}(.project | startswith(\"big-bang/apps/sandbox\")) or "
    [[ "$SCAN_UMBRELLA" == true ]] && jq_filter="${jq_filter}(.project == \"big-bang/bigbang\") or "

    # Remove trailing " or " and wrap in select
    jq_filter="${jq_filter% or }"

    # Create filtered results file (also exclude blog/, chart/, adr/ directories)
    results_file="filtered_input_${timestamp}.json"
    jq "[.[] | select($jq_filter) | select(.file_path | test(\"^blog/|/blog/|^chart/|/chart/|/adrs?/|/ADRs?/\") | not)]" "$INPUT_FILE" > "$results_file"
    found_count=$(jq 'length' "$results_file")
    checked_count="N/A"

    echo ""
    echo -e "${BOLD}${GREEN}📥 Using existing scan results: ${NC}${BOLD}$INPUT_FILE${NC}"
    echo -e "   • Files in input: ${BOLD}$original_count${NC}"
    echo -e "   • Files after filtering: ${BOLD}${YELLOW}$found_count${NC} (${selected_projects})"
    echo ""
else
    # Scan for files
    results_file="old_markdown_${timestamp}.json"
    echo "[]" > "$results_file"

    # Counters
    counter_file=$(mktemp)
    echo "0" > "$counter_file"
    found_counter_file=$(mktemp)
    echo "0" > "$found_counter_file"

    echo ""
    echo -e "${BOLD}${GREEN}🔎 Phase 1: Scanning for old markdown files...${NC}"
    echo ""

    # Process each search group
    for item in "${SEARCH_GROUPS[@]}"; do
    # Reset counter for each group (limit applies per-group)
    echo "0" > "$counter_file"

    if [[ "$item" =~ ^group: ]]; then
        search_type="groups"
        search_path="${item#group:}"
        display_type="Group"
    elif [[ "$item" =~ ^project: ]]; then
        search_type="projects"
        search_path="${item#project:}"
        display_type="Project"
    else
        search_type="groups"
        search_path="$item"
        display_type="Group"
    fi

    encoded_path=$(echo -n "$search_path" | sed 's/\//%2F/g')

    echo -e "${BOLD}${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${MAGENTA}📁 ${display_type}: ${CYAN}$search_path${NC}"
    echo -e "${BOLD}${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    page=1
    checked_count=$(cat "$counter_file" 2>/dev/null | tr -d ' \n\r')
    if ! [[ "$checked_count" =~ ^[0-9]+$ ]]; then
        checked_count=0
    fi

    while [[ $checked_count -lt $MAX_FILES ]]; do
        search_results=$(glab api "${search_type}/${encoded_path}/search?scope=blobs&search=extension:md&per_page=100&page=$page" 2>/dev/null || echo "[]")

        result_count=$(jq 'length' <<<"$search_results")
        if [[ "$result_count" -eq 0 ]]; then
            break
        fi

        echo "$search_results" | jq -c '.[]' 2>/dev/null | while read -r blob; do
            checked_count=$(cat "$counter_file" 2>/dev/null | tr -d ' \n\r')
            if ! [[ "$checked_count" =~ ^[0-9]+$ ]]; then
                checked_count=0
            fi

            if [[ $checked_count -ge $MAX_FILES ]]; then
                break
            fi

            if ! echo "$blob" | jq empty 2>/dev/null; then
                continue
            fi

            project_id=$(echo "$blob" | jq -r '.project_id // empty' 2>/dev/null || echo "")
            file_path=$(echo "$blob" | jq -r '.path // empty' 2>/dev/null || echo "")

            if [[ -z "$project_id" || -z "$file_path" ]]; then
                continue
            fi

            if [[ ! "$file_path" =~ \.md$ ]]; then
                continue
            fi

            # Skip chart, blog, and ADR directories
            if [[ "$file_path" =~ ^chart/ || "$file_path" =~ /chart/ ]]; then
                continue
            fi
            if [[ "$file_path" =~ ^blog/ || "$file_path" =~ /blog/ || "$file_path" =~ /adrs?/ || "$file_path" =~ /ADRs?/ ]]; then
                continue
            fi

            ((checked_count++))
            echo "$checked_count" > "$counter_file"

            if [[ $((checked_count % 25)) -eq 0 ]]; then
                echo -e "  ${DIM}[Progress: Checked $checked_count files...]${NC}"
            fi

            file_info=$(glab api "projects/$project_id/repository/files/$(echo -n "$file_path" | jq -sRr @uri)?ref=HEAD" 2>/dev/null || echo "{}")

            if [[ "$file_info" == "{}" || -z "$file_info" ]]; then
                continue
            fi

            last_commit_id=$(echo "$file_info" | jq -r '.last_commit_id // ""')
            if [[ -z "$last_commit_id" ]]; then
                continue
            fi

            # Check if this commit should be ignored (e.g., refactor commits)
            commit_to_use="$last_commit_id"
            if [[ ${#IGNORE_COMMITS[@]} -gt 0 ]]; then
                for ignored in "${IGNORE_COMMITS[@]}"; do
                    if [[ "$last_commit_id" == "$ignored"* || "$ignored" == "$last_commit_id"* ]]; then
                        # Fetch commit history for this file and find the next non-ignored commit
                        encoded_file_path=$(echo -n "$file_path" | jq -sRr @uri)
                        commit_history=$(glab api "projects/$project_id/repository/commits?path=$file_path&per_page=10" 2>/dev/null || echo "[]")

                        # Find first commit not in ignore list
                        while IFS= read -r hist_commit; do
                            hist_id=$(echo "$hist_commit" | jq -r '.id // ""')
                            is_ignored=false
                            for ign in "${IGNORE_COMMITS[@]}"; do
                                if [[ "$hist_id" == "$ign"* || "$ign" == "$hist_id"* ]]; then
                                    is_ignored=true
                                    break
                                fi
                            done
                            if [[ "$is_ignored" == false && -n "$hist_id" ]]; then
                                commit_to_use="$hist_id"
                                break
                            fi
                        done < <(echo "$commit_history" | jq -c '.[]')
                        break
                    fi
                done
            fi

            commit=$(glab api "projects/$project_id/repository/commits/$commit_to_use" 2>/dev/null || echo "{}")
            committed_date=$(echo "$commit" | jq -r '.committed_date // ""')

            if [[ -z "$committed_date" ]]; then
                continue
            fi

            if [[ "$committed_date" < "$date_limit" ]]; then
                project_info=$(glab api "projects/$project_id" 2>/dev/null || echo "{}")
                project_path=$(echo "$project_info" | jq -r '.path_with_namespace // "unknown"')

                # Calculate age (portable: try GNU date first, then BSD)
                commit_date_clean="${committed_date%%.*}"  # Remove fractional seconds
                commit_date_clean="${commit_date_clean//T/ }"  # Replace T with space for GNU date
                if commit_epoch=$(date -d "${committed_date}" +%s 2>/dev/null); then
                    # GNU date worked
                    today_epoch=$(date +%s)
                    age_days=$(( (today_epoch - commit_epoch) / 86400 ))
                elif commit_epoch=$(date -jf "%Y-%m-%dT%H:%M:%S" "${committed_date%%.*}" +%s 2>/dev/null); then
                    # BSD date worked
                    today_epoch=$(date +%s)
                    age_days=$(( (today_epoch - commit_epoch) / 86400 ))
                else
                    # Fallback: estimate from date string (YYYY-MM-DD)
                    age_days=0
                fi

                years=$(( age_days / 365 ))
                remaining_days=$(( age_days % 365 ))
                months=$(( remaining_days / 30 ))
                days=$(( remaining_days % 30 ))

                age_human=""
                if [[ $years -gt 0 ]]; then
                    age_human="${years} year"
                    [[ $years -gt 1 ]] && age_human="${years} years"
                fi
                if [[ $months -gt 0 ]]; then
                    [[ -n "$age_human" ]] && age_human="$age_human "
                    age_human="${age_human}${months} month"
                    [[ $months -gt 1 ]] && age_human="${age_human}s"
                fi
                if [[ $years -eq 0 && $days -gt 0 ]]; then
                    [[ -n "$age_human" ]] && age_human="$age_human "
                    age_human="${age_human}${days} day"
                    [[ $days -gt 1 ]] && age_human="${age_human}s"
                fi
                [[ -z "$age_human" ]] && age_human="$age_days days"

                # Add to results JSON
                echo "{
                    \"project\": \"$project_path\",
                    \"file_path\": \"$file_path\",
                    \"last_modified\": \"$committed_date\",
                    \"age_days\": $age_days,
                    \"age_human\": \"$age_human\"
                }" | jq -s ". + $(cat "$results_file")" > "${results_file}.tmp"
                mv "${results_file}.tmp" "$results_file"

                current_found=$(cat "$found_counter_file" 2>/dev/null | tr -d ' \n\r')
                if ! [[ "$current_found" =~ ^[0-9]+$ ]]; then
                    current_found=0
                fi
                ((current_found++))
                echo "$current_found" > "$found_counter_file"

                # Color code based on age
                if [[ $age_days -gt 730 ]]; then
                    age_color="${RED}"
                elif [[ $age_days -gt 365 ]]; then
                    age_color="${YELLOW}"
                else
                    age_color="${GREEN}"
                fi

                echo -e "  ${GREEN}✓${NC} ${DIM}$project_path/${NC}${BOLD}$file_path${NC}"
                echo -e "    ${DIM}Last modified:${NC} ${committed_date%%T*} ${DIM}(${age_color}$age_human old${DIM})${NC}"
            fi
        done

        ((page++))

        checked_count=$(cat "$counter_file" 2>/dev/null | tr -d ' \n\r')
        if ! [[ "$checked_count" =~ ^[0-9]+$ ]]; then
            checked_count=0
        fi

        if [[ $checked_count -ge $MAX_FILES ]]; then
            break
        fi

        if [[ $page -gt 10 ]]; then
            break
        fi
    done

    done

    # Get final counts
    checked_count=$(cat "$counter_file" 2>/dev/null | tr -d ' \n\r')
    found_count=$(cat "$found_counter_file" 2>/dev/null | tr -d ' \n\r')

    echo ""
    echo -e "${BOLD}${BLUE}📊 Scan Complete:${NC}"
    echo -e "   • Files checked: ${BOLD}$checked_count${NC}"
    echo -e "   • Potentially outdated files found: ${BOLD}${YELLOW}$found_count${NC}"
    echo ""

    if [[ "$found_count" -eq 0 || "$found_count" == "" ]]; then
        echo -e "${GREEN}✅ No outdated markdown files found!${NC}"
        rm -f "$counter_file" "$found_counter_file" "$CHARTER_FILE" "$MAPPING_FILE" "$PROJECT_ID_CACHE"
        rm -f "$results_file" "$OUTPUT_JSON_FILE" "$FAILURE_JSON_FILE"
        exit 0
    fi

    # Sort results by age
    jq 'sort_by(.age_days) | reverse' "$results_file" > "${results_file}.tmp"
    mv "${results_file}.tmp" "$results_file"

    echo -e "${GREEN}✅ Scan results saved to:${NC} ${BOLD}$results_file${NC}"
    echo ""

    # Cleanup scan temp files
    rm -f "$counter_file" "$found_counter_file"
fi

# Check if results file has content
found_count=$(jq 'length' "$results_file" 2>/dev/null || echo "0")
if [[ "$found_count" -eq 0 ]]; then
    echo -e "${GREEN}✅ No outdated markdown files to process!${NC}"
    rm -f "$OUTPUT_JSON_FILE" "$FAILURE_JSON_FILE"
    exit 0
fi

# Phase 2: Create issues
echo -e "${BOLD}${GREEN}🔧 Phase 2: Creating issues...${NC}"
echo -e "${DIM}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Umbrella project constant
UMBRELLA_PROJECT="big-bang/bigbang"

# Function to create a single-file issue (for packages/maintained/sandbox)
create_single_file_issue() {
    local project="$1"
    local file_path="$2"
    local last_modified="$3"
    local age_human="$4"

    # Get team label
    local team_label=$(get_team_label "$project" || echo "")

    # Skip if team doesn't match filter
    if [[ "$TEAM_FILTER" != "all" ]] && [[ -z "$team_label" ]]; then
        ((skipped_team++))
        return
    fi

    echo -e "${BOLD}📄 $project/${NC}${CYAN}$file_path${NC}"
    echo -e "   ${DIM}Age: $age_human${NC}"

    if [[ -n "$team_label" ]]; then
        echo -e "   Team: ${GREEN}$team_label${NC}"
    fi

    local issue_title="Documentation Review Needed for $file_path"

    # Check for existing issue (idempotency check)
    local existing_iid=$(check_existing_issue "$project" "$issue_title" || echo "")

    if [[ -n "$existing_iid" ]]; then
        echo -e "   ${YELLOW}⏭️  Issue already exists: #$existing_iid${NC}"
        ((duplicate_issues++))

        # If epic specified, check if we need to add it
        if [[ -n "$EPIC_IID" ]]; then
            local encoded_path=$(echo "$project" | sed 's/\//%2F/g')
            local issue_data=$(glab api "projects/$encoded_path/issues/$existing_iid" 2>/dev/null || echo "{}")
            local issue_id=$(echo "$issue_data" | jq -r '.id // empty')

            if [[ -n "$issue_id" ]]; then
                if check_issue_in_epic "$issue_id"; then
                    echo -e "      ${DIM}Already in epic #$EPIC_IID${NC}"
                    ((already_in_epic++))
                else
                    if [[ "$DRY_RUN" == true ]]; then
                        echo -e "      ${YELLOW}[DRY RUN]${NC} Would add existing issue to epic #$EPIC_IID"
                        ((would_add_to_epic++))
                    else
                        local issue_url="https://repo1.dso.mil/${project}/-/issues/${existing_iid}"
                        add_to_epic "$issue_url" && ((added_to_epic++))
                    fi
                fi
            fi
        fi
        echo ""
        return
    fi

    # Prepare issue content
    local gitlab_base="https://repo1.dso.mil"
    local default_branch=$(get_default_branch "$project")
    local doc_url="${gitlab_base}/${project}/-/blob/${default_branch}/${file_path}"

    local issue_description="The document [\`$file_path\`]($doc_url) has been identified as being possibly out-of-date.

Please review and ensure this document is up-to-date.

**Last Modified:** $last_modified ($age_human ago)"

    if [[ -n "$EPIC_IID" ]]; then
        issue_description="$issue_description
**Related Epic:** &$EPIC_IID"
    fi

    issue_description="$issue_description

---
*This issue was automatically generated by the documentation review script.*"

    local labels="kind::docs,priority::3"
    if [[ -n "$team_label" ]]; then
        labels="$labels,$team_label"
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "   ${YELLOW}[DRY RUN]${NC} Would create issue:"
        echo -e "      • Title: ${BOLD}$issue_title${NC}"
        echo -e "      • Labels: $labels"
        echo -e "      • Weight: 1"
        if [[ -n "$EPIC_IID" ]]; then
            echo -e "      ${YELLOW}[DRY RUN]${NC} Would add to epic #$EPIC_IID"
            ((would_add_to_epic++))
        fi
        ((issues_would_create++))
    else
        echo -e "   ${DIM}Creating issue...${NC}"

        local issue_output=$(glab issue create \
            --repo "$project" \
            --title "$issue_title" \
            --description "$issue_description" \
            --label "$labels" \
            --weight 1 \
            2>&1)

        if [[ $? -eq 0 ]]; then
            local issue_url=$(echo "$issue_output" | grep -oE 'https://[^ ]+' | head -1)
            [[ -z "$issue_url" ]] && issue_url="$issue_output"

            echo -e "   ${GREEN}✅ Created:${NC} $issue_url"
            ((issues_created++))

            # Add to output JSON
            jq --arg proj "$project" \
               --arg file "$file_path" \
               --arg url "$issue_url" \
               --arg title "$issue_title" \
               '. += [{"project": $proj, "file": $file, "title": $title, "url": $url}]' \
               "$OUTPUT_JSON_FILE" > "${OUTPUT_JSON_FILE}.tmp" && mv "${OUTPUT_JSON_FILE}.tmp" "$OUTPUT_JSON_FILE"

            # Add to epic if specified
            if [[ -n "$EPIC_IID" ]]; then
                if add_to_epic "$issue_url"; then
                    ((added_to_epic++))
                fi
            fi
        else
            echo -e "   ${RED}❌ Failed to create issue${NC}"
            echo -e "   ${DIM}$issue_output${NC}"
            ((issues_failed++))

            jq --arg proj "$project" \
               --arg file "$file_path" \
               --arg error "$issue_output" \
               '. += [{"project": $proj, "file_path": $file, "error": $error}]' \
               "$FAILURE_JSON_FILE" > "${FAILURE_JSON_FILE}.tmp" && mv "${FAILURE_JSON_FILE}.tmp" "$FAILURE_JSON_FILE"
        fi
    fi
    echo ""
}

# Function to create a directory-grouped issue (for umbrella)
create_directory_issue() {
    local project="$1"
    local directory="$2"
    local files_json="$3"

    local file_count=$(echo "$files_json" | jq 'length')

    echo -e "${BOLD}📁 $project/${NC}${CYAN}$directory/${NC} ${DIM}($file_count files)${NC}"

    # Get team label
    local team_label=$(get_team_label "$project" || echo "")

    if [[ -n "$team_label" ]]; then
        echo -e "   Team: ${GREEN}$team_label${NC}"
    fi

    # Skip if team doesn't match filter
    if [[ "$TEAM_FILTER" != "all" ]] && [[ -z "$team_label" ]]; then
        ((skipped_team++))
        return
    fi

    local issue_title="Documentation Review Needed for $directory/"

    # Check for existing issue (idempotency check)
    local existing_iid=$(check_existing_issue "$project" "$issue_title" || echo "")

    if [[ -n "$existing_iid" ]]; then
        echo -e "   ${YELLOW}⏭️  Issue already exists: #$existing_iid${NC}"
        ((duplicate_issues++))

        # If epic specified, check if we need to add it
        if [[ -n "$EPIC_IID" ]]; then
            local encoded_path=$(echo "$project" | sed 's/\//%2F/g')
            local issue_data=$(glab api "projects/$encoded_path/issues/$existing_iid" 2>/dev/null || echo "{}")
            local issue_id=$(echo "$issue_data" | jq -r '.id // empty')

            if [[ -n "$issue_id" ]]; then
                if check_issue_in_epic "$issue_id"; then
                    echo -e "      ${DIM}Already in epic #$EPIC_IID${NC}"
                    ((already_in_epic++))
                else
                    if [[ "$DRY_RUN" == true ]]; then
                        echo -e "      ${YELLOW}[DRY RUN]${NC} Would add existing issue to epic #$EPIC_IID"
                        ((would_add_to_epic++))
                    else
                        local issue_url="https://repo1.dso.mil/${project}/-/issues/${existing_iid}"
                        add_to_epic "$issue_url" && ((added_to_epic++))
                    fi
                fi
            fi
        fi
        echo ""
        return
    fi

    # Build issue description with file list
    local gitlab_base="https://repo1.dso.mil"
    local default_branch=$(get_default_branch "$project")

    local issue_description="The following documents in \`$directory/\` have been identified as being possibly out-of-date.

Please review and ensure these documents are up-to-date.

## Files to Review

"

    # Add each file to the description
    while IFS= read -r file_entry; do
        local fp=$(echo "$file_entry" | jq -r '.file_path')
        local lm=$(echo "$file_entry" | jq -r '.last_modified')
        local ah=$(echo "$file_entry" | jq -r '.age_human')
        local filename=$(basename "$fp")
        local doc_url="${gitlab_base}/${project}/-/blob/${default_branch}/${fp}"

        issue_description="${issue_description}- [ ] [\`$filename\`]($doc_url) - Last modified: ${lm%%T*} ($ah ago)
"
        echo -e "      ${DIM}• $filename ($ah old)${NC}"
    done < <(echo "$files_json" | jq -c '.[]')

    if [[ -n "$EPIC_IID" ]]; then
        issue_description="$issue_description
**Related Epic:** &$EPIC_IID"
    fi

    issue_description="$issue_description

---
*This issue was automatically generated by the documentation review script.*"

    local labels="kind::docs,priority::3"
    if [[ -n "$team_label" ]]; then
        labels="$labels,$team_label"
    fi

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "   ${YELLOW}[DRY RUN]${NC} Would create issue:"
        echo -e "      • Title: ${BOLD}$issue_title${NC}"
        echo -e "      • Labels: $labels"
        echo -e "      • Weight: $file_count"
        if [[ -n "$EPIC_IID" ]]; then
            echo -e "      ${YELLOW}[DRY RUN]${NC} Would add to epic #$EPIC_IID"
            ((would_add_to_epic++))
        fi
        ((issues_would_create++))
    else
        echo -e "   ${DIM}Creating issue...${NC}"

        local issue_output=$(glab issue create \
            --repo "$project" \
            --title "$issue_title" \
            --description "$issue_description" \
            --label "$labels" \
            --weight "$file_count" \
            2>&1)

        if [[ $? -eq 0 ]]; then
            local issue_url=$(echo "$issue_output" | grep -oE 'https://[^ ]+' | head -1)
            [[ -z "$issue_url" ]] && issue_url="$issue_output"

            echo -e "   ${GREEN}✅ Created:${NC} $issue_url"
            ((issues_created++))

            # Add to output JSON
            jq --arg proj "$project" \
               --arg dir "$directory" \
               --arg url "$issue_url" \
               --arg title "$issue_title" \
               --argjson count "$file_count" \
               '. += [{"project": $proj, "directory": $dir, "file_count": $count, "title": $title, "url": $url}]' \
               "$OUTPUT_JSON_FILE" > "${OUTPUT_JSON_FILE}.tmp" && mv "${OUTPUT_JSON_FILE}.tmp" "$OUTPUT_JSON_FILE"

            # Add to epic if specified
            if [[ -n "$EPIC_IID" ]]; then
                if add_to_epic "$issue_url"; then
                    ((added_to_epic++))
                fi
            fi
        else
            echo -e "   ${RED}❌ Failed to create issue${NC}"
            echo -e "   ${DIM}$issue_output${NC}"
            ((issues_failed++))

            jq --arg proj "$project" \
               --arg dir "$directory" \
               --arg error "$issue_output" \
               '. += [{"project": $proj, "directory": $dir, "error": $error}]' \
               "$FAILURE_JSON_FILE" > "${FAILURE_JSON_FILE}.tmp" && mv "${FAILURE_JSON_FILE}.tmp" "$FAILURE_JSON_FILE"
        fi
    fi
    echo ""
}

# Separate umbrella files from other project files
umbrella_files=$(jq --arg proj "$UMBRELLA_PROJECT" '[.[] | select(.project == $proj)]' "$results_file")
other_files=$(jq --arg proj "$UMBRELLA_PROJECT" '[.[] | select(.project != $proj)]' "$results_file")

umbrella_count=$(echo "$umbrella_files" | jq 'length')
other_count=$(echo "$other_files" | jq 'length')

# Process non-umbrella files (1 issue per file)
if [[ "$other_count" -gt 0 ]]; then
    echo -e "${BOLD}${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${MAGENTA}📦 Package/Maintained/Sandbox Projects (1 issue per file)${NC}"
    echo -e "${BOLD}${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    while IFS= read -r file_json; do
        project=$(echo "$file_json" | jq -r '.project')
        file_path=$(echo "$file_json" | jq -r '.file_path')
        last_modified=$(echo "$file_json" | jq -r '.last_modified')
        age_human=$(echo "$file_json" | jq -r '.age_human')

        create_single_file_issue "$project" "$file_path" "$last_modified" "$age_human"
    done < <(echo "$other_files" | jq -c '.[]')
fi

# Process umbrella files (1 issue per directory)
if [[ "$umbrella_count" -gt 0 ]]; then
    echo -e "${BOLD}${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${MAGENTA}📂 Umbrella Project (1 issue per directory)${NC}"
    echo -e "${BOLD}${MAGENTA}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    # Group umbrella files by directory
    directories=$(echo "$umbrella_files" | jq -r '[.[] | .file_path | split("/")[:-1] | join("/")] | unique | .[]')

    while IFS= read -r dir; do
        [[ -z "$dir" ]] && continue

        # Get all files in this directory
        dir_files=$(echo "$umbrella_files" | jq --arg d "$dir" '[.[] | select((.file_path | split("/")[:-1] | join("/")) == $d)]')

        create_directory_issue "$UMBRELLA_PROJECT" "$dir" "$dir_files"
    done <<< "$directories"

    # Handle root-level files (no directory)
    root_files=$(echo "$umbrella_files" | jq '[.[] | select((.file_path | contains("/")) | not)]')
    root_count=$(echo "$root_files" | jq 'length')

    if [[ "$root_count" -gt 0 ]]; then
        # Create individual issues for root-level files
        while IFS= read -r file_json; do
            file_path=$(echo "$file_json" | jq -r '.file_path')
            last_modified=$(echo "$file_json" | jq -r '.last_modified')
            age_human=$(echo "$file_json" | jq -r '.age_human')

            create_single_file_issue "$UMBRELLA_PROJECT" "$file_path" "$last_modified" "$age_human"
        done < <(echo "$root_files" | jq -c '.[]')
    fi
fi

# Cleanup temp files
rm -f "$CHARTER_FILE" "$MAPPING_FILE" "$PROJECT_ID_CACHE" "$DEFAULT_BRANCH_CACHE"
# Clean up filtered input file if we created one
[[ "$results_file" == filtered_input_* ]] && rm -f "$results_file"

# Final Summary
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}                         FINAL SUMMARY                         ${NC}"
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

if [[ -n "$INPUT_FILE" ]]; then
    echo -e "${CYAN}📊 Input Statistics:${NC}"
    echo -e "   • Input file: ${BOLD}$INPUT_FILE${NC}"
    echo -e "   • Files in input: ${BOLD}${YELLOW}$found_count${NC}"
else
    echo -e "${CYAN}📊 Scan Statistics:${NC}"
    echo -e "   • Files scanned: ${BOLD}$checked_count${NC}"
    echo -e "   • Outdated files found: ${BOLD}${YELLOW}$found_count${NC}"
fi
echo ""

echo -e "${CYAN}📋 Issue Statistics:${NC}"
if [[ $skipped_team -gt 0 ]]; then
    echo -e "   • Skipped (team filter): ${BOLD}${YELLOW}$skipped_team${NC}"
fi
echo -e "   • Already existing issues: ${BOLD}${YELLOW}$duplicate_issues${NC}"

if [[ "$DRY_RUN" == true ]]; then
    echo -e "   • Would create: ${BOLD}${YELLOW}$issues_would_create${NC}"
    if [[ -n "$EPIC_IID" ]]; then
        echo ""
        echo -e "${CYAN}📌 Epic Statistics:${NC}"
        echo -e "   • Already in epic #$EPIC_IID: ${BOLD}$already_in_epic${NC}"
        echo -e "   • Would add to epic: ${BOLD}${YELLOW}$would_add_to_epic${NC}"
    fi
    echo ""
    echo -e "${YELLOW}ℹ️  This was a DRY RUN. No changes were made.${NC}"
    echo -e "${DIM}   Run without --dry-run to create issues.${NC}"
else
    echo -e "   • Issues created: ${BOLD}${GREEN}$issues_created${NC}"
    if [[ $issues_failed -gt 0 ]]; then
        echo -e "   • Issues failed: ${BOLD}${RED}$issues_failed${NC}"
    fi
    if [[ -n "$EPIC_IID" ]]; then
        echo ""
        echo -e "${CYAN}📌 Epic Statistics:${NC}"
        echo -e "   • Already in epic #$EPIC_IID: ${BOLD}$already_in_epic${NC}"
        echo -e "   • Added to epic: ${BOLD}${GREEN}$added_to_epic${NC}"
    fi
fi

echo ""

# Output files info
echo -e "${CYAN}📁 Output Files:${NC}"

# Only show scan results if we created them (not when using input file)
if [[ -z "$INPUT_FILE" ]]; then
    echo -e "   • Scan results: ${BOLD}$results_file${NC}"
fi

if [[ "$DRY_RUN" == false ]]; then
    created_count=$(jq 'length' "$OUTPUT_JSON_FILE" 2>/dev/null || echo 0)
    if [[ $created_count -gt 0 ]]; then
        echo -e "   • Created issues: ${BOLD}$OUTPUT_JSON_FILE${NC}"
    else
        rm -f "$OUTPUT_JSON_FILE"
    fi

    failure_count=$(jq 'length' "$FAILURE_JSON_FILE" 2>/dev/null || echo 0)
    if [[ $failure_count -gt 0 ]]; then
        echo -e "   • Failed issues: ${BOLD}$FAILURE_JSON_FILE${NC}"
    else
        rm -f "$FAILURE_JSON_FILE"
    fi
fi

echo ""
echo -e "${GREEN}✅ Done!${NC}"
