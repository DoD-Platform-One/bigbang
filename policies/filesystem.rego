package main

import data.lib.kubernetes

warn[msg] {
	kubernetes.volumes[volume]
	kubernetes.hostpath(volume)
	msg = sprintf("The %s %s is mounting hostpath %s", [kubernetes.kind, kubernetes.name, volume.hostPath.path])
}

# https://kubesec.io/basics/containers-securitycontext-readonlyrootfilesystem-true/
warn[msg] {
	kubernetes.containers[container]
	kubernetes.no_read_only_filesystem(container)
	msg = kubernetes.format(sprintf("%s in the %s %s is not using a read only root filesystem", [container.name, kubernetes.kind, kubernetes.name]))
}