package lib.kubernetes

containers[container] {
	pods[pod]
	all_containers = pod_containers(pod)
	container = all_containers[_]
}

containers[container] {
	all_containers = pod_containers(object)
	container = all_containers[_]
}

guaranteed_qos(c) {
	not c.resources.requests.memory = c.resources.limits.memory
	not c.resources.requests.cpu = c.resources.limits.cpu
}

guaranteed_qos(c) {
	not c.resources.requests.memory = c.resources.limits.memory
}

guaranteed_qos(c) {
	not c.resources.requests.cpu = c.resources.limits.cpu
}

no_read_only_filesystem(c) {
	has_field(c, "securityContext")
	not has_field(c.securityContext, "readOnlyRootFilesystem")
}

privileged(c) {
	has_field(c, "securityContext")
	has_field(c.securityContext, "privileged")
	c.securityContext.privileged
}

runasuser(c) = issue {
	has_field(c, "securityContext")
	has_field(c.securityContext, "runAsUser")
	c.securityContext.runAsUser < 10000
	issue = "has a UID of less than 1000"
}

runasuser(c) = issue {
	has_field(c, "securityContext")
	not c.securityContext.runAsUser
	issue = "using defaulting to image UID"
}

hostpath(c) {
	sprintf("%s", [c])
	has_field(c, "hostPath")
	has_field(c.hostPath, "path")
}

split_image(image) = [image, "latest"] {
	not contains(image, ":")
}

split_image(image) = [image_name, tag] {
	[image_name, tag] = split(image, ":")
}