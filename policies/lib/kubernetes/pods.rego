package lib.kubernetes

pods[pod] {
	is_statefulset
	pod = object.spec.template
}

pods[pod] {
	is_daemonset
	pod = object.spec.template
}

pods[pod] {
	is_deployment
	pod = object.spec.template
}

pods[pod] {
	is_pod
	pod = object
}

pod_containers(pod) = all_containers {
	keys = {"containers", "initContainers"}
	all_containers = [c | keys[k]; c = pod.spec[k][_]]
}

default_serviceaccount(p) {
	has_field(p, "automountServiceAccountToken")
	has_field(p, "serviceAccountName")
	p.automountServiceAccountToken = true
	p.serviceAccountName = "default"
}

default_serviceaccount(p) {
	not has_field(p, "automountServiceAccountToken")
	not has_field(p, "serviceAccountName")
}
