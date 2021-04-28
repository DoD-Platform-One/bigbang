package main

import data.lib.kubernetes

# https://kubesec.io/basics/containers-resources-limits-memory
warn[msg] {
	kubernetes.containers[container]
	not container.resources.requests.memory
	msg = kubernetes.format(sprintf("%s in the %s %s does not have a memory requests set", [container.name, kubernetes.kind, kubernetes.name]))
}

# https://kubesec.io/basics/containers-resources-limits-cpu/
warn[msg] {
	kubernetes.containers[container]
	not container.resources.requests.cpu
	msg = kubernetes.format(sprintf("%s in the %s %s does not have a CPU requests set", [container.name, kubernetes.kind, kubernetes.name]))
}

# https://kubesec.io/basics/containers-resources-limits-memory
warn[msg] {
	kubernetes.containers[container]
	not container.resources.limits.memory
	msg = kubernetes.format(sprintf("%s in the %s %s does not have a memory limit set", [container.name, kubernetes.kind, kubernetes.name]))
}

# https://kubesec.io/basics/containers-resources-limits-cpu/
warn[msg] {
	kubernetes.containers[container]
	not container.resources.limits.cpu
	msg = kubernetes.format(sprintf("%s in the %s %s does not have a CPU limit set", [container.name, kubernetes.kind, kubernetes.name]))
}

# https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/#create-a-pod-that-gets-assigned-a-qos-class-of-guaranteed
warn[msg] {
	kubernetes.containers[container]
	kubernetes.guaranteed_qos(container)
	msg = sprintf("%s in the %s %s does not have QoS class of Guaranteed", [container.name, kubernetes.kind, kubernetes.name])
}