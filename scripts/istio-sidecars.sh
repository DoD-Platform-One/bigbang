#!/bin/bash
# List or restart pods still running an Istio sidecar (for sidecar -> ambient migration).
#
# Istio uses native sidecars, so istio-proxy is in .spec.initContainers (a sidecar pod
# shows 2/2 while .spec.containers length is 1) -- both container lists are checked.
# ztunnel's own container is also named istio-proxy, so it is excluded by label. Istio
# ingress gateways are the Envoy gateway itself (not ambient-captured), so they are
# excluded too and left running.
#
# Usage:
#   istio-sidecars.sh list    [-n NAMESPACE]   # list pods that still carry a sidecar
#   istio-sidecars.sh restart [-n NAMESPACE]   # rolling-restart their owning workloads
#
# With no -n, all namespaces are scanned.

set -euo pipefail

usage() {
  echo "Usage: $0 {list|restart} [-n NAMESPACE]" >&2
  exit 2
}

ACTION="${1:-}"
shift || usage

NS_ARGS=(--all-namespaces)
NS_LABEL="all namespaces"
while getopts "n:" opt; do
  case "$opt" in
    n) NS_ARGS=(-n "$OPTARG"); NS_LABEL="namespace $OPTARG" ;;
    *) usage ;;
  esac
done

# Emit "namespace<TAB>pod" for every pod carrying an istio-proxy sidecar, excluding ztunnel.
sidecar_pods() {
  kubectl get pods "${NS_ARGS[@]}" -o json \
    | jq -r '.items[]
        | select(((.spec.initContainers // []) | map(.name) | index("istio-proxy"))
                 or ((.spec.containers // []) | map(.name) | index("istio-proxy")))
        | select(.metadata.labels.app != "ztunnel")
        | select((.metadata.labels.istio // "") == "")
        | select((.metadata.labels["operator.istio.io/component"] // "") != "IngressGateways")
        | select(has("metadata") and (.metadata.labels | has("gateway.networking.k8s.io/gateway-name") | not))
        | .metadata.namespace + "\t" + .metadata.name'
}

# Resolve a pod to its owning controller as "namespace<TAB>kind/name", following the
# ReplicaSet -> Deployment hop so we restart the Deployment rather than the ReplicaSet.
pod_owner() {
  local ns="$1" pod="$2" kind name
  read -r kind name < <(kubectl get pod "$pod" -n "$ns" -o \
    jsonpath='{.metadata.ownerReferences[0].kind} {.metadata.ownerReferences[0].name}')
  if [ "$kind" = "ReplicaSet" ]; then
    read -r kind name < <(kubectl get rs "$name" -n "$ns" -o \
      jsonpath='{.metadata.ownerReferences[0].kind} {.metadata.ownerReferences[0].name}')
  fi
  [ -n "${kind:-}" ] && [ -n "${name:-}" ] && printf '%s\t%s/%s\n' "$ns" "$kind" "$name"
}

case "$ACTION" in
  list)
    pods="$(sidecar_pods)"
    if [ -z "$pods" ]; then
      echo "No pods with an istio-proxy sidecar found in $NS_LABEL."
      exit 0
    fi
    echo "Pods with an istio-proxy sidecar in $NS_LABEL:"
    printf '%s\n' "$pods" | column -t
    ;;

  restart)
    pods="$(sidecar_pods)"
    if [ -z "$pods" ]; then
      echo "No pods with an istio-proxy sidecar found in $NS_LABEL. Nothing to restart."
      exit 0
    fi

    # Collect the distinct owning workloads across all sidecar pods.
    owners=""
    while IFS=$'\t' read -r ns pod; do
      owner="$(pod_owner "$ns" "$pod" || true)"
      [ -n "$owner" ] && owners+="$owner"$'\n'
    done <<< "$pods"
    owners="$(printf '%s' "$owners" | sort -u | sed '/^$/d')"

    if [ -z "$owners" ]; then
      echo "Found sidecar pods but could not resolve owning workloads; nothing to restart." >&2
      exit 1
    fi

    # kubectl rollout restart only supports Deployment/StatefulSet/DaemonSet. Other owners
    # (e.g. Jobs) can carry a sidecar but cannot be rolled -- report them so they can be
    # handled manually instead of silently skipping or aborting the loop.
    restartable=""
    unsupported=""
    while IFS=$'\t' read -r ns res; do
      case "${res%%/*}" in
        Deployment|StatefulSet|DaemonSet) restartable+="$ns"$'\t'"$res"$'\n' ;;
        *) unsupported+="$ns"$'\t'"$res"$'\n' ;;
      esac
    done <<< "$owners"
    restartable="$(printf '%s' "$restartable" | sed '/^$/d')"
    unsupported="$(printf '%s' "$unsupported" | sed '/^$/d')"

    if [ -n "$restartable" ]; then
      echo "Restarting workloads with sidecar pods in $NS_LABEL:"
      printf '%s\n' "$restartable" | column -t
      while IFS=$'\t' read -r ns res; do
        kubectl rollout restart "$res" -n "$ns"
      done <<< "$restartable"
    fi

    if [ -n "$unsupported" ]; then
      echo >&2
      echo "Skipped owners that cannot be rolling-restarted (restart or recreate manually):" >&2
      printf '%s\n' "$unsupported" | column -t >&2
    fi
    ;;

  *)
    usage
    ;;
esac
