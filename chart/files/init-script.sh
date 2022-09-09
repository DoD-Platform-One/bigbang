#!/bin/bash

chown 2002.2002 /var/atlassian/confluence-datacenter/
           
# Get ips of cluster nodes from confluence service
if [ -f ${CONFLUENCE_HOME}/confluence.cfg.xml ]; then
  if [ -z "${CLUSTER_PEER_IPS}" ]; then
    # This is a special case, where confluence is running in kubernetes, not on plain docker host.
    KUBE_TOKEN=$(</var/run/secrets/kubernetes.io/serviceaccount/token)
    # Note: In the command below, "this node" will not show up in the service endpoints,
    #       because it is still "booting up" and "not ready".
    CLUSTER_PEER_IPS=$(curl -sSk -H "Authorization: Bearer $KUBE_TOKEN" https://$KUBERNETES_SERVICE_HOST:$KUBERNETES_PORT_443_TCP_PORT/api/v1/namespaces/${CONFLUENCE_NAMESPACE}/endpoints/${CONFLUENCE_SERVICE_NAME} | jq -r .subsets[].addresses[].ip | paste -sd "," -)

  else
    # This is a special case, which caters for confluence running on plain docker host instead of Kubernetes.
    echo "Using CLUSTER_PEER_IPS = ${CLUSTER_PEER_IPS} , as received by ENV variable."

  fi

  # Lets manage POD_IP first, as it will be used later.
  # So, POD_IP is being obtained through the helm chart.
  # But, if the container is being run without Kubernetes, such as on plain docker host, then POD_IP will be empty.
  # In that case, we need to find the IP of this pod/container ourselves, using 'ip addr'
  if [ -z "${POD_IP}" ]; then
    POD_IP=$(ip addr | egrep -w inet | egrep -e "eth|ens" | awk '{print $2}' | cut -d '/' -f1)
  fi

  if [ -z "${CLUSTER_PEER_IPS}" ]; then
    # if there are no peer IPs found, then we need to add at least the IP of this node in the cluster.peers file.
    CLUSTER_PEER_IPS=${POD_IP}
  else
    # append our IP to the peers list:
    CLUSTER_PEER_IPS="${POD_IP},${CLUSTER_PEER_IPS}"
  fi

  echo "Updating ${CONFLUENCE_HOME}/confluence.cfg.xml with PEER IPS: ${CLUSTER_PEER_IPS} ..."
  xmlstarlet edit -L -u "//properties/property[@name='confluence.cluster.peers']" \
    --value "${CLUSTER_PEER_IPS}" ${CONFLUENCE_HOME}/confluence.cfg.xml
else
  echo "The file ${CONFLUENCE_HOME}/confluence.cfg.xml was not found; because, this may be the first node - still booting up."
fi
