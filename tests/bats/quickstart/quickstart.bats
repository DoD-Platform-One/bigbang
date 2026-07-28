#!/usr/bin/env bats
# =============================================================================
# BATS Tests for quickstart.sh
# =============================================================================
# Source: docs/reference/scripts/quickstart.sh
# Run with: bats tests/bats/quickstart/
#
# These tests verify quickstart.sh argument parsing, pure helpers, and workflow
# orchestration. No real Git, AWS, Helm, Flux, or Kubernetes calls are made.
# =============================================================================

setup() {
    export REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}" && git rev-parse --show-toplevel)"
    export SCRIPT_PATH="${REPO_ROOT}/docs/reference/scripts/quickstart.sh"
}

_source_quickstart() {
    source "${SCRIPT_PATH}"
}

_reset_quickstart_globals() {
    arg_host=""
    arg_privateip=""
    arg_username=""
    arg_keyfile=""
    arg_version=""
    arg_pipeline_templates_version=master
    arg_repolocation="${REPO1_LOCATION:-}"
    arg_registry1_username="${REGISTRY1_USERNAME:-}"
    arg_registry1_token="${REGISTRY1_TOKEN:-}"
    arg_cloud_provider=aws
    arg_metallb=false
    arg_provision=false
    arg_deploy=false
    arg_wait=false
    arg_destroy=false
    arg_recreate_k3d=false
    arg_recreate_cloud=false
    arg_argv=()
}

_mock_quickstart_workflow() {
    checkout_bigbang_repo() { printf 'checkout_bigbang_repo\n' >> "${QUICKSTART_LOG}"; }
    checkout_pipeline_templates() { printf 'checkout_pipeline_templates\n' >> "${QUICKSTART_LOG}"; }
    build_k3d_cluster() { printf 'build_k3d_cluster %s\n' "$*" >> "${QUICKSTART_LOG}"; }
    destroy_k3d_cluster() { printf 'destroy_k3d_cluster\n' >> "${QUICKSTART_LOG}"; }
    deploy_flux() { printf 'deploy_flux\n' >> "${QUICKSTART_LOG}"; }
    deploy_bigbang() { printf 'deploy_bigbang %s\n' "$*" >> "${QUICKSTART_LOG}"; }
}

_mock_kubectl_and_jq() {
    mkdir -p "${BATS_TEST_TMPDIR}/bin"
    cat > "${BATS_TEST_TMPDIR}/bin/kubectl" <<'EOF'
#!/bin/bash
echo '{"items":[]}'
EOF
    chmod +x "${BATS_TEST_TMPDIR}/bin/kubectl"

    cat > "${BATS_TEST_TMPDIR}/bin/jq" <<'EOF'
#!/bin/bash
cat >/dev/null
EOF
    chmod +x "${BATS_TEST_TMPDIR}/bin/jq"

    export PATH="${BATS_TEST_TMPDIR}/bin:${PATH}"
}

_make_wait_script() {
    mkdir -p "${BATS_TEST_TMPDIR}/repo/big-bang/pipeline-templates/pipeline-templates/scripts/deploy"
    cat > "${BATS_TEST_TMPDIR}/repo/big-bang/pipeline-templates/pipeline-templates/scripts/deploy/03_wait_for_resources.sh" <<'EOF'
#!/bin/bash
printf 'wait_for_resources\n' >> "${QUICKSTART_LOG}"
EOF
    chmod +x "${BATS_TEST_TMPDIR}/repo/big-bang/pipeline-templates/pipeline-templates/scripts/deploy/03_wait_for_resources.sh"
}

@test "sourcing quickstart.sh loads functions without running the workflow" {
    _source_quickstart

    declare -f main >/dev/null
    declare -f check_for_tools >/dev/null
}

@test "parse_arguments sets defaults from the environment" {
    export REPO1_LOCATION="/tmp/repo1"
    export REGISTRY1_USERNAME="env-user"
    export REGISTRY1_TOKEN="env-token"

    _source_quickstart

    [ "${arg_repolocation}" = "/tmp/repo1" ]
    [ "${arg_registry1_username}" = "env-user" ]
    [ "${arg_registry1_token}" = "env-token" ]
    [ "${arg_pipeline_templates_version}" = "master" ]
    [ "${arg_cloud_provider}" = "aws" ]
}

