# Upgrading Big Bang

## Before Upgrading
Before upgrading Big Bang, please first check the Release Notes and the Changelog to look for any notes that apply to Big Bang Updates and Package Updates.

There are two important things to review when upgrading:
1. "Upgrade Notices" in the Big Bang release notes: 
  - These capture any critical notes that the Big Bang development team identified during the release process. 
    - This may be an update to Flux which requires a "manual" application, or a change to a specific package that we deem important to include.
2. Changelog entries for individual packages that you are deploying: 
  - Oftentimes individual packages could have breaking changes depending on your configuration. 
  - It is important to review the changes included with those packages and determine if your configuration needs to be adjusted as a result.

## Supported Upgrades
Generally, we expect upgrades to be done one minor release at a time.  If necessary, it is possible to jump past several versions provided there is careful review of the release notes in between the versions and there are no problems.

NOTE: It is recommended that upgrades first be tested in a staging environment that mirrors the production environment so that errors are caught early.

## Upgrading a Single Package
Packages in Big Bang can be updated one at a time.
Upgrading a single package in Big Bang is done by changing the tag in the values for that package.  This should be done in the overriding values in the customer template.

For a git repository:

```yaml
istiod:
  sourceType: "git"
  git:
    repo: https://repo1.dso.mil/big-bang/product/packages/istiod.git
    path: "./chart"
    tag: "1.26.0-bb.0"

```

For a helm repository:

```yaml
istiod:
  sourceType: "helmRepo"
  helmRepo:
    repoName: "registry1"
    chartName: "istiod"
    tag: "1.26.0-bb.0"
```

These values are in `chart/values.yaml` of the Big Bang helm chart.
When using the [Customer Template](https://repo1.dso.mil/big-bang/customers/template) you can make these changes in either the base values (`bigbang/base/values.yaml`) or in each environment's values file (ex: `bigbang/dev/configmap.yaml`).

## Upgrading Big Bang umbrella deployment
To upgrade your umbrella deployment of Big Bang when using the [Customer Template](https://repo1.dso.mil/big-bang/customers/template) you have two options:
- Edit `base/kustomization.yaml` and change the value for the [base `ref`](https://repo1.dso.mil/big-bang/customers/template/-/blob/main/base/kustomization.yaml#L4) to the new version. This will update all environments leveraging this base (dev, prod, etc).
```yaml
namespace: bigbang
resources:
  - https://repo1.dso.mil/big-bang/bigbang.git//base?ref=1.57.1
```

- Edit the environment specific Kustomization (ex: `dev/kustomization.yaml`) to use the new version under the [ref/patch section](https://repo1.dso.mil/big-bang/customers/template/-/blob/main/dev/kustomization.yaml#L18-21).
```yaml
  spec:
    interval: 1m
    ref:
      $patch: replace
      tag: "1.57.1"
```

## Verifying the Upgrade
After upgrading the cluster, there are some places to look to verify that the upgrade was completed successfully.

### Verify Helm releases 
Verify all the helm releases have succeeded
   
   If everything has updated successfully you should see `Release reconciliation succeeded` as the status for each HelmRelease.
```bash
❯ k get hr -A
NAMESPACE   NAME              AGE    READY   STATUS
bigbang     kyverno           5h1m   True    Release reconciliation succeeded
bigbang     kyvernopolicies   5h1m   True    Release reconciliation succeeded
bigbang     istio-crds        5h1m   True    Release reconciliation succeeded
bigbang     istiod            5h1m   True    Release reconciliation succeeded
bigbang     istio-gateway     5h1m   True    Release reconciliation succeeded
```

### Verify Pods
 - Verify that there are all pods are either `Running` or `Completed.`
 - Look for any pods that recently restarted (crashing recently).
   - Below see an example of a pod that has restarted multiple times in a short time.
```bash
❯ k get pod -A
NAMESPACE           NAME                                                        READY   STATUS    RESTARTS   AGE
kube-system         local-path-provisioner-5ff76fc89d-xd85h                     1/1     Running   0          22m
...
monitoring          alertmanager-monitoring-monitoring-kube-alertmanager-0      3/3     Running   7          3m
```

### Verify Image Versions for Specific Packages
 - Check for specific package versions (image version on pods).
   - There may be cases where you are hoping to use new features in a new package version, as such it can be beneficial to validate that package did update to the new version as expected.
   - It can also be important to validate Istio sidecar versions, especially for packages outside of Big Bang core/addons. See an example of checking the image version of the running pod below:
```bash
❯ kubectl get po -n istio-system -o yaml|grep image|head -1
      image: registry1.dso.mil/ironbank/opensource/istio/pilot:1.25.2
```
### Check Package Usability
 - Validate the UI for web applications loads properly.
   - This could be through a basic `curl` check or similar to confirm UIs are up and healthy.
 - You may configure and use certain applications in unique ways.
   - It is important to validate those specific applications/features are functioning as expected post-upgrade.

## Upgrade Troubleshooting
Usually, a good place to start with troubleshooting is to identify which package had issues upgrading. After identifying the package that had problems it can be helpful to re-review the release notes and changelog for that specific package to see if any changes were missed that may have caused the upgrade issue you ran into.

Specific troubleshooting steps for common issues will be added here in the future.
