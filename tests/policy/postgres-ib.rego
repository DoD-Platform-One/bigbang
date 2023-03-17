package main

name = input.metadata.name

registries_allow_pg := ["registry1.dsop.io/ironbank", "registry1.dso.mil/ironbank", "registry.dsop.io", "registry.dso.mil"]
registries_warn_pg := ["registry.dsop.io", "registry.dso.mil"]

in_allowed_registries_pg(image) {
  startswith(image, registries_allow[i])
}

in_warning_registries_pg(image) {
  startswith(image, registries_warn[i])
}

# Deny non-approved registries
deny[msg] {
  image := input.spec.dockerImage
  not in_allowed_registries_pg(image)
  msg := sprintf("Image '%v' in '%v' is not from approved registries", [image, name])
}

# Warn about non-Ironbank Images
warn[msg] {
  image := input.spec.dockerImage
  in_warning_registries_pg(image)
  msg := sprintf("Image '%v' in '%v' is not from Ironbank", [image, name])
}

# Warn about DSOP Images
warn[msg] {
  image := input.spec.dockerImage
  contains(image, ".dsop.io")
  msg := sprintf("Update 'dsop.io' to 'dso.mil' for image '%v' in '%v'", [image, name])
}
