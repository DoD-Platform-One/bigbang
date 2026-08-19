#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  REPO_ROOT=$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)
  GENERATOR="${REPO_ROOT}/scripts/generate-package-schemas.sh"
}

create_generator_fixture() {
  FIXTURE_ROOT="${BATS_TEST_TMPDIR}/repo"
  mkdir -p "${FIXTURE_ROOT}/chart/templates" "${FIXTURE_ROOT}/scripts"
  cp "${REPO_ROOT}/chart/package-metadata.yaml" \
    "${REPO_ROOT}/chart/values.schema.json" \
    "${REPO_ROOT}/chart/values.yaml" \
    "${FIXTURE_ROOT}/chart/"
  cp "${REPO_ROOT}/scripts/generate-package-schemas.jq" \
    "${REPO_ROOT}/scripts/generate-package-schemas.sh" \
    "${REPO_ROOT}/scripts/migrate-values-3-to-4.sh" \
    "${FIXTURE_ROOT}/scripts/"

  while IFS= read -r template_directory; do
    mkdir -p "${FIXTURE_ROOT}/chart/templates/${template_directory}"
  done < <(yq -r '.packages[].templateDirectory' "${FIXTURE_ROOT}/chart/package-metadata.yaml")
}

@test "generated canonical package schemas are current" {
  run "$GENERATOR" --check

  [ "$status" -eq 0 ]
  [ "$output" = "Generated package metadata files are up to date." ]
}

@test "every catalog package has a generated canonical schema" {
  expected=$(yq -o=json '.packages | keys' "${REPO_ROOT}/chart/package-metadata.yaml" | jq -c 'sort')
  actual=$(jq -c '.["$defs"].canonicalPackages.properties | keys | sort' "${REPO_ROOT}/chart/values.schema.json")

  [ "$actual" = "$expected" ]
}

@test "rejects an integrated package template directory omitted from the catalog" {
  create_generator_fixture
  mkdir -p "${FIXTURE_ROOT}/chart/templates/example-package"
  touch "${FIXTURE_ROOT}/chart/templates/example-package/helmrelease.yaml"

  run "${FIXTURE_ROOT}/scripts/generate-package-schemas.sh" --check

  [ "$status" -ne 0 ]
  [ "$output" = "Error: integrated package template directory chart/templates/example-package is missing from chart/package-metadata.yaml" ]
}

@test "rejects a package key that is not a camelCase identifier" {
  create_generator_fixture
  yq -i '.packages."invalid-package" = .packages.kiali | del(.packages.kiali)' \
    "${FIXTURE_ROOT}/chart/package-metadata.yaml"

  run "${FIXTURE_ROOT}/scripts/generate-package-schemas.sh" --check

  [ "$status" -ne 0 ]
  [[ "$output" == *"package metadata package keys must use camelCase identifiers"* ]]
}

@test "rejects a template directory that is not kebab-case" {
  create_generator_fixture
  yq -i '.packages.kiali.templateDirectory = "Invalid_Directory"' \
    "${FIXTURE_ROOT}/chart/package-metadata.yaml"

  run "${FIXTURE_ROOT}/scripts/generate-package-schemas.sh" --check

  [ "$status" -ne 0 ]
  [[ "$output" == *"package metadata templateDirectory values must use kebab-case directory names"* ]]
}
