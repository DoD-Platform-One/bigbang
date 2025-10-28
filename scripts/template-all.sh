#!/usr/bin/env bash

# Big Bang All-in-One Templater
#
# This script templates a Big Bang Helm chart, resolves all GitRepository,
# HelmRepository, and OCIRepository resources, and templates all HelmRelease
# resources with their respective value overlays and post-renderers.
#
# It supports both direct Helm chart templating and post-rendering mode.
#
# Usage:
#   ./scripts/template-all.sh [helm template args...]
#   cat prerendered-templates.yaml | ./scripts/template-all.sh
#   helm template ./chart | ./scripts/template-all.sh
#   helm template ./chart --post-renderer ./scripts/template-all.sh
#
# Options:
#   --debug    Enable debug logging (will also be passed on to Helm template
#              command if templating directly)
#
# Requirements:
#   - helm
#   - git
#   - yq (github.com/mikefarah/yq)
#   - kubectl

set -euo pipefail

debug_mode=false
for arg in "$@"; do
  if [[ "$arg" == "--debug" ]]; then
    debug_mode=true
    break
  fi
done

running_as_postrenderer=false
if [[ $# -eq 0 ]]; then
  running_as_postrenderer=true
fi

b=$(tput setaf 4) # Blue
r=$(tput setaf 1) # Red
y=$(tput setaf 3) # Yellow
n=$(tput sgr0)    # Normal

function info() {
  echo -e "[${b}INFO${n}] $1" >&2
}

function debug() {
  if $debug_mode; then
    echo -e "[${y}DEBUG${n}] $1" >&2
  fi
}

function error() {
  echo -e "[${r}ERROR${n}] $1" >&2
}

log_dir=$(mktemp -d)
error_log="$log_dir/error.log"

trap 'rm -rf "${log_dir}"' EXIT INT TERM

function try() {
  if $debug_mode; then
    "$@" | tee "$error_log"
    if [[ ${PIPESTATUS[0]} -ne 0 ]]; then
      return 1
    fi
    return
  fi
  "$@" 2>"$error_log"
}

function die() {
  error "$1"
  cat "$error_log" >&2
  exit 1
}

big_bang_templates=""

if $running_as_postrenderer; then
  info "Reading Big Bang templates from stdin..."
  big_bang_templates=$(try cat /dev/stdin) || die "Failed to read Big Bang chart from stdin."
else
  info "Templating Big Bang chart with Helm..."
  big_bang_templates=$(try helm template "$@") || die "Failed to template Big Bang chart."
fi

if [[ -z "$big_bang_templates" ]]; then
  die "No templates found in Big Bang chart."
fi

declare git_repos=()
declare helm_repos=()
declare oci_repos=()

mapfile -t git_repos < <(yq -N 'select(.kind == "GitRepository") | .metadata.name' <<<"$big_bang_templates")
mapfile -t helm_repos < <(yq -N 'select(.kind == "HelmRepository") | .metadata.name' <<<"$big_bang_templates")
mapfile -t oci_repos < <(yq -N 'select(.kind == "OCIRepository") | .metadata.name' <<<"$big_bang_templates")

if ((${#git_repos[@]} + ${#helm_repos[@]} + ${#oci_repos[@]} == 0)); then
  info "No repositories defined. Nothing to do."
  info "Outputting original templates."
  printf "%s\n" "$big_bang_templates"
  exit 0
fi

repo_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/big-bang/template-repos"
mkdir -p "$repo_cache_dir"

#shellcheck disable=SC2329 # This is invoked in a subshell via run_with_limit
function fetch_git_repo() {
  local repo_name="$1"
  debug "Resolving GitRepository: $repo_name"
  git_url=$(yq "select(.kind == \"GitRepository\" and .metadata.name == \"$repo_name\") | .spec.url" <<<"$big_bang_templates")

  git_ref_branch=$(yq "select(.kind == \"GitRepository\" and .metadata.name == \"$repo_name\") | .spec.ref.branch" <<<"$big_bang_templates")
  git_ref_tag=$(yq "select(.kind == \"GitRepository\" and .metadata.name == \"$repo_name\") | .spec.ref.tag" <<<"$big_bang_templates")
  git_ref_commit=$(yq "select(.kind == \"GitRepository\" and .metadata.name == \"$repo_name\") | .spec.ref.commit" <<<"$big_bang_templates")

  repo_dir="$repo_cache_dir/$repo_name"
  if [[ ! -d "$repo_dir" ]]; then
    try git clone "$git_url" "$repo_dir" || die "Failed to clone Git repository: $git_url"
  fi

  pushd "$repo_dir" >/dev/null || die "Failed to access repository directory: $repo_dir"
  try git reset --hard || die "Failed to reset repository: $git_url"
  try git fetch --all || die "Failed to fetch updates for repository: $git_url"

  if [[ -n "$git_ref_tag" && "$git_ref_tag" != "null" ]]; then
    try git checkout "tags/$git_ref_tag" || die "Failed to checkout tag '$git_ref_tag' in repository: $git_url"
  elif [[ -n "$git_ref_branch" && "$git_ref_branch" != "null" ]]; then
    try git checkout "$git_ref_branch" || die "Failed to checkout branch '$git_ref_branch' in repository: $git_url"
  elif [[ -n "$git_ref_commit" && "$git_ref_commit" != "null" ]]; then
    try git checkout "$git_ref_commit" || die "Failed to checkout commit '$git_ref_commit' in repository: $git_url"
  else
    die "GitRepository $repo_name has no valid ref (branch, tag, or commit)."
  fi

  echo ".git" >>.helmignore
  popd >/dev/null
}

should_update_helm_repos=false

#shellcheck disable=SC2329 # This is invoked in a subshell via run_with_limit
function fetch_helm_repo() {
  local repo_name="$1" helm_repo helm_repo_url helm_repo_type username password credential_secret secret_namespace docker_config
  debug "Resolving HelmRepository: $repo_name"
  helm_repo=$(yq "select(.kind == \"HelmRepository\" and .metadata.name == \"$repo_name\")" <<<"$big_bang_templates")
  helm_repo_url=$(yq ".spec.url" <<<"$helm_repo")
  helm_repo_type=$(yq ".spec.type" <<<"$helm_repo")

  # Handle classic Helm repo
  if [[ $helm_repo_type == "helm" || -z "$helm_repo_type" || "$helm_repo_type" == "null" ]]; then
    try helm repo add "$repo_name" "$helm_repo_url" || die "Failed to add Helm repository: $helm_repo_url"
    should_update_helm_repos=true
    return
  fi

  # Handle OCI Helm repo
  username=$(yq ".spec.username" <<<"$helm_repo")
  password=$(yq ".spec.password" <<<"$helm_repo")

  credential_secret=$(yq ".spec.secretRef.name" <<<"$helm_repo")
  if [[ -n "$credential_secret" && "$credential_secret" != "null" ]]; then
    secret_namespace=$(yq ".metadata.namespace" <<<"$helm_repo")
    docker_config=$(yq "select(.kind == \"Secret\" and .metadata.name == \"$credential_secret\" and .metadata.namespace == \"$secret_namespace\") | .data.\".dockerconfigjson\"" <<<"$big_bang_templates" | base64 --decode)
    registry_base_domain=$(echo "$helm_repo_url" | cut -d/ -f3) # NOTE: Assuming oci:// prefix. Maybe not always the case?
    username=$(echo "$docker_config" | yq ".auths.\"$registry_base_domain\".username")
    password=$(echo "$docker_config" | yq ".auths.\"$registry_base_domain\".password")
  fi

  debug "Logging into OCI Helm repository: $helm_repo_url"
  if ! try helm registry login -u "$username" -p "$password" "$helm_repo_url"; then
    die "Failed to login to OCI Helm repository: $helm_repo_url"
  fi
}

#shellcheck disable=SC2329 # This is invoked in a subshell via run_with_limit
function fetch_oci_repo() {
  local repo_name="$1"
  debug "Resolving OCIRepository: $repo_name"

  oci_url=$(yq "select(.kind == \"OCIRepository\" and .metadata.name == \"$repo_name\") | .spec.url" <<<"$big_bang_templates")
  oci_ref_tag=$(yq "select(.kind == \"OCIRepository\" and .metadata.name == \"$repo_name\") | .spec.ref.tag" <<<"$big_bang_templates")
  oci_ref_digest=$(yq "select(.kind == \"OCIRepository\" and .metadata.name == \"$repo_name\") | .spec.ref.digest" <<<"$big_bang_templates")

  repo_dir="$repo_cache_dir/$repo_name"
  mkdir -p "$repo_dir"

  if [[ -n "$oci_ref_tag" && "$oci_ref_tag" != "null" ]]; then
    ref_tag="$oci_ref_tag"
  elif [[ -n "$oci_ref_digest" && "$oci_ref_digest" != "null" ]]; then
    ref_tag="$oci_ref_digest"
  else
    die "OCIRepository $repo_name has no valid ref (tag or digest)."
  fi

  debug "Pulling OCI chart from $oci_url (ref: $ref_tag)"
  if ! try helm pull "oci://$oci_url" --version "$oci_ref_tag" --destination "$repo_dir"; then
    die "Failed to pull OCI chart: oci://$oci_url:$oci_ref_tag"
  fi
}

max_jobs=10
declare -a pids
declare -A job_names

function run_with_limit() {
  local name="$1"
  shift
  while (($(jobs -rp | wc -l) >= max_jobs)); do sleep 0.2; done
  {
    "$@" >"$log_dir/${name}.log" 2>&1
  } &
  pid=$!
  job_names["$pid"]="$name"
  pids+=("$pid")
}

function wait_for_jobs() {
  local success=0 fail=0 failed_jobs=()
  local -a log_files=()
  for pid in "${pids[@]}"; do
    if wait "$pid"; then
      ((success++))
    else
      ((fail++))
      failed_jobs+=("${job_names[$pid]}")
    fi
    log_files+=("$log_dir/${job_names[$pid]}.log")
  done

  if $debug_mode; then
    debug "==== Individual Fetch Logs ===="
    for log_file in "${log_files[@]}"; do
      debug "---- Log: $(basename "$log_file") ----"
      >&2 cat "$log_file" || true
    done
  fi

  debug "==== Fetch Summary ===="
  debug "Succeeded: $success"
  debug "Failed:    $fail"

  if ((fail > 0)); then
    error "The following fetches failed:"
    for job in "${failed_jobs[@]}"; do
      error "  - $job:"
      >&2 cat "$log_dir/${job}.log" || true
    done
    return 1
  fi
}

debug "Fetching GitRepositories..."
for git_repo in "${git_repos[@]}"; do
  debug "Scheduling fetch for GitRepository: $git_repo"
  run_with_limit "$git_repo" fetch_git_repo "$git_repo"
done

debug "Fetching HelmRepositories..."
for helm_repo in "${helm_repos[@]}"; do
  debug "Scheduling fetch for HelmRepository: $helm_repo"
  run_with_limit "$helm_repo" fetch_helm_repo "$helm_repo"
done

debug "Fetching OCIRepositories..."
for oci_repo in "${oci_repos[@]}"; do
  debug "Scheduling fetch for OCIRepository: $oci_repo"
  run_with_limit "$oci_repo" fetch_oci_repo "$oci_repo"
done

debug "Waiting for all fetches to complete..."
if ! wait_for_jobs; then
  die "One or more repository fetches failed."
fi

if $should_update_helm_repos; then
  info "Updating Helm repositories..."
  # helm repo update is not thread-safe, so we run it once after adding all repos
  try helm repo update 1>/dev/null || die "Failed to update Helm repositories."
fi

info "All repositories successfully resolved."

declare values_overlays_dir
values_overlays_dir=$(mktemp -d)
trap 'rm -rf "$values_overlays_dir"' EXIT INT TERM

function generate_overlay_files() {
  local release_name="$1"
  local -a values_files

  debug "Resolving values overlays for: $release_name"
  values_secret_names=$(yq "select(.kind == \"HelmRelease\" and .metadata.name == \"$release_name\") | .spec.valuesFrom[].name" <<<"$big_bang_templates")
  values_secret_keys=$(yq "select(.kind == \"HelmRelease\" and .metadata.name == \"$release_name\") | .spec.valuesFrom[].valuesKey" <<<"$big_bang_templates")

  IFS=$'\n' read -rd '' -a names <<<"$values_secret_names" || true
  IFS=$'\n' read -rd '' -a keys <<<"$values_secret_keys" || true

  for i in "${!names[@]}"; do
    secret_name="${names[i]}"
    secret_key="${keys[i]}"

    values=$(yq "select(.kind == \"Secret\" and .metadata.name == \"$secret_name\") | .stringData.\"$secret_key\"" <<<"$big_bang_templates")

    values_filename="$values_overlays_dir/$release_name/$secret_name-$i.yaml"
    mkdir -p "$(dirname "$values_filename")"
    echo "$values" | yq -r . >"$values_filename"
    values_files+=("$values_filename")
  done

  echo "${values_files[@]}"
}

function apply_post_renderers() {
  local templates="$1"
  local post_renderers="$2"

  if [[ -z "$post_renderers" || "$post_renderers" == "null" ]]; then
    debug "No post-renderers to apply."
    echo "$templates"
    return
  fi

  kustomization=$(yq '{
    "resources": ["templates.yaml"],
    "patches": (.[].kustomize.patches // [] | flatten),
    "images": (.[].kustomize.images // [] | flatten)
  }' <<<"$post_renderers")

  debug "Generated kustomization from post-renderers:\n$kustomization"

  kustomize_directory=$(mktemp -d)
  trap 'rm -rf "$kustomize_directory"' EXIT INT TERM

  echo "$kustomization" | yq '.' >"$kustomize_directory/kustomization.yaml"
  echo "$templates" >"$kustomize_directory/templates.yaml"

  kustomize_args=("--load-restrictor=LoadRestrictionsNone")

  debug "Applying post-renderers..."

  if ! post_rendered_templates=$(try kubectl kustomize "${kustomize_args[@]}" "$kustomize_directory"); then
    die "Kustomize post-rendering failed."
  fi

  debug "Post-rendering completed!"
  echo "$post_rendered_templates"
}

function template_helm_release() {
  local release_name="$1"
  debug "Templating HelmRelease: $release_name"

  helm_release=$(yq "select(.kind == \"HelmRelease\" and .metadata.name == \"$release_name\")" <<<"$big_bang_templates")
  helm_chart=$(yq ".spec.chart.spec.chart" <<<"$helm_release")
  helm_chart_version=$(yq ".spec.chart.spec.version" <<<"$helm_release")
  helm_source_name=$(yq ".spec.chart.spec.sourceRef.name" <<<"$helm_release")
  helm_source_kind=$(yq ".spec.chart.spec.sourceRef.kind" <<<"$helm_release")
  target_namespace=$(yq ".spec.targetNamespace" <<<"$helm_release")
  if [[ -z "$target_namespace" || "$target_namespace" == "null" ]]; then
    target_namespace=$(yq ".metadata.namespace" <<<"$helm_release")
  fi

  local -a values_args=("--namespace" "$target_namespace")

  overlay_files=$(try generate_overlay_files "$release_name") || die "Failed to generate value overlays for HelmRelease: $release_name"
  for file in $overlay_files; do
    values_args+=("--values" "$file")
  done

  debug "Applying value overlays: ${values_args[*]}"
  if [[ $helm_source_kind == "HelmRepository" ]]; then
    helm_repo=$(yq "select(.kind == \"HelmRepository\" and .metadata.name == \"$helm_source_name\")" <<<"$big_bang_templates")
    helm_repo_url=$(yq ".spec.url" <<<"$helm_repo")
    helm_repo_type=$(yq ".spec.type" <<<"$helm_repo")

    if [[ $helm_repo_type == "oci" ]]; then
      debug "Using OCI Helm repository: $helm_repo_url"
      if ! release_templates=$(try helm template "$release_name" "$helm_repo_url/$helm_chart" --version "$helm_chart_version" "${values_args[@]}"); then
        die "Failed to template HelmRelease: $release_name"
      fi
    else
      debug "Using classic Helm repository: $helm_repo_url"
      if ! release_templates=$(try helm template "$release_name" "$helm_source_name/$helm_chart" --version "$helm_chart_version" "${values_args[@]}"); then
        die "Failed to template HelmRelease: $release_name"
      fi
    fi
  elif [[ $helm_source_kind == "GitRepository" ]]; then
    repo_dir="$repo_cache_dir/$helm_source_name"
    chart_path=${helm_chart#./}
    if [[ -n "$chart_path" && "$chart_path" != "null" ]]; then
      repo_dir="$repo_dir/$chart_path"
    fi

    debug "Using chart directory: $repo_dir"
    pushd "$repo_dir" >/dev/null || die "Failed to access repository directory: $repo_dir"
    if ! release_templates=$(try helm template . "${values_args[@]}"); then
      die "Failed to template HelmRelease: $release_name"
    fi
    popd >/dev/null
  elif [[ $helm_source_kind == "OCIRepository" ]]; then
    repo_dir="$repo_cache_dir/$helm_source_name"
    chart_file=$(find "$repo_dir" -maxdepth 1 -type f -name "*.tgz" | head -n1)
    if [[ -z "$chart_file" ]]; then
      die "No chart archive found for OCIRepository: $helm_source_name"
    fi

    debug "Using OCI chart archive: $chart_file"
    if ! release_templates=$(try helm template "$release_name" "$chart_file" "${values_args[@]}"); then
      die "Failed to template HelmRelease: $release_name"
    fi
  else
    die "Unsupported source kind '$helm_source_kind' for HelmRelease: $release_name"
  fi

  post_renderers=$(yq ".spec.postRenderers" <<<"$helm_release")
  if ! release_templates=$(apply_post_renderers "$release_templates" "$post_renderers"); then
    die "Failed to apply post-renderers for HelmRelease: $release_name"
  fi

  echo "$release_templates"
}

all_package_templates=""
all_helm_releases=()

mapfile -t all_helm_releases < <(yq -N 'select(.kind == "HelmRelease") | .metadata.name' <<<"$big_bang_templates")
for ((i = 0; i < ${#all_helm_releases[@]}; i++)); do
  helm_release="${all_helm_releases[i]}"
  debug "$(printf "Processing HelmRelease %d/%d: %s" $((i + 1)) "${#all_helm_releases[@]}" "$helm_release")"
  package_templates=$(template_helm_release "$helm_release")
  all_package_templates+=$(printf "\n---\n%s" "$package_templates")
done

info "Templating completed successfully."

completed_templates=$(printf "%s\n%s" "$big_bang_templates" "$all_package_templates")

echo "$completed_templates"
