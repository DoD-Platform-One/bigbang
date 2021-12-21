# ImagePullPolicy at Big Bang Level

Big Bang is currently working to standardize the adoption of a global image pull policy so that customers can set a single value and have it passed to all packages.

The global image pull policy has been adopted in Big Bang for the core packages and for addons. In the Big Bang values.yaml file, a global parameter has been created to set the global image pull policy (`imagePullPolicy` in values) and it gets passed down to all core packages and addons spec. The default value for this global policy is `IfNotPresent`.

We have also documented the package overrides required if you want to set a single package/pod with a different pull policy than the global.

# ImagePullPolicy per Package

| Package | Default | Value Override |
|---|---|---|
| Istio Controlplane | None | <pre lang="yaml">istio:<br>  values:<br>    imagePullPolicy: IfNotPresent</pre> |
| Istio Operator | `IfNotPresent` | <pre lang="yaml">istio-operator:<br>  values:<br>    imagePullPolicy: IfNotPresent</pre> |
| Jaeger | `Always` | <pre lang="yaml">jaeger:<br>  values:<br>    image:<br>      pullPolicy: IfNotPresent</pre> |
| Kiali | `IfNotPresent` | <pre lang="yaml">kiali:<br>  values:<br>    image:<br>      pullPolicy: IfNotPresent<br>    cr:<br>      spec:<br>        deployment:<br>          image_pull_policy: IfNotPresent</pre> |
| Cluster Auditor | `Always` | <pre lang="yaml">clusterAuditor:<br>  values:<br>    image:<br>      imagePullPolicy: IfNotPresent</pre> |
| OPA Gatekeeper | `IfNotPresent` | <pre lang="yaml">gatekeeper:<br>  values:<br>    postInstall:<br>      labelNamespace:<br>        image:<br>          pullPolicy: IfNotPresent<br>    postUpgrade:<br>      cleanupCRD:<br>        image:<br>          pullPolicy: IfNotPresent<br>    image:<br>      pullPolicy: IfNotPresent</pre> |
| Kyverno  | `IfNotPresent` | <pre lang="yaml">addons:<br>  kyverno:<br>    values:<br>      image:<br>        pullPolicy: IfNotPresent<br>      initImage:<br>        pullPolicy: IfNotPresent</pre> | 
| Elasticsearch / Kibana | `IfNotPresent` | <pre lang="yaml">logging:<br>  values:<br>    imagePullPolicy: IfNotPresent</pre> |
| ECK Operator | `IfNotPresent` | <pre lang="yaml">eckoperator:<br>  values:<br>    image:<br>      pullPolicy: IfNotPresent</pre> |
| Fluentbit | `Always` | <pre lang="yaml">fluentbit:<br>  values:<br>    image:<br>      pullPolicy: IfNotPresent</pre> |
| Loki | `IfNotPresent` | <pre lang="yaml">loki:<br>  values:<br>    image:<br>      pullPolicy: IfNotPresent</pre> |
| Monitoring | Varies | <pre lang="yaml">monitoring:<br>  values: <br>    kube-state-metrics:<br>      image:<br>        pullPolicy: IfNotPresent<br>    grafana:<br>      image:<br>        pullPolicy: IfNotPresent<br>      sidecar:<br>        imagePullPolicy: IfNotPresent<br>    prometheus-node-exporter:<br>      image:<br>        pullPolicy: IfNotPresent<br>    prometheusOperator:<br>      image:<br>        pullPolicy: IfNotPresent<br>      admissionWebhooks:<br>        cleanupProxy:<br>          image:<br>            pullPolicy: IfNotPresent<br>        patch: <br>          image:<br>            pullPolicy: IfNotPresent<br>    prometheus:<br>      prometheusSpec:<br>        containers:<br>          - name: "prometheus"<br>            imagePullPolicy: IfNotPresent<br>          - name: "config-reloader"<br>            imagePullPolicy: IfNotPresent<br>    alertmanager:<br>      alertmanagerSpec:<br>        containers:<br>          - name: "alertmanager"<br>            imagePullPolicy: IfNotPresent<br>          - name: "config-reloader"<br>            imagePullPolicy: IfNotPresent</pre> |
| Twistlock | `IfNotPresent` | <pre lang="yaml">twistlock:<br>  values:<br>    console:<br>      image:<br>        imagePullPolicy: IfNotPresent</pre>  |
| Promtail  | `IfNotPresent` | <pre lang="yaml">promtail:<br>  values:<br>    init:<br>      image:<br>        pullPolicy: IfNotPresent<br>    image:<br>      pullPolicy: IfNotPresent</pre>  |
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
| Vault    | `IfNotPresent` | <pre lang="yaml">addons:<br>  vault:<br>    values:<br>      injector:<br>        image:<br>          pullPolicy: IfNotPresent<br>      server:<br>        image:<br>          pullPolicy: IfNotPresent<br>      csi:<br>        image:<br>          pullPolicy: IfNotPresent</pre> |
