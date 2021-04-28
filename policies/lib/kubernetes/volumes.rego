package lib.kubernetes

volumes[volume] {
	pods[pod]
	volume = pod.spec.volumes[_]
}