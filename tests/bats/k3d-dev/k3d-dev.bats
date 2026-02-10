#!/usr/bin/env bats
# =============================================================================
# BATS Tests for k3d-dev.sh
# =============================================================================
# Source: docs/reference/scripts/developer/k3d-dev.sh
# Run with: bats tests/bats/k3d-dev/
#
# These tests verify k3d-dev.sh pure functions and argument parsing.
# No real AWS API calls, SSH connections, or network requests are made.
#
# NOTE: Due to BATS subshell behavior, we source k3d-dev.sh within each test
# rather than in setup(). This ensures functions have access to proper state.
# =============================================================================

# Helper to source the script
_source_k3d_dev() {
    export TMPDIR="${BATS_TEST_TMPDIR:-$(mktemp -d)}"
    REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}" && git rev-parse --show-toplevel)"
    source "${REPO_ROOT}/docs/reference/scripts/developer/k3d-dev.sh"
    trap - EXIT  # Clear k3d-dev.sh's trap to prevent interference
}

# Cleanup after each test
teardown() {
    rm -f k3d_dev_run_batch* 2>/dev/null || true
}

# Helper to reset globals
_reset_globals() {
    export PROVISION_CLOUD_INSTANCE=true
    export CLOUDPROVIDER="aws"
    export SSHUSER=ubuntu
    export action=create_instances
    export ATTACH_SECONDARY_IP=false
    export BIG_INSTANCE=false
    export METAL_LB=true
    export PRIVATE_IP=false
    export PROJECTTAG=default
    export RESET_K3D=false
    export USE_WEAVE=false
    export TERMINATE_INSTANCE=true
    export QUIET=false
    export CLOUD_RECREATE_INSTANCE=false
    export INIT_SCRIPT=""
    export RUN_BATCH_FILE=""
    export KUBECONFIG=""
    export PrivateIP=""
    export PublicIP=""
    export SSHKEY=""
    export AWSUSERNAME=""
    export InstId=""
    export BASE_DOMAIN="dev.bigbang.mil"
    export ENABLE_OIDC=false
    export PUBLIC_DOMAINS=()
    export PASSTHROUGH_DOMAINS=()
}

# =============================================================================
# Pure Function Tests
# =============================================================================

@test "k3dsshcmd builds correct SSH command" {
    _source_k3d_dev
    SSHKEY="/path/to/key.pem"
    SSHUSER="testuser"
    PublicIP="10.0.0.1"

    result=$(k3dsshcmd)

    [[ "$result" == *"-i /path/to/key.pem"* ]]
    [[ "$result" == *"testuser@10.0.0.1"* ]]
}

@test "set_kubeconfig uses PublicIP when not provisioning" {
    _source_k3d_dev
    _reset_globals
    PROVISION_CLOUD_INSTANCE="false"
    PublicIP="1.2.3.4"
    PROJECTTAG="myproject"

    set_kubeconfig

    [[ "$KUBECONFIG" == *"1.2.3.4-dev-myproject-config" ]]
}

@test "set_kubeconfig uses AWSUSERNAME when provisioning" {
    _source_k3d_dev
    _reset_globals
    PROVISION_CLOUD_INSTANCE="true"
    AWSUSERNAME="devuser"
    PROJECTTAG="test"

    set_kubeconfig

    [[ "$KUBECONFIG" == *"devuser-dev-test-config" ]]
}

# =============================================================================
# Argument Parsing Tests
# =============================================================================

@test "process_arguments -b sets BIG_INSTANCE=true" {
    _source_k3d_dev
    _reset_globals
    process_arguments -b
    [ "$BIG_INSTANCE" = "true" ]
}

@test "process_arguments -M sets METAL_LB=false" {
    _source_k3d_dev
    _reset_globals
    process_arguments -M
    [ "$METAL_LB" = "false" ]
}

@test "process_arguments -p sets PRIVATE_IP=true" {
    _source_k3d_dev
    _reset_globals
    process_arguments -p
    [ "$PRIVATE_IP" = "true" ]
}

