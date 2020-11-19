package main

import data.kubernetes

name = input.metadata.name

required_deployment_labels {
    input.metadata.labels["app.kubernetes.io/name"]
    input.metadata.labels["app.kubernetes.io/instance"]
    input.metadata.labels["app.kubernetes.io/version"]
    input.metadata.labels["app.kubernetes.io/component"]
    input.metadata.labels["app.kubernetes.io/part-of"]
    input.metadata.labels["app.kubernetes.io/managed-by"]
}

deny[msg] {
  kubernetes.is_deployment
  not required_deployment_labels
  msg = sprintf("%s must include Kubernetes recommended labels: https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/#labels", [name])
}

deny[msg] {
  input.kind == "Deployment"
  image := input.spec.template.spec.containers[_].image
  not count(split(image, ":")) == 2
  msg := sprintf("image '%v' doesn't specify a valid tag", [image])
}

deny[msg] {
  input.kind == "Deployment"
  image := input.spec.template.spec.containers[_].image
  endswith(image, "latest")
  msg := sprintf("image '%v' uses latest tag", [image])
}
