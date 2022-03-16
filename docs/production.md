# Big Bang Production Configuration

[[_TOC_]]

## Gatekeeper
The gatekeeper `values` section should resemble below when deploying to production.

```yaml
# OPA Gatekeeper
#
gatekeeper:
  # -- Toggle deployment of OPA Gatekeeper.
  enabled: true
  git:
    repo: https://repo1.dso.mil/platform-one/big-bang/apps/core/policy.git
    path: "./chart"
    tag: "3.5.1-bb.2"

  # -- Flux reconciliation overrides specifically for the OPA Gatekeeper Package
  flux: {}

  # -- Values to passthrough to the gatekeeper chart: https://repo1.dso.mil/platform-one/big-bang/apps/core/policy.git
  values:
      violations:
        allowedDockerRegistries:
          match:
            excludedNamespaces: 
              - kube-system # ignored as the kubernetes distro cannot be controlled

  # -- Post Renderers.  See docs/postrenders.md
  postRenderers: []
```

To validate it was deployed correctly on your cluster run the following command:

`kubectl get k8sallowedrepos.constraints.gatekeeper.sh/allowed-docker-registries -o yaml`

You should only see `kube-system` under `excludedNamespaces` section.

Output:

```yaml
  name: allowed-docker-registries
  resourceVersion: "10390"
  uid: b51b3887-3cf8-4495-b37e-fb8ef31755db
spec:
  enforcementAction: deny
  match:
    excludedNamespaces:
    - kube-system
    kinds:
    - apiGroups:
      - ""
      kinds:
      - Pod
  parameters:
    exemptContainers: []
    repos:
    - registry1.dso.mil
    - registry.dso.mil
```

## Gitlab
This section provides suggested settings for Gitlab operational/production environments.

### Use external database service
For production deployments you must externalize the database service. BigBang will pass through the most common value overrides to the Gitlab Package chart.   
Disable the internal postgres by configuring an external database in the BigBang values.
```yaml
addons:
  gitlab: 
    database:
      host:
      port:
      database:
      username:
      password:
```

### Use external object storage 
For production deployments you must externalize object storage service. BigBang will pass through the most common value overrides to the Gitlab Package chart.  
Disable the internal MinIO instance by configuring an external object storage service.
```yaml
addons:
  gitlab:
    objectStorage:
      type:
      endpoint:
      region:
      accessKey:
      accessSecret:
      bucketPrefix:
      iamProfile:
```

### Flux settings
Large Gitlab installations should increase the Gitlab specific HelmRelease timeout value to around 30m to 45m and the Gitlab specific HelmRelease retries value should be adjusted to around 8 to 10.
```yaml
addons:
  gitlab:
    flux:
      timeout: 30m
      upgrade:
        remediation:
          retries: 8
```

### Kubernetes resource request/limit settings
K8s resource requests/limits for webservice and gitaly workloads should be increased from the defaults. Gitlab engineers state predicting Gitaly's resource consumption is very difficult, and will require testing to find the applicable limits/requests for each individual installation. See this [Gitlab Epic](https://gitlab.com/groups/gitlab-org/-/epics/6127) for more information. See the [gitlab/docs/k8s-resources.md](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab/-/blob/main/docs/k8s-resources.md) for a list of all possible configuration values. Use BigBang values overrides to change the Gitlab resource settings.  
Recommended starting point:
```yaml
addons:
  gitlab:
    values:
      gitlab:
        webservice:
          resources:
            limits:
              cpu: 2
              memory: 4G
            requests:
              cpu: 2
              memory: 4G
        gitaly:
          resources:
            limits:
              cpu: 2
              memory: 4G
            requests:
              cpu: 2
              memory: 4G
```

### Backup and rename gitlab-rails-secret
An operational deployment of Gitlab should backup and re-create the Gitlab Rails Encryption information as a secret with a different name as [documented here](https://docs.gitlab.com/charts/installation/secrets.html#gitlab-rails-secret). Using a custom secret name can help prevent accidental overwriting. 
To make the secret creation easier, the existing secret can be copied and modified with a different name.
```bash
kubectl get secret/gitlab-rails-secret -n gitlab -o yaml > gitlab-rails-custom-secret.yaml
```
Edit the file and change the name of the secret. Example:
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: gitlab-rails-custom-secret
```
Use GitOps configuration as code (CaC) and commit the custom rails secret to your GitOps repository. You should encrypt the custom rails secret keys in the GitOps repository to preserve security. 
Then the following Gitlab helm chart value `global.railsSecrets.secret` can be overridden to point to the custom rails secret.
```yaml
addons:
  gitlab:
    values:
      global:
        railsSecrets:
          secret:  gitlab-rails-custom-secret
```
The custom rails secret should be backed up somewhere secure outside the cluster if not included in your GitOps code repository.

**If the Kubernetes gitlab-rails-secret happens to get overwritten Gitlab will no longer be able to access the encrypted data in the database.**

You will get errors like this in the logs.
```text
OpenSSL::Cipher::CipherError ()
```
Many things break when this happens and the recovery is ugly with serious user impacts.  

At a minimum an operational deployment of Gitlab should export and save the gitlab-rails-secret somewhere secure outside the cluster.
```bash
kubectl get secret/gitlab-rails-secret -n gitlab -o yaml > cya.yaml
```

