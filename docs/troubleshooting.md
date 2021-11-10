# Appendix B - Big Bang Troubleshooting

- [Appendix B - Big Bang Troubleshooting](#appendix-b---big-bang-troubleshooting)
  - [Iron Bank authentication](#iron-bank-authentication)
  - [Flux install](#flux-install)
  - [Git Repository](#git-repository)
  - [ConfigMap or Secrets](#configmap-or-secrets)
  - [Helm Release](#helm-release)
  - [Kustomization](#kustomization)
  - [Packages](#packages)

Big Bang can take a long time to run.  After making changes, it could take 10-15 minutes to take effect.  Use the [sync.sh](../scripts/sync.sh) script to speed this up.

Big Bang is configured to retry failed package installations and upgrades.  Before concluding you have a failure, make sure you allow Big Bang to attempt to resolve dependencies and retry.

## Iron Bank authentication

| Symptom | Cause | Resolution |
|--|--|--|
| Despite entering correct credentials, get `unauthorized: authentication required` from Iron Bank | Using a non-robot account with an expired token | Login with the non-robot account manually at `registry1.dso.mil`, then retry.  For production, contact the Iron Bank team to obtain a robot account and update pull credentials to use it in your environment |

## Flux install

Helpful debugging commands:

```shell
# Get the status
kubectl get pods -n flux-system

# Get the logs
kubectl get events -n flux-system
```

| Symptom | Cause | Resolution |
|--|--|--|
| Install script timed and pods are still pulling the image | Slow connection to docker registry | Adjust `--timeout` value in `flux install` to wait longer |
| Pod status is `ImagePullBackOff` or `ErrImagePull` | Bad registry, version, or credentials | Fix the `--registry`, `--version`, or `--image-pull secret` options or use the `./scripts/install_flux.sh` script for pulling from Iron Bank |

## Git Repository

Helpful debugging commands:

```shell
# Get the status
kubectl get gitrepositories -A

# Get the logs
kubectl get events --field-selector involvedObject.kind=GitRepository -A
```

| Symptom | Cause | Resolution |
|--|--|--|
| `unable to clone ... error: authentication required` | Pull credentials for Git invalid or not provided | Add credentials to a `Secret` and reference it in `GitRepository.spec.secretRef.name`.  If possible, encrypt the secret and include it in the Kustomization deployment for your environment.
| `auth secret error: Secret ... not found` | `GitRepository` is trying to use credentials but cannot find the `Secret` | Make sure the secret exists and is in the same namespace as the `GitRepository` resource.   If possible, encrypt the secret and include it in the Kustomization deployment for your environment.
| `unable to clone ... error: repository not found` | Invalid Git url | Fix url for Git repository and redeploy |
| `unable to clone ... error: couldn't find remote ref` | Invalid branch or tag | Fix branch or tag for Git repository and redeploy |

## ConfigMap or Secrets

| Symptom | Cause | Resolution |
|--|--|--|
|`ConfigMap` or `Secret` does not exist| GitRepository or Kustomization failed.  Namespace was incorrect. | Use [GitRepository](#git-repository) and [Kustomization](#kustomization) sections to troubleshoot.  Use `kubectl get secrets,configmaps -A` to verify resource was not in the wrong Namespace. |

## Helm Release

Helpful debugging commands:

```shell
# Get the status
kubectl get hr -A

# Get the logs
kubectl get events --field-selector involvedObject.kind=HelmRelease -A

# Describe the HelmRelease to get more information
kubectl describe hr <NAME> -n bigbang

# Get all logs/events for a specific HelmRelease object
flux logs --kind=HelmRelease --namespace bigbang --name <NAME>
```

| Symptom | Cause | Resolution |
|--|--|--|
| `Reconciliation in Progress` | This is normal and indicates flux is currently applying updates | Wait |
| `dependency ... is not ready` | This is normal and indicates flux is currently waiting on another resource to complete | Wait |
| `Error: YAML parse error on ...` | Syntax error in helm chart | Use `helm template` to narrow down the problem.  Fix it and commit to Git |
| `Helm install failed: failed to create resource ... unable to create new content in namespace because it is being terminated` | This seems to happen when a re-deploy of Big Bang occurs to early after a Big Bang delete. |  Try to remove the namespace using `kubectl get ns <stuck namespace> -o json | jq '.spec.finalizers = []' | kubectl replace --raw "/api/v1/namespaces/$NS/finalize" -f`.  If this does not work, a cluster restart may be necessary. |
| `Error: failed to download ...` | Path to Helm chart is incorrect | Find the HelmRelease configuration and update `spec.path` to the correct path of the helm chart |
| `Helm uninstall failed: uninstall: Release not loaded: ____: release: not found` | Helm install failed because of an error and a rollback/uninstall is attempted but release has not been installed. | Describe the HelmRelease in question or use flux to get the logs to get more info abut why it failed to install. |
| `reconciliation failed: Helm rollback failed: an error occurred while cleaning up resources. original rollback error: no XXXX with the name "XXXX" found: unable to cleanup resources: object not found, skipping delete` | This error happens when an upgrade fails and flux attempts a rollback but there are templates that have been renamed/removed. | Describe the HelmRelease in question or use flux to get the logs to get more info abut why exactly the upgrade failed. |

## Kustomization

Helpful debugging commands:

```shell
# Get the status
kubectl get kustomizations -A

# Get the logs
kubectl get events --field-selector involvedObject.kind=Kustomization -A
```

| Symptom | Cause | Resolution |
|--|--|--|
| `kustomization path not found` | `spec.path` in Kustomization resource in is incorrect | Fix `spec.path` and redeploy |
| `Source not found` | `spec.sourceRef` in Kustomization resource is incorrect | Fix `spec.sourceRef` to point to repository resource and redeploy |
| `decryption secret error: Secret ... not found` | SOPS private key secret is missing or misconfigured | Check `decryption` settings in the Kustomization resource to make sure `secretRef` is pointing to the correct secret.  Make sure the `Secret` holding the private key is deployed in the cluster. |
| `kustomize build failed: json: unknown field` | There is a syntax error with the kustomization files. | Use `kustomize build` on the `<env>` folder or `base` folder to narrow down the problem.  Fix the error and push to Git. |
| `evalsymlink failure ... no such file or directory` | A reference to a file in `kustomization.yaml` is incorrect | Use `kustomize build` on the `<env>` folder or `base` folder to narrow down the problem.  Fix the error and push to Git. |
| `Error: accumulating resources ...` | A reference to a base is incorrect | Use `kustomize build` on the `<env>` folder or `base` folder to narrow down the problem.Review the `bases:` section for correct paths to find the error.  Fix the error and push to Git. |
| `Error fetchingref: fatal: couldn't find remote ref ...` | The branch, tag, or sha used for a remote base is incorrect | Use `kustomize build` on the `<env>` folder or `base` folder to narrow down the problem.  It is likely the remote reference to the Big Bang's Kustomize in the `base` folder.  Review the `bases:` section for correct paths to find the error.  Fix the error and push to Git. |
| `Error: merging from generator ...` | Kustomize is trying to merge with a resource that is non-existent.  This is usually due to naming the merging `ConfigMap` or `Secret` incorrectly compared to a base `ConfigMap` or `Secret`. | Use `kustomize build` on the `<env>` folder or `base` folder to narrow down the problem.  Look for the keyword `merge` in the `kustomization.yaml` files and verify the `name` is correctly set. |

## Packages

Helpful debugging commands:

```shell
# Get the status
kubectl get deployments,po -n <namespace of package>

# Get the logs
kubectl get events --field-selector involvedObject.kind=Deployment -n <namespace of package>
kubectl get events --field-selector involvedObject.kind=Pod -n <namespace of package>
```
