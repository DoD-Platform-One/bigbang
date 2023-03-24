#!/usr/bin/env bats

# Load the file containing the get_package_path function
load 'templates.sh'

setup_file() {
  curl https://repo1.dso.mil/big-bang/bigbang/-/raw/master/chart/values.yaml > values.yaml
}

setup() {
  CI_VALUES_FILE=values.yaml
  VALUES_FILE=values.yaml
}

# Test the get_package_path function
@test "get_package_path returns the expected path for a valid package name" {
  expected_path="neuvector"
  actual_path="$(get_package_path neuvector)"
  [ "$actual_path" = "$expected_path" ]
}

@test "get_package_path returns an empty string for an invalid package name" {
  expected_error=""
  actual_error="$(get_package_path foobar)"
  [ "$actual_error" = "$expected_error" ]
}

@test "get_package_path returns the expected path for a valid addons package name" {
  expected_path="addons.velero"
  actual_path="$(get_package_path velero)"
  [ "$actual_error" = "$expected_error" ]
}

@test "enable function enables a package" {
  yq -i e '.neuvector.enabled = "false"' $VALUES_FILE

  enable neuvector
  expected="true"
  actual="$(yq e '.neuvector.enabled' $VALUES_FILE)"
  [ "$actual" = "$expected" ]
}

@test "enable function enables an addons package" {
  yq -i e '.addons.velero.enabled = "false"' $VALUES_FILE

  enable velero
  expected="true"
  actual="$(yq e '.addons.velero.enabled' $VALUES_FILE)"
  [ "$actual" = "$expected" ]
}

