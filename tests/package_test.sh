#!/usr/bin/env bats

load '../library/templates.sh'
load 'node_modules/bats-assert/load.bash'
load 'node_modules/bats-support/load.bash'

setup() {
  bats_require_minimum_version 1.5.0
  mkdir -p $BATS_FILE_TMPDIR/chart
  cat << EOF > $BATS_FILE_TMPDIR/chart/Chart.yaml
annotations:
  helm.sh/images: |
    - name: exporter
      image: registry1.dso.mil/ironbank/neuvector/neuvector/prometheus-exporter:5.1.0
EOF

  echo "registry1.dso.mil/ironbank/neuvector/neuvector/prometheus-exporter:5.1.0" > $BATS_FILE_TMPDIR/images.txt
}

@test "image_annotation_validation success" {
  cd $BATS_FILE_TMPDIR
  run -0 image_annotation_validation
}

@test "image_annotation_validation invalid image annotation failure" {
  cd $BATS_FILE_TMPDIR
  echo "registry1.dso.mil/ironbank/neuvector/neuvector/nothere:1.2.3" >> $BATS_FILE_TMPDIR/images.txt

  run -1 image_annotation_validation
  assert_output --partial "pulled in cluster but not found in helm.sh/images annotation in Chart.yaml."
}

@test "image_annotation_validation invalid image failure" {
  cat << EOF > $BATS_FILE_TMPDIR/chart/Chart.yaml
annotations:
  helm.sh/images: |
    - name: exporter
      image: registry1.dso.mil/ironbank/neuvector/neuvector/prometheus-exporter:5.1.0
    - name: nothere
      image: registry1.dso.mil/ironbank/neuvector/neuvector/nothere:1.2.3
EOF

  cd $BATS_FILE_TMPDIR

  run -1 image_annotation_validation
  assert_output --partial "from helm.sh/images annotation in Chart.yaml does not exist in the registry."
}

@test "image_annotation_validation image not annotated" {
  cd $BATS_FILE_TMPDIR
  echo "registry1.dso.mil/ironbank/opensource/grafana/loki:2.7.4" >> $BATS_FILE_TMPDIR/images.txt

  run -1 image_annotation_validation
  assert_output --partial "pulled in cluster but not found in helm.sh/images annotation in Chart.yaml."
}

@test "image_annotation_validation no annotations, no errors" {
  rm -rf $BATS_FILE_TMPDIR/chart/Chart.yaml
  cat << EOF > $BATS_FILE_TMPDIR/chart/Chart.yaml
annotations:
  not-helm-annotation: foobar
EOF
  echo "registry1.dso.mil/ironbank/opensource/grafana/loki:2.7.4" >> $BATS_FILE_TMPDIR/images.txt

  cd $BATS_FILE_TMPDIR

  run -0 image_annotation_validation
}
