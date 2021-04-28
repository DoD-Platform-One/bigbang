package lib.kubernetes

default is_gatekeeper = false

is_gatekeeper {
	has_field(input, "review")
	has_field(input.review, "object")
}

object = input {
	not is_gatekeeper
}

object = input.review.object {
	is_gatekeeper
}

format(msg) = gatekeeper_format {
	is_gatekeeper
	gatekeeper_format = {"msg": msg}
}

format(msg) = msg {
	not is_gatekeeper
}

name = object.metadata.name

kind = object.kind

is_service {
	kind = "Service"
}

is_deployment {
	kind = "Deployment"
}

is_daemonset {
	kind = "DaemonSet"
}

is_statefulset {
	kind = "StatefulSet"
}

is_pod {
	kind = "Pod"
}

has_field(obj, field) {
	obj[field]
}