@test "process_arguments -d sets action=destroy_instances" {
    _source_k3d_dev
    _reset_globals
    process_arguments -d
    [ "$action" = "destroy_instances" ]
}

@test "process_arguments -t sets PROJECTTAG" {
    _source_k3d_dev
    _reset_globals
    process_arguments -t myproject
    [ "$PROJECTTAG" = "myproject" ]
}

@test "process_arguments -K sets RESET_K3D=true" {
    _source_k3d_dev
    _reset_globals
    process_arguments -K
    [ "$RESET_K3D" = "true" ]
}

@test "process_arguments -H sets PublicIP and disables cloud provisioning" {
    _source_k3d_dev
    _reset_globals
    process_arguments -H 192.168.1.100
    [ "$PublicIP" = "192.168.1.100" ]
    [ "$PROVISION_CLOUD_INSTANCE" = "false" ]
}

@test "process_arguments -H without -P sets PrivateIP=PublicIP" {
    _source_k3d_dev
    _reset_globals
    process_arguments -H 10.20.30.40
    [ "$PublicIP" = "10.20.30.40" ]
    [ "$PrivateIP" = "10.20.30.40" ]
}

@test "process_arguments -D and --domain set BASE_DOMAIN" {
    _source_k3d_dev
    _reset_globals
    process_arguments -D custom.example.com
    [ "$BASE_DOMAIN" = "custom.example.com" ]

    _reset_globals
    process_arguments --domain another.domain.org
    [ "$BASE_DOMAIN" = "another.domain.org" ]
}

@test "process_arguments handles multiple flags" {
    _source_k3d_dev
    _reset_globals
    process_arguments -b -M -t combined-test
    [ "$BIG_INSTANCE" = "true" ]
    [ "$METAL_LB" = "false" ]
    [ "$PROJECTTAG" = "combined-test" ]
}

@test "process_arguments reports unknown option" {
    _source_k3d_dev
    _reset_globals
    output=$(process_arguments --unknown-option 2>&1) || true
    [[ "$output" == *"not recognized"* ]]
}

# =============================================================================
# Domain Configuration Tests
# =============================================================================

@test "set_domains builds PUBLIC_DOMAINS and PASSTHROUGH_DOMAINS" {
    _source_k3d_dev
    _reset_globals
    BASE_DOMAIN="test.example.com"
    PUBLIC_SUBDOMAINS=("grafana" "prometheus")
    PASSTHROUGH_SUBDOMAINS=("keycloak")

    set_domains

    [[ " ${PUBLIC_DOMAINS[*]} " == *"grafana.test.example.com"* ]]
    [[ " ${PUBLIC_DOMAINS[*]} " == *"prometheus.test.example.com"* ]]
    [[ " ${PASSTHROUGH_DOMAINS[*]} " == *"keycloak.test.example.com"* ]]
}

@test "set_domains uses default BASE_DOMAIN" {
    _source_k3d_dev
    set_domains
    [[ " ${PUBLIC_DOMAINS[*]} " == *"grafana.dev.bigbang.mil"* ]]
}

@test "set_domains clears stale values before rebuilding" {
    _source_k3d_dev
    _reset_globals
    BASE_DOMAIN="new.domain.com"
    PUBLIC_SUBDOMAINS=("app")
    PASSTHROUGH_SUBDOMAINS=()
    PUBLIC_DOMAINS=("stale.old.domain.com")

    set_domains

    [ "${#PUBLIC_DOMAINS[@]}" -eq 1 ]
    [ "${PUBLIC_DOMAINS[0]}" = "app.new.domain.com" ]
}

# =============================================================================
# Batch File Tests
# =============================================================================

@test "run_batch_add fails if no batch started" {
    _source_k3d_dev
    _reset_globals
    exit_code=0
    ( run_batch_add "echo test" ) 2>/dev/null || exit_code=$?
    [ "$exit_code" -eq 1 ]
}
