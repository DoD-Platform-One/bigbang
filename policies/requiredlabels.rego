package main

import data.lib.kubernetes

warn[msg] {
	kubernetes.is_deployment
	not kubernetes.required_deployment_labels
	msg = sprintf("%s %s must include Kubernetes recommended labels: https://kubernetes.io/docs/concepts/overview/working-with-objects/common-labels/#labels", [kubernetes.kind, kubernetes.name])
}

warn[msg] {
	kubernetes.is_deployment
	kubernetes.containers[container]
	[image_name, tag] = kubernetes.split_image(container.image)
	not tag
	msg := sprintf("%s in the %s %s has an image, %s, doesn't specify a valid tag", [container.name, kubernetes.kind, kubernetes.name, image_name])
}

warn[msg] {
	kubernetes.is_deployment
	kubernetes.containers[container]
	[image_name, "latest"] = kubernetes.split_image(container.image)
	msg = kubernetes.format(sprintf("%s in the %s %s has an image, %s, using the latest tag", [container.name, kubernetes.kind, image_name, kubernetes.name]))
}
