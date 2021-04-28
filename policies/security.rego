package main

import data.lib.kubernetes

# https://kubesec.io/basics/containers-securitycontext-privileged-true/
warn[msg] {
	kubernetes.containers[container]
	kubernetes.privileged(container)
	msg = sprintf("%s in the %s %s is privileged", [container.name, kubernetes.kind, kubernetes.name])
}

# https://kubesec.io/basics/containers-securitycontext-privileged-true/
warn[msg] {
	kubernetes.pods[pod]
	kubernetes.privileged(pod.spec)
	msg = sprintf("%s %s is privileged", [kubernetes.kind, kubernetes.name])
}

# https://kubesec.io/basics/containers-securitycontext-runasnonroot-true/
warn[msg] {
	kubernetes.containers[container]
	not container.securityContext.runAsNonRoot = true
	msg = kubernetes.format(sprintf("%s in the %s %s has ability to run as root", [container.name, kubernetes.kind, kubernetes.name]))
}

# https://kubesec.io/basics/containers-securitycontext-runasuser/
warn[msg] {
	kubernetes.containers[container]
	issue = kubernetes.runasuser(container)
	msg = kubernetes.format(sprintf("%s in the %s %s %s", [container.name, kubernetes.kind, kubernetes.name, issue]))
}

# https://kubesec.io/basics/containers-securitycontext-runasuser/
warn[msg] {
	kubernetes.pods[pod]
	issue = kubernetes.runasuser(pod.spec)
	msg = kubernetes.format(sprintf("%s %s %s", [kubernetes.kind, kubernetes.name, issue]))
}