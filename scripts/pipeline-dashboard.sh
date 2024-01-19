#!/bin/bash

# GitLab API Variables
GITLAB_URL="https://repo1.dso.mil"
GITLAB_API_URL="https://repo1.dso.mil/api/v4"
PROJECT_ID=2872
PROJECT_NAME="bigbang"
REPO_NAME="big-bang"
BRANCH="master"

# Function to get pipeline status
get_pipeline_status() {
    pipeline_status=$(curl --silent "${GITLAB_API_URL}/projects/${PROJECT_ID}/pipelines?ref=${BRANCH}" | jq -r '.[0].status')
    echo "${pipeline_status}"
}

# Generate Markdown content
generate_markdown() {
    echo "# GitLab Pipelines Dashboard"
    echo "## Project Overview"
    echo "| Project Name | Pipeline Status |"
    echo "|--------------|------------------|"
    echo "| ${PROJECT_NAME} | ![Pipeline Status](${GITLAB_URL}/${REPO_NAME}/${PROJECT_NAME}/badges/${BRANCH}/pipeline.svg) |"


    # use job name to get job status...getting 401 while trying to get info .. will test
    # job_names=("eks-bigbang-up",)


    # for job_name in "${job_names[@]}"; do
    #     job_status=$(get_job_status "${job_name}")
    #     echo "- [${job_name}](${GITLAB_API_URL}/projects/${PROJECT_ID}/${PROJECT_NAME}/-/jobs/${job_id}): ![Job Status](https://gitlab.com/${PROJECT_ID}/${PROJECT_NAME}/badges/${BRANCH}/job/${job_name}.svg)"
    # done
}

# Execute the script
generate_markdown > generated_dashboard.md

