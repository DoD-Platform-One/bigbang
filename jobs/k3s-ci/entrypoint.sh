#!/bin/sh

mkdir -p /etc/rancher/k3s
cat <<EOF > /etc/rancher/registries.yaml
mirrors:
  "*":
    endpoint:
      - "http://registry:5000"

EOF

/bin/kubeconfig_server &
/bin/k3s "$@"
