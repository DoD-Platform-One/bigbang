#!/usr/bin/env bats

setup() {
    export REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}" && git rev-parse --show-toplevel)"
}

@test "ambient overlay retains Vault ingress certificates" {
    run yq eval-all \
        '(select(fileIndex == 0) * select(fileIndex == 1) * select(fileIndex == 2)) |
        ((.addons.vault.ingress.cert | length) > 0 and
        (.addons.vault.ingress.key | length) > 0)' \
        "${REPO_ROOT}/tests/test-values.yaml" \
        "${REPO_ROOT}/chart/ingress-certs.yaml" \
        "${REPO_ROOT}/tests/test-values-ambient.yaml"

    [ "${status}" -eq 0 ]
    [ "${output}" = "true" ]
}

@test "ambient overlay contains only ambient-specific configuration" {
    run yq eval --output-format=json --indent=0 \
        '{"top": (keys | sort), "ambient": .istio.ambient.enabled}' \
        "${REPO_ROOT}/tests/test-values-ambient.yaml"

    [ "${status}" -eq 0 ]
    [ "${output}" = '{"top":["istio"],"ambient":true}' ]
}