@test "parse_arguments accepts core quickstart options" {
    _source_quickstart

    parse_arguments \
        --host 203.0.113.10 \
        --privateip 10.0.0.10 \
        --username ubuntu \
        --keyfile /tmp/key.pem \
        --version 3.0.0 \
        --pipeline-templates-version release-1.2.3 \
        --repolocation /tmp/repo1 \
        --registry1-username alice \
        --registry1-token token-value \
        --cloud-provider azure \
        --metallb \
        --provision \
        --deploy \
        --wait

    [ "${arg_host}" = "203.0.113.10" ]
    [ "${arg_privateip}" = "10.0.0.10" ]
    [ "${arg_username}" = "ubuntu" ]
    [ "${arg_keyfile}" = "/tmp/key.pem" ]
    [ "${arg_version}" = "3.0.0" ]
    [ "${arg_pipeline_templates_version}" = "release-1.2.3" ]
    [ "${arg_repolocation}" = "/tmp/repo1" ]
    [ "${arg_registry1_username}" = "alice" ]
    [ "${arg_registry1_token}" = "token-value" ]
    [ "${arg_cloud_provider}" = "azure" ]
    [ "${arg_metallb}" = "true" ]
    [ "${arg_provision}" = "true" ]
    [ "${arg_deploy}" = "true" ]
    [ "${arg_wait}" = "true" ]
}

@test "parse_arguments stores passthrough Helm arguments after --" {
    _source_quickstart

    parse_arguments --deploy -- -f "/tmp/custom values.yaml" --set addons.gitlab.enabled=true

    [ "${arg_deploy}" = "true" ]
    [ "${#arg_argv[@]}" -eq 4 ]
    [ "${arg_argv[0]}" = "-f" ]
    [ "${arg_argv[1]}" = "/tmp/custom values.yaml" ]
    [ "${arg_argv[2]}" = "--set" ]
    [ "${arg_argv[3]}" = "addons.gitlab.enabled=true" ]
}

@test "parse_arguments recreation flags imply provisioning" {
    _source_quickstart

    parse_arguments --recreate-k3d
    [ "${arg_recreate_k3d}" = "true" ]
    [ "${arg_provision}" = "true" ]

    _reset_quickstart_globals
    parse_arguments --recreate-cloud
    [ "${arg_recreate_cloud}" = "true" ]
    [ "${arg_provision}" = "true" ]
}

@test "parse_arguments rejects unknown options" {
    _source_quickstart

    run parse_arguments --not-a-real-option

    [ "${status}" -eq 1 ]
    [[ "${output}" == *"Option --not-a-real-option not recognized"* ]]
}

@test "build_k3d_arguments builds the expected k3d-dev flags and is idempotent" {
    _source_quickstart
    arg_privateip="10.0.0.10"
    arg_host="203.0.113.10"
    arg_username="ubuntu"
    arg_keyfile="/tmp/key.pem"
    arg_metallb=true
    arg_cloud_provider=aws
    arg_recreate_k3d=true
    arg_recreate_cloud=true

    first="$(build_k3d_arguments)"
    second="$(build_k3d_arguments)"

    expected=" -P 10.0.0.10 -H 203.0.113.10 -U ubuntu -k /tmp/key.pem -m -c aws -K -R"
    [ "${first}" = "${expected}" ]
    [ "${second}" = "${expected}" ]
}

@test "build_k3d_cluster invokes k3d-dev with quickstart defaults and extra arguments" {
    _source_quickstart
    export BIG_BANG_REPO="${BATS_TEST_TMPDIR}/bigbang"
    export K3D_ARGS_FILE="${BATS_TEST_TMPDIR}/k3d-args"
    mkdir -p "${BIG_BANG_REPO}/docs/reference/scripts/developer"
    cat > "${BIG_BANG_REPO}/docs/reference/scripts/developer/k3d-dev.sh" <<'EOF'
#!/bin/bash
printf '%s\n' "$@" > "${K3D_ARGS_FILE}"
EOF
    chmod +x "${BIG_BANG_REPO}/docs/reference/scripts/developer/k3d-dev.sh"

    arg_host="203.0.113.10"
    arg_privateip="10.0.0.10"
    arg_username="ubuntu"
    arg_keyfile="/tmp/key.pem"
    arg_cloud_provider=aws

    build_k3d_cluster --kubeconfig /tmp/kubeconfig --print-instructions
    args="$(tr '\n' ' ' < "${K3D_ARGS_FILE}")"

    [[ "${args}" == *"-t quickstart -T -q"* ]]
    [[ "${args}" == *"-P 10.0.0.10"* ]]
    [[ "${args}" == *"-H 203.0.113.10"* ]]
    [[ "${args}" == *"-U ubuntu"* ]]
    [[ "${args}" == *"-k /tmp/key.pem"* ]]
    [[ "${args}" == *"-c aws"* ]]
    [[ "${args}" == *"--kubeconfig /tmp/kubeconfig --print-instructions"* ]]
}

