package main

import data.lib.kubernetes

registries_allow := ["registry1.dso.mil/ironbank", "registry.dso.mil"]
registries_warn := ["registry.dso.mil"]

in_allowed_registries(image) {
    startswith(image, registries_allow[i])
}

in_warning_registries(image) {
    startswith(image, registries_warn[i])
}

# Deny non-approved registries
deny[msg] {
	kubernetes.containers[container]
	[image_name, tag] = kubernetes.split_image(container.image)
	not in_allowed_registries(image_name)
	msg := sprintf("Image '%v' in '%v' '%v' is not from approved registries", [image_name, kubernetes.kind, kubernetes.name])
}

# Warn about non-Ironbank registries
warn[msg] {
	kubernetes.containers[container]
	[image_name, tag] = kubernetes.split_image(container.image)
    not in_allowed_registries(image_name)
    msg := sprintf("Image '%v' in '%v' '%v' is not from Ironbank", [image_name, kubernetes.kind, kubernetes.name])
}
