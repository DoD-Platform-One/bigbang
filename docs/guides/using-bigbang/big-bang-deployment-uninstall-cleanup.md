# Big Bang Deployment: Uninstall & Cleanup Guide

This guide explains how to remove your Big Bang deployment—including all helm releases, namespaces, persistent data, and custom resources from your Kubernetes cluster.

While this guide provides the basic steps to clean things up, every installation and cluster is different.  Additional commands and cleanup may be necessary depending on your specific installation to remove additional Kinds such as:

* clusterrole
* clusterrolebinding
* configmap
* lease
* services
* secret
* serviceaccount
* etc

---

## 1. Uninstall the Big Bang Helm Release

```bash
$ helm uninstall bigbang -n bigbang
```

## 2. Delete the Big Bang Namespace

```bash
$ kubectl delete namespace bigbang
```

## 3. Remove FluxCD Resources 

```bash
$ flux uninstall --namespace=flux-system --silent
$ kubectl delete namespace flux-system
```

## 4. Delete Additional Namespaces Created by Big Bang Packages

Check for and delete any additional namespaces (e.g., `istio-system`, `keycloak`, `gitlab`, etc.):

```bash
$ kubectl get namespaces
$ kubectl delete namespace <namespace-name>
```

## 5. Remove Namespaces that remain (if applicable)

If a namespace is stuck in "Terminating", you can remove its finalizers by running the following commands or by using a helper script found here: https://repo1.dso.mil/big-bang/bigbang/-/blob/master/scripts/remove-ns-finalizer.sh

```bash
$ kubectl get namespace <namespace-name> -o json | \
  jq '.spec.finalizers = []' | \
  kubectl replace --raw "/api/v1/namespaces/<namespace-name>/finalize" -f -
```

## 6. Delete Persistent Volume Claims and Persistent Volumes Used By Big Bang

```bash
$ kubectl get pvc --all-namespaces
$ kubectl delete pvc <pvc-name> -n <namespace>
$ kubectl get pv
$ kubectl delete pv <pv-name>
```

## 7. Remove Custom Resource Definitions (CRDs)

To remove CRDs installed by Big Bang or its packages:

```bash
$ kubectl get crd | grep -E 'istio|keycloak|gitlab|neuvector|anchore' | awk '{print $1}' | xargs kubectl delete crd
```

## 8. Verify Cleanup

Check for any remaining resources:

```bash
$ kubectl get all --all-namespaces
$ kubectl get namespaces
```

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