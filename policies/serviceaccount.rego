package main

import data.lib.kubernetes

warn[msg] {
	kubernetes.pods[pod]
	kubernetes.default_serviceaccount(pod.spec)
	msg := sprintf("%s %s is using default Service Account", [kubernetes.kind, kubernetes.name])
}
