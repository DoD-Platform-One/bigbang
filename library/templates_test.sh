#!/usr/bin/env bats

# Load the file containing the get_package_path function
load 'templates.sh'

setup_file() {
  curl https://repo1.dso.mil/big-bang/bigbang/-/raw/master/chart/values.yaml > values.yaml
}

setup() {
  bats_require_minimum_version 1.5.0
  CI_VALUES_FILE=values.yaml
  VALUES_FILE=values.yaml
  MAPPING_FILE=library/package-mapping.yaml
}

# Test the get_package_path function
@test "get_package_path returns the expected path for a valid package name" {
  expected_path="neuvector"
  run -0 get_package_path neuvector
  [ "$output" = "$expected_path" ]
}

@test "get_package_path returns an empty string for an invalid package name" {
  expected_error=""
  run -0 get_package_path foobar
  [ "$output" = "$expected_error" ]
}

@test "get_package_path returns the expected path for a valid addons package name" {
  expected_path="addons.velero"
  run -0 get_package_path velero
  [ "$output" = "$expected_path" ]
}

@test "enable function enables a package" {
  yq -i e '.neuvector.enabled = "false"' $VALUES_FILE

  run -0 enable neuvector
  expected="true"
  actual="$(yq e '.neuvector.enabled' $VALUES_FILE)"
  [ "$actual" = "$expected" ]
}

@test "enable function enables an addons package" {
  yq -i e '.addons.velero.enabled = "false"' $VALUES_FILE

  run -0 enable velero
  expected="true"
  actual="$(yq e '.addons.velero.enabled' $VALUES_FILE)"
  [ "$actual" = "$expected" ]
}

@test "get dependencies function returns nothing" {
  run -0 get_dependencies_from_values_key mattermostOperator
  expected=""
  [ "$output" = "$expected" ]
}

@test "get dependencies function returns no error" {
  run -0 get_dependencies_from_values_key "Spaces in key"
  expected=""
  [ "$output" = "$expected" ]
}

@test "get dependencies function returns dependencies" {
  run -0 get_dependencies_from_values_key velero
  expected=$'minio\nminioOperator'
  [ "$output" = "$expected" ]
}
