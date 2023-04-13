#!/usr/bin/env bats

# Load the bats-assert library
load 'node_modules/bats-assert/load.bash'
load 'node_modules/bats-support/load.bash'

BIGBANG_HOME=../

diag() {
  echo "# $@" >&3
}

valid() {
  TEST_DIR=test-values/$1/valid

  find $TEST_DIR -type f | while read file; do
    diag "Testing $file"
    run helm template $BIGBANG_HOME/chart --values=$file
    assert_equal "$status" "0"
  done
}

invalid() {
  TEST_DIR=test-values/$1/invalid

  find $TEST_DIR -type f | while read file; do
    diag "Testing $file"
    run helm template $BIGBANG_HOME/chart --values=$file
    assert_equal "$status" "1"
  done
}

# Test basic schema validation
@test "helm template validate schema" {
  run helm template $BIGBANG_HOME/chart
  assert_equal "$status" "0"
}

# Test basic schema validation failure
@test "helm template validate schema failure" {
  run helm template $BIGBANG_HOME/chart --set=neuvector.sso.foo=true
  assert_equal "$status" "1"
}

# Test umbrella validation
@test "helm template validate umbrella schema" {
  valid umbrella
  invalid umbrella
}

# Test git schema validation
@test "helm template validate schema git" {
  valid git
  invalid git
}

# Test registryCredentials schema validation
@test "helm template validate schema registryCredentials" {
  valid registry-credentials
  invalid registry-credentials
}

# Test basePackage git schema validation
@test "helm template validate basePackage schema" {
  valid base-package
  invalid base-package
}

# Test basePackage git schema validation
@test "helm template validate git basePackage schema" {
  valid base-package-git
  invalid base-package-git
}

# Test basePackage sso schema validation
@test "helm template validate sso schema" {
  valid base-package-sso
  invalid base-package-sso
}

# Test basePackage helmRepo schema validation
@test "helm template validate helmRepo schema" {
  valid base-package-helm-repo
  invalid base-package-helm-repo
}

# Test basePackage source type schema validation
@test "helm template validate source type schema" {
  valid base-package-source-type
  invalid base-package-source-type
}

# Test basePackage source type schema validation
@test "helm template validate addons schema" {
  valid addons
  invalid addons
}

# Ensure core packages cannot have extra keys
@test "helm template validate core package no extra keys" {
  local PACKAGES=$(yq e '.[] | select(. | (has("git") or has("oci"))) | path | .[-1]' $BIGBANG_HOME/chart/values.yaml)

  for package in $PACKAGES; do
    run helm template $BIGBANG_HOME/chart --set=$package.extra=key --values=$file
    diag "Testing extra keys for core package $package"
    assert_equal "$status" "1"
  done
}