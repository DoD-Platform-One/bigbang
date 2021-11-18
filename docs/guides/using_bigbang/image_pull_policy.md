# ImagePullPolicy at Big Bang Level

Big Bang is currently working to standardize the adoption of a global image pull policy so that customers can set a single value and have it passed to all packages. This work is not yet complete, but should allow customers easier control over their global pull policy.

In the meantime we have begun to document the package overrides required in preparation for this change.

# ImagePullPolicy per Package

| Package | Default | Value Override |
|---|---|---|
| Istio Controlplane | None | <pre lang="yaml">istio:<br>  values:<br>    imagePullPolicy: IfNotPresent</pre> |
| Istio Operator | `IfNotPresent` | <pre lang="yaml">istio-operator:<br>  values:<br>    imagePullPolicy: IfNotPresent</pre> |
| Jaeger | `Always` | <pre lang="yaml">jaeger:<br>  values:<br>    image:<br>      pullPolicy: IfNotPresent</pre> |
| Kiali | `IfNotPresent` | <pre lang="yaml">kiali:<br>  values:<br>    image:<br>      pullPolicy: IfNotPresent<br>    cr:<br>      spec:<br>        deployment:<br>          image_pull_policy: IfNotPresent</pre> |
| Cluster Auditor | `Always` | <pre lang="yaml">clusterAuditor:<br>  values:<br>    image:<br>      imagePullPolicy: IfNotPresent</pre> |
| OPA Gatekeeper | `IfNotPresent` | <pre lang="yaml">gatekeeper:<br>  values:<br>    postInstall:<br>      labelNamespace:<br>        image:<br>          pullPolicy: IfNotPresent<br>    postUpgrade:<br>      cleanupCRD:<br>        image:<br>          pullPolicy: IfNotPresent<br>    image:<br>      pullPolicy: IfNotPresent</pre> |
| Elasticsearch / Kibana | `IfNotPresent` | <pre lang="yaml">logging:<br>  values:<br>    imagePullPolicy: IfNotPresent</pre> |
| ECK Operator | `IfNotPresent` | <pre lang="yaml">eckoperator:<br>  values:<br>    image:<br>      pullPolicy: IfNotPresent</pre> |
| Fluentbit | `Always` | <pre lang="yaml">fluentbit:<br>  values:<br>    image:<br>      pullPolicy: IfNotPresent</pre> |
| Monitoring | Varies | <pre lang="yaml">monitoring:<br>  values: <br>    kube-state-metrics:<br>      image:<br>        pullPolicy: IfNotPresent<br>    grafana:<br>      image:<br>        pullPolicy: IfNotPresent<br>    prometheus-node-exporter:<br>      image:<br>        pullPolicy: IfNotPresent<br>    prometheusOperator:<br>      image:<br>        pullPolicy: IfNotPresent<br>      admissionWebhooks:<br>        cleanupProxy:<br>          image:<br>            pullPolicy: IfNotPresent<br>        patch: <br>          image:<br>            pullPolicy: IfNotPresent</pre> |
| Twistlock | `IfNotPresent` | <pre lang="yaml">twistlock:<br>  values:<br>    console:<br>      image:<br>        imagePullPolicy: IfNotPresent</pre>  |
| ArgoCD | Varies | <pre lang="yaml">addons:<br>  argocd:<br>    values:<br>      global:<br>        image:<br>          imagePullPolicy: IfNotPresent<br>      controller:<br>        image:<br>          imagePullPolicy: IfNotPresent<br>      dex:<br>        image:<br>          imagePullPolicy: IfNotPresent<br>      redis-bb:<br>        image:<br>          pullPolicy: IfNotPresent<br>      server:<br>        image:<br>          imagePullPolicy: IfNotPresent<br>      repoServer:<br>        image:<br>          imagePullPolicy: IfNotPresent</pre> |
| Authservice | `IfNotPresent` | <pre lang="yaml">addons:<br>  authservice:<br>    values:<br>      image:<br>        pullPolicy: IfNotPresent</pre> |
| MinIO Operator | `IfNotPresent` | <pre lang="yaml">addons:<br>  minioOperator:<br>    values:<br>      operator:<br>        image:<br>          pullPolicy: IfNotPresent</pre> |
| MinIO | `IfNotPresent` | <pre lang="yaml">addons:<br>  minio:<br>    values:<br>      tenants:<br>        image:<br>          pullPolicy: IfNotPresent</pre> |
| Gitlab | None | <pre lang="yaml">addons:<br>  gitlab:<br>    values:<br>      global:<br>        image:<br>          pullPolicy: IfNotPresent</pre> |
| Gitlab Runners | `IfNotPresent` | <pre lang="yaml">addons:<br>  gitlabRunner:<br>    values:<br>      imagePullPolicy: IfNotPresent</pre> |
| Nexus | `IfNotPresent` | <pre lang="yaml">addons:<br>  nexus:<br>    values:<br>      image:<br>        pullPolicy: IfNotPresent<br>      job_image:<br>        pullPolicy: IfNotPresent</pre> |
| Sonarqube | `IfNotPresent` | <pre lang="yaml">addons:<br>  sonarqube:<br>    values:<br>      image:<br>        pullPolicy: IfNotPresent</pre> |
| Anchore | `IfNotPresent` | <pre lang="yaml">addons:<br>  anchore:<br>    values:<br>      anchoreGlobal:<br>        imagePullPolicy: IfNotPresent<br>      anchoreEnterpriseGlobal:<br>        imagePullPolicy: IfNotPresent<br>      anchoreEnterpriseUi:<br>        imagePullPolicy: IfNotPresent</pre> |
| Mattermost Operator | `IfNotPresent` | <pre lang="yaml">addons:<br>  mattermostoperator:<br>    values:<br>      image:<br>        imagePullPolicy: IfNotPresent</pre> |
| Mattermost | `IfNotPresent` | <pre lang="yaml">addons:<br>  mattermost:<br>    values:<br>      image:<br>        imagePullPolicy: IfNotPresent</pre> |
| Velero | `IfNotPresent` | <pre lang="yaml">addons:<br>  velero:<br>    values:<br>      image:<br>        pullPolicy: IfNotPresent</pre> |
| Keycloak | `IfNotPresent` | <pre lang="yaml">addons:<br>  keycloak:<br>    values:<br>      image:<br>        pullPolicy: IfNotPresent<br>      pgchecker:<br>        image:<br>          pullPolicy: IfNotPresent</pre> |
