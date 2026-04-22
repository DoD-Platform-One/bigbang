#!/usr/bin/env bash

# Script to remove stale labels from documentation review issues
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
DRY_RUN=false
STALE_LABEL="stale"
SCRIPT_CREATED_ONLY=true  # Default to script-created issues only

# Project/group flags (all false by default, if none specified all are enabled)
SCAN_PACKAGES=false
SCAN_MAINTAINED=false
SCAN_SANDBOX=false
SCAN_UMBRELLA=false

# Function to show usage
usage() {
    cat << EOF
Usage: $(basename "$0") [OPTIONS]

Remove stale labels from documentation review issues in BigBang GitLab projects.
Searches for issues with "kind::docs" label and removes the "stale" label.

OPTIONS:
    -d, --dry-run        Dry run mode - shows what would be done without making changes
    -l, --label LABEL    Stale label to remove (default: "stale")
    -a, --all            Process ALL documentation issues (not just script-created)
    -h, --help           Show this help message

BEHAVIOR:
    By default, only processes issues created by doc-review.sh script
    (identified by title "Documentation Review Needed for").
    Use -a/--all to process all documentation issues with kind::docs label.

PROJECT SELECTION (if none specified, all are scanned):
    --packages           Scan big-bang/product/packages
    --maintained         Scan big-bang/product/maintained
    --sandbox            Scan big-bang/apps/sandbox
    --umbrella           Scan big-bang/bigbang (umbrella project)

EXAMPLES:
    $(basename "$0") -d                        # Dry run (preview script-created issues)
    $(basename "$0")                          # Remove stale labels from script-created issues
    $(basename "$0") -a                       # Remove stale labels from ALL docs issues
    $(basename "$0") -a -d                    # Dry run for all docs issues
    $(basename "$0") --umbrella -d            # Dry run umbrella only (script-created)
    $(basename "$0") --packages --maintained  # Remove stale from packages/maintained (script-created)
    $(basename "$0") -l "Status::Stale" -d    # Use custom stale label
EOF
    exit 0
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -l|--label)
            STALE_LABEL="$2"
            shift 2
            ;;
        -a|--all)
            SCRIPT_CREATED_ONLY=false
            shift
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

# Header
echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}${BLUE}║        BigBang Documentation Stale Label Remover            ║${NC}"
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
echo -e "   • Stale label: ${BOLD}${YELLOW}$STALE_LABEL${NC}"
echo -e "   • Projects: ${BOLD}${CYAN}${selected_projects}${NC}"
if [[ "$SCRIPT_CREATED_ONLY" == false ]]; then
    echo -e "   • Filter: ${BOLD}${YELLOW}All documentation issues${NC}"
else
    echo -e "   • Filter: ${BOLD}${CYAN}Script-created issues only${NC} ${DIM}(default)${NC}"
fi
if [[ "$DRY_RUN" == true ]]; then
    echo -e "   • Mode: ${BOLD}${YELLOW}DRY RUN${NC} (no changes will be made)"
else
    echo -e "   • Mode: ${BOLD}${GREEN}REAL RUN${NC} (stale labels will be removed)"
fi
echo ""

# Build search groups based on flags
SEARCH_GROUPS=()
[[ "$SCAN_PACKAGES" == true ]] && SEARCH_GROUPS+=("group:big-bang/product/packages")
[[ "$SCAN_MAINTAINED" == true ]] && SEARCH_GROUPS+=("group:big-bang/product/maintained")
[[ "$SCAN_SANDBOX" == true ]] && SEARCH_GROUPS+=("group:big-bang/apps/sandbox")
[[ "$SCAN_UMBRELLA" == true ]] && SEARCH_GROUPS+=("project:big-bang/bigbang")

# Statistics
total_checked=0
stale_found=0
stale_removed=0
stale_would_remove=0
stale_failed=0

