#!/usr/bin/env bats

# Load the file containing the get_package_path function
load '../library/templates.sh'
load 'node_modules/bats-assert/load.bash'
load 'node_modules/bats-support/load.bash'

setup_file() {
  curl https://repo1.dso.mil/big-bang/bigbang/-/raw/master/chart/values.yaml > $BATS_SUITE_TMPDIR/values.yaml
}

setup() {
  bats_require_minimum_version 1.5.0
  CI_VALUES_FILE=$BATS_SUITE_TMPDIR/values.yaml
  VALUES_FILE=$BATS_SUITE_TMPDIR/values.yaml
  MAPPING_FILE=../library/package-mapping.yaml
  PACKAGE_IMAGE_FILE=$BATS_SUITE_TMPDIR/package-images.yaml
}

# Test the get_package_path function
@test "get_package_path returns the expected path for a valid package name" {
  expected_path="neuvector"
  run -0 get_package_path neuvector
  assert_equal "$output" "$expected_path"
}

@test "get_package_path returns an empty string for an invalid package name" {
  expected_error=""
  run -0 get_package_path foobar
  assert_equal "$output" "$expected_error"
}

@test "get_package_path returns the expected path for a valid addons package name" {
  expected_path="addons.velero"
  run -0 get_package_path velero
  assert_equal "$output" "$expected_path"
}

@test "enable function enables a package" {
  yq -i e '.neuvector.enabled = "false"' $VALUES_FILE

  run -0 enable neuvector
  expected="true"
  actual="$(yq e '.neuvector.enabled' $VALUES_FILE)"
  assert_equal "$actual" "$expected"
}

@test "enable function enables an addons package" {
  yq -i e '.addons.velero.enabled = "false"' $VALUES_FILE

  run -0 enable velero
  expected="true"
  actual="$(yq e '.addons.velero.enabled' $VALUES_FILE)"
  assert_equal "$actual" "$expected"
}

@test "get dependencies function returns nothing" {
  run -0 get_dependencies_from_values_key mattermostOperator
  expected=""
  assert_equal "$output" "$expected"
}

@test "get dependencies function returns no error" {
  run -0 get_dependencies_from_values_key "Spaces in key"
  expected=""
  assert_equal "$output" "$expected"
}

@test "get dependencies function returns dependencies" {
  run -0 get_dependencies_from_values_key velero
  expected=$'minio\nminioOperator'
  assert_equal "$output" "$expected"
}

@test "get generating package image file" {
  run -0 bigbang_package_images
  istio_image_count="$(yq e '.package-image-list.istio.images | length' $PACKAGE_IMAGE_FILE)"
  istio_has_version="$(yq e '.package-image-list.istio | has("version")' $PACKAGE_IMAGE_FILE)"
  package_count="$(yq e '.package-image-list | length' $PACKAGE_IMAGE_FILE)"

  # Spot check istio
  [ "$istio_image_count" -gt 2 ]
  assert_equal "$istio_has_version" "true"

  # Should have lots of packages
  [ "$package_count" -gt 5 ]
}
