#!/usr/bin/env bats

bats_require_minimum_version 1.5.0

setup() {
  REPO_ROOT=$(cd "${BATS_TEST_DIRNAME}/../../.." && pwd)
  GENERATOR="${REPO_ROOT}/scripts/generate-package-schemas.sh"
}

create_generator_fixture() {
  FIXTURE_ROOT="${BATS_TEST_TMPDIR}/repo"
  mkdir -p "${FIXTURE_ROOT}/chart/templates" "${FIXTURE_ROOT}/scripts" \
    "${FIXTURE_ROOT}/docs/packages/core" "${FIXTURE_ROOT}/docs/packages/addons"
  cp "${REPO_ROOT}/chart/package-metadata.yaml" \
    "${REPO_ROOT}/chart/values.schema.json" \
    "${REPO_ROOT}/chart/values.yaml" \
    "${FIXTURE_ROOT}/chart/"
  cp "${REPO_ROOT}/scripts/generate-package-schemas.jq" \
    "${REPO_ROOT}/scripts/generate-package-schemas.sh" \
    "${REPO_ROOT}/scripts/migrate-values-3-to-4.sh" \
    "${FIXTURE_ROOT}/scripts/"
  cp "${REPO_ROOT}/docs/packages/index.md" "${FIXTURE_ROOT}/docs/packages/"
  cp "${REPO_ROOT}/docs/packages/core/index.md" \
    "${REPO_ROOT}/docs/packages/core/.pages" \
    "${FIXTURE_ROOT}/docs/packages/core/"
  cp "${REPO_ROOT}/docs/packages/addons/index.md" \
    "${REPO_ROOT}/docs/packages/addons/.pages" \
    "${FIXTURE_ROOT}/docs/packages/addons/"

  while IFS= read -r template_directory; do
    mkdir -p "${FIXTURE_ROOT}/chart/templates/${template_directory}"
  done < <(yq -r '.packages[].templateDirectory' "${FIXTURE_ROOT}/chart/package-metadata.yaml")

  while IFS= read -r documentation_path; do
    mkdir -p "${FIXTURE_ROOT}/$(dirname "$documentation_path")"
    cp "${REPO_ROOT}/${documentation_path}" \
      "${FIXTURE_ROOT}/${documentation_path}"
  done < <(yq -r '.packages[].documentation' \
    "${FIXTURE_ROOT}/chart/package-metadata.yaml" | sort -u)
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

@test "every catalog package has a generated documentation entry" {
  while IFS=$'\t' read -r package_name documentation_path; do
    grep -Fq "packages.${package_name}" "${REPO_ROOT}/docs/packages/index.md"
    [ -f "${REPO_ROOT}/${documentation_path}" ]
  done < <(yq -r '.packages | to_entries[] | [.key, .value.documentation] | @tsv' \
    "${REPO_ROOT}/chart/package-metadata.yaml")
}

@test "package metadata groups categories and alphabetizes canonical keys" {
  category_order=$(yq -r '.packages[].category' \
    "${REPO_ROOT}/chart/package-metadata.yaml" | awk '!seen[$0]++')
  [ "$category_order" = $'core\naddon' ]

  for category in core addon; do
    actual=$(CATEGORY="$category" yq -r \
      '.packages | to_entries[] | select(.value.category == strenv(CATEGORY)) | .key' \
      "${REPO_ROOT}/chart/package-metadata.yaml")
    expected=$(printf '%s\n' "$actual" | LC_ALL=C sort -f)

    [ "$actual" = "$expected" ]
  done
}

@test "generated package navigation is alphabetical by displayed title" {
  for navigation_path in \
    "${REPO_ROOT}/docs/packages/core/.pages" \
    "${REPO_ROOT}/docs/packages/addons/.pages"; do
    actual=$(sed -n 's/^  - "\([^"]*\)":.*$/\1/p' "$navigation_path")
    expected=$(printf '%s\n' "$actual" | LC_ALL=C sort -f)

    [ "$actual" = "$expected" ]
  done
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

@test "rejects package documentation outside its category" {
  create_generator_fixture
  yq -i '.packages.kiali.documentation = "docs/packages/addons/kiali.md"' \
    "${FIXTURE_ROOT}/chart/package-metadata.yaml"

  run "${FIXTURE_ROOT}/scripts/generate-package-schemas.sh" --check

  [ "$status" -ne 0 ]
  [[ "$output" == *"package metadata documentation paths must match the package category"* ]]
}

@test "rejects a package documentation path that does not exist" {
  create_generator_fixture
  rm "${FIXTURE_ROOT}/docs/packages/core/kiali.md"

  run "${FIXTURE_ROOT}/scripts/generate-package-schemas.sh" --check

  [ "$status" -ne 0 ]
  [ "$output" = "Error: package documentation docs/packages/core/kiali.md does not exist" ]
}
