# ImagePullPolicy at Big Bang Level

Big Bang is currently working to standardize the adoption of a global image pull policy so that customers can set a single value and have it passed to all packages. This work is not yet complete, but should allow customers easier control over their global pull policy.

In the meantime we have begun to document the package overrides required in preparation for this change.

# ImagePullPolicy per Package

| Package | Default | Value Override |
|---|---|---|
| Istio Controlplane | None | <pre lang="yaml">istio:<br>  values:<br>    imagePullPolicy: IfNotPresent</pre> |
| Istio Operator | `IfNotPresent` | <pre lang="yaml">istio-operator:<br>  values:<br>    imagePullPolicy: IfNotPresent</pre> |
| Jaeger | Always | <pre lang="yaml">jaeger:<br>  values:<br>    image:<br>      pullPolicy: IfNotPresent</pre> |
| Kiali | IfNotPresent | <pre lang="yaml">kiali:<br>  values:<br>    image:<br>      pullPolicy: IfNotPresent<br></pre><br><pre lang="yaml">kiali:<br>  values:<br>    cr:<br>      spec:<br>        deployment:<br>          image_pull_policy: IfNotPresent</pre> |
| Cluster Auditor | Always | <pre lang="yaml">clusterAuditor:<br>  values:<br>    image:<br>      imagePullPolicy: IfNotPresent</pre> |
| OPA Gatekeeper | IfNotPresent | <pre lang="yaml">gatekeeper:<br>  values:<br>    postInstall:<br>      labelNamespace:<br>        image:<br>          pullPolicy: IfNotPresent<br>    image:<br>      pullPolicy: IfNotPresent</pre> |
| Elasticsearch / Kibana | None | No override available |
| ECK Operator | IfNotPresent | <pre lang="yaml">eckoperator:<br>  values:<br>    image:<br>      pullPolicy: IfNotPresent</pre> |
| Fluentbit | Always | <pre lang="yaml">fluentbit:<br>  values:<br>    image:<br>      pullPolicy: IfNotPresent</pre> |
| Monitoring | Varies | To be documented |
| Twistlock | `IfNotPresent` | <pre lang="yaml">twistlock:<br>  values:<br>    console:<br>      image:<br>        imagePullPolicy: IfNotPresent</pre>  |
| ArgoCD | IfNotPresent | To be documented |
| Authservice | IfNotPresent | <pre lang="yaml">addons:<br>  authservice:<br>    values:<br>      image:<br>        pullPolicy: IfNotPresent</pre> |
| MinIO Operator | To be documented | To be documented |
| MinIO | To be documented | To be documented |
| Gitlab | To be documented | To be documented |
| Gitlab Runners | To be documented | To be documented |
| Nexus | To be documented | To be documented |
| Sonarqube | To be documented | To be documented |
| Anchore | To be documented | To be documented |
| Mattermost Operator | To be documented | To be documented |
| Mattermost | To be documented | To be documented |
| Velero | To be documented | To be documented |
| Keycloak | To be documented | To be documented |