# Function to remove stale label from an issue
remove_stale_label() {
    local project_path="$1"
    local issue_iid="$2"
    local issue_title="$3"
    local current_labels="$4"

    echo -e "${BOLD}Issue #$issue_iid:${NC} ${CYAN}$issue_title${NC}"
    echo -e "   Project: ${DIM}$project_path${NC}"

    if [[ "$DRY_RUN" == true ]]; then
        echo -e "   ${YELLOW}[DRY RUN]${NC} Would remove label: ${BOLD}$STALE_LABEL${NC}"
        stale_would_remove=$((stale_would_remove + 1))
    else
        # Remove the stale label from the list
        local new_labels=$(echo "$current_labels" | jq -r --arg stale "$STALE_LABEL" 'map(select(. != $stale)) | join(",")')

        local encoded_path=$(echo "$project_path" | sed 's/\//%2F/g')
        local result=$(glab api --method PUT "projects/$encoded_path/issues/$issue_iid" \
            --field "labels=$new_labels" 2>&1)

        if [[ $? -eq 0 ]]; then
            echo -e "   ${GREEN}✅ Removed label: $STALE_LABEL${NC}"
            stale_removed=$((stale_removed + 1))
        else
            echo -e "   ${RED}❌ Failed to remove label${NC}"
            echo -e "   ${DIM}$result${NC}"
            stale_failed=$((stale_failed + 1))
        fi
    fi
    echo ""
}

# Function to process issues in a project
process_project_issues() {
    local project_path="$1"
    
    proj_encoded=$(echo "$project_path" | sed 's/\//%2F/g')
    
    # Search for open issues with both kind::docs and stale labels
    issues=$(glab api "projects/$proj_encoded/issues?state=opened&labels=kind::docs,$STALE_LABEL&per_page=100" 2>/dev/null || echo "[]")
    
    # Filter by script-created issues if flag is set
    if [[ "$SCRIPT_CREATED_ONLY" == true ]]; then
        issues=$(echo "$issues" | jq '[.[] | select(.title | startswith("Documentation Review Needed for"))]')
    fi
    
    issue_count=$(echo "$issues" | jq 'length')
    total_checked=$((total_checked + issue_count))
    
    if [[ "$issue_count" -gt 0 ]]; then
        stale_found=$((stale_found + issue_count))
        
        # Process each issue
        while IFS= read -r issue; do
            iid=$(echo "$issue" | jq -r '.iid')
            title=$(echo "$issue" | jq -r '.title')
            labels=$(echo "$issue" | jq -r '.labels')
            
            remove_stale_label "$project_path" "$iid" "$title" "$labels"
        done < <(echo "$issues" | jq -c '.[]')
    fi
}

# Process each search group
echo -e "${BOLD}${GREEN}🔎 Searching for documentation issues with stale labels...${NC}"
echo ""

for item in "${SEARCH_GROUPS[@]}"; do
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
    echo ""

    # For groups, we need to get all projects in the group
    if [[ "$search_type" == "groups" ]]; then
        # Get all projects in the group
        projects=$(glab api "${search_type}/${encoded_path}/projects?per_page=100" 2>/dev/null | jq -r '.[].path_with_namespace' || echo "")
        
        if [[ -z "$projects" ]]; then
            echo -e "${DIM}No projects found in this group${NC}"
            echo ""
            continue
        fi

        # Search issues in each project
        while IFS= read -r project_path; do
            [[ -z "$project_path" ]] && continue
            process_project_issues "$project_path"
        done <<< "$projects"
        
        if [[ "$stale_found" -eq 0 ]]; then
            echo -e "${GREEN}✅ No stale documentation issues found${NC}"
            echo ""
        fi
    else
        # For single project, search directly
        process_project_issues "$search_path"
        
        if [[ "$stale_found" -eq 0 ]]; then
            echo -e "${GREEN}✅ No stale documentation issues found${NC}"
            echo ""
        fi
    fi
done

# Final Summary
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}${GREEN}                         FINAL SUMMARY                         ${NC}"
echo -e "${BOLD}${GREEN}═══════════════════════════════════════════════════════════════${NC}"
echo ""

echo -e "${CYAN}📊 Statistics:${NC}"
echo -e "   • Documentation issues with stale label: ${BOLD}${YELLOW}$stale_found${NC}"

if [[ "$DRY_RUN" == true ]]; then
    echo -e "   • Would remove stale label: ${BOLD}${YELLOW}$stale_would_remove${NC}"
    echo ""
    echo -e "${YELLOW}ℹ️  This was a DRY RUN. No changes were made.${NC}"
    echo -e "${DIM}   Run without --dry-run to remove stale labels.${NC}"
else
    echo -e "   • Stale labels removed: ${BOLD}${GREEN}$stale_removed${NC}"
    if [[ $stale_failed -gt 0 ]]; then
        echo -e "   • Failed removals: ${BOLD}${RED}$stale_failed${NC}"
    fi
fi

echo ""
echo -e "${GREEN}✅ Done!${NC}"