@test "deploy_bigbang invokes Helm with registry credentials, defaults, and passthrough args" {
    _source_quickstart
    export BIG_BANG_REPO="${BATS_TEST_TMPDIR}/bigbang"
    export HELM_ARGS_FILE="${BATS_TEST_TMPDIR}/helm-args"
    export REGISTRY1_USERNAME="alice"
    export REGISTRY1_TOKEN="token-value"
    mkdir -p "${BIG_BANG_REPO}" "${BATS_TEST_TMPDIR}/bin"
    cat > "${BATS_TEST_TMPDIR}/bin/helm" <<'EOF'
#!/bin/bash
printf '%s\n' "$@" > "${HELM_ARGS_FILE}"
EOF
    chmod +x "${BATS_TEST_TMPDIR}/bin/helm"
    export PATH="${BATS_TEST_TMPDIR}/bin:${PATH}"

    deploy_bigbang -f "/tmp/custom values.yaml" --set addons.gitlab.enabled=true
    args="$(tr '\n' ' ' < "${HELM_ARGS_FILE}")"

    [[ "${args}" == *"upgrade -i bigbang ${BIG_BANG_REPO}/chart -n bigbang --create-namespace"* ]]
    [[ "${args}" == *"--set registryCredentials.username=alice"* ]]
    [[ "${args}" == *"--set registryCredentials.password=token-value"* ]]
    grep -qx -- "/tmp/custom values.yaml" "${HELM_ARGS_FILE}"
    [[ "${args}" == *"-f /tmp/custom values.yaml --set addons.gitlab.enabled=true"* ]]
    [[ "${args}" == *"-f ${BIG_BANG_REPO}/chart/ingress-certs.yaml"* ]]
    [[ "${args}" == *"-f ${BIG_BANG_REPO}/docs/reference/configs/example/dev-sso-values.yaml"* ]]
}

@test "check_for_tools exits with a helpful error when dependencies are missing" {
    _source_quickstart
    which() { return 1; }

    run check_for_tools

    [ "${status}" -eq 1 ]
    [[ "${output}" == *"Required tool jq missing, please fix and run again"* ]]
    [[ "${output}" == *"Required tool yq missing, please fix and run again"* ]]
}

@test "check_for_tools succeeds when all required tools are executable" {
    _source_quickstart
    mkdir -p "${BATS_TEST_TMPDIR}/tools"
    for tool in jq yq kubectl helm git sed awk; do
        printf '#!/bin/bash\nexit 0\n' > "${BATS_TEST_TMPDIR}/tools/${tool}"
        chmod +x "${BATS_TEST_TMPDIR}/tools/${tool}"
    done
    which() { printf '%s/tools/%s\n' "${BATS_TEST_TMPDIR}" "$1"; }

    check_for_tools
}

@test "main --destroy checks out repos and only destroys the quickstart cluster" {
    _source_quickstart
    export QUICKSTART_LOG="${BATS_TEST_TMPDIR}/quickstart.log"
    : > "${QUICKSTART_LOG}"
    _mock_quickstart_workflow

    run main --repolocation "${BATS_TEST_TMPDIR}/repo" --destroy

    [ "${status}" -eq 0 ]
    log="$(cat "${QUICKSTART_LOG}")"
    [[ "${log}" == *"checkout_bigbang_repo"* ]]
    [[ "${log}" == *"checkout_pipeline_templates"* ]]
    [[ "${log}" == *"destroy_k3d_cluster"* ]]
    [[ "${log}" != *"deploy_flux"* ]]
    [[ "${log}" != *"deploy_bigbang"* ]]
    [[ "${log}" != *"wait_for_resources"* ]]
}

@test "main --deploy deploys, waits, forwards Helm args, and prints instructions" {
    _source_quickstart
    export QUICKSTART_LOG="${BATS_TEST_TMPDIR}/quickstart.log"
    : > "${QUICKSTART_LOG}"
    _mock_quickstart_workflow
    _mock_kubectl_and_jq
    _make_wait_script

    run main \
        --host 203.0.113.10 \
        --repolocation "${BATS_TEST_TMPDIR}/repo" \
        --deploy \
        -- -f /tmp/custom-values.yaml --set addons.gitlab.enabled=true

    [ "${status}" -eq 0 ]
    log="$(cat "${QUICKSTART_LOG}")"
    [[ "${log}" == *"checkout_bigbang_repo"* ]]
    [[ "${log}" == *"checkout_pipeline_templates"* ]]
    [[ "${log}" == *"deploy_flux"* ]]
    [[ "${log}" == *"deploy_bigbang -f /tmp/custom-values.yaml --set addons.gitlab.enabled=true"* ]]
    [[ "${log}" == *"wait_for_resources"* ]]
    [[ "${log}" == *"build_k3d_cluster --kubeconfig"* ]]
    [[ "${log}" == *"203.0.113.10-dev-quickstart-config"* ]]
    [[ "${output}" == *"INSTALLATION   COMPLETE"* ]]
}
