package main

name = input.metadata.name

deny[msg] {
  image := input.spec.template.spec.containers[_].image
  not any([startswith(image, "registry1.dsop.io/ironbank"), startswith(image, "registry1.dso.mil/ironbank")])
  msg := sprintf("Image '%v' in '%v' is not from Ironbank", [image, name])
}
