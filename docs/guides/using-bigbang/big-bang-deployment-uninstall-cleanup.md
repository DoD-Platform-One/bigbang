# Big Bang Deployment: Uninstall & Cleanup Guide

This guide explains how to remove your Big Bang deployment—including all Helm releases, namespaces, persistent data, and custom resources—from your Kubernetes cluster.

  Note: There may be potential items that will need to be removed manually if the helm commands failes to delete them. Please check the namespaces for any of these items.
  * services
  * configmap
  * secret
  * serviceaccount
  * lease
  * clusterrolebinding
  * clusterrole
---

## 1. Uninstall the Big Bang Helm Release

helm uninstall bigbang -n bigbang

## 2. Delete the Big Bang Namespace

kubectl delete namespace bigbang

## 3. Remove FluxCD Resources 

flux uninstall --namespace=flux-system --silent
kubectl delete namespace flux-system

## 4. Delete Other Namespaces Created by Big Bang Packages

Check for and delete any additional namespaces (e.g., `istio-system`, `keycloak`, `gitlab`, etc.):

kubectl get namespaces
kubectl delete namespace <namespace-name>

## 5. Remove Stuck Namespaces (if any)

If a namespace is stuck in "Terminating", remove its finalizers:

kubectl get namespace <namespace-name> -o json | \
  jq '.spec.finalizers = []' | \
  kubectl replace --raw "/api/v1/namespaces/<namespace-name>/finalize" -f -

Or use the helper script if available:

https://repo1.dso.mil/big-bang/bigbang/-/blob/master/scripts/remove-ns-finalizer.sh <namespace-name>

## 6. Delete Persistent Volume Claims and Persistent Volumes

kubectl get pvc --all-namespaces
kubectl delete pvc <pvc-name> -n <namespace>
kubectl get pv
kubectl delete pv <pv-name>

## 7. Remove Custom Resource Definitions (CRDs)

To remove CRDs installed by Big Bang or its packages:

kubectl get crd | grep -E 'istio|keycloak|gitlab|neuvector|anchore' | awk '{print $1}' | xargs kubectl delete crd

## 8. Verify Cleanup

Check for any remaining resources:

kubectl get all --all-namespaces
kubectl get namespaces

Delete any remaining resources as needed.

**Note:**  
If you used additional override files or installed extra components, ensure you remove their resources and namespaces as well.

## Cluster Resource Stats (Example)

- **Pods:**  
  `kubectl get pods --all-namespaces | wc -l`

- **Namespaces:**  
  `kubectl get namespaces | wc -l`

- **Persistent Volume Claims:**  
  `kubectl get pvc --all-namespaces | wc -l`

- **Persistent Volumes:**  
  `kubectl get pv | wc -l`

- **Custom Resource Definitions:**  
  `kubectl get crd | wc -l`


## References

- [Big Bang Troubleshooting Guide](docs/understanding-bigbang/concepts/troubleshooting.md)
- [Supported Package Integration](docs/developer/package-integration/supported.md)