package main

import data.lib.kubernetes

# https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-a-liveness-command
warn[msg] {
	kubernetes.containers[container]
	not container.livenessProbe
	msg = sprintf("%s in the %s %s is missing livenessProbe", [container.name, kubernetes.kind, kubernetes.name])
}

# https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/#define-readiness-probes
warn[msg] {
	kubernetes.containers[container]
	not container.readinessProbe
	msg = sprintf("%s in the %s %s is missing readinessProbe", [container.name, kubernetes.kind, kubernetes.name])
}