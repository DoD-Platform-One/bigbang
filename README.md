# Sonatype Nexus Repository Manager (NXRM)

Source of truth for components, artifacts, binaries, etc.

This chart was sourced from [Sonatype's Helm Charts.](https://github.com/sonatype/helm3-charts) with minimal changes.

## Prerequisites
- Kubernetes Cluster deployed
- Kubernetes config installed in ~/.kube/config
- Helm installed
- Keycloak (Optional - SSO)
- Sonatype NXRM License. Required for SAML integration

## Iron Bank
You can `pull` the Iron Bank image [here](https://registry1.dso.mil/harbor/projects/3/repositories/sonatype%2Fnexus%2Fnexus) and view the container approval [here](https://ironbank.dso.mil/repomap/sonatype/nexus).

## Helm
Please reference complete list of providable variables [here](https://github.com/sonatype/helm3-charts/tree/master/charts/nexus-repository-manager#configuration)

```bash
git clone https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/nexus-repository-manager.git
helm install nexus-repository-manager chart
```

## BigBang Additions, Comments, and Important Information
### SAML/SSO Integration
BigBang requires/prefers SAML/SSO integration out of the box; unfortunately, the upstream Helm chart did not have a
solution at the drafting of this integration. To achieve our goal, we added a Kubernetes job that handles the SAML/SSO
integration. To enable this functionality, ensure `sso.enabled` is set to `true`; you will additionally require a
Keycloak instance, the IDP metadata file, along with other parameters you may defined in `sso.idp_data`. Our
implementation closely follows the [Sonatype SAML Integration](https://support.sonatype.com/hc/en-us/articles/1500000976522-SAML-integration-for-Nexus-Repository-Manager-Pro-3-and-Nexus-IQ-Server-with-Keycloak) documentation.

Retrieve a list of all available privileges:
`curl -X GET "https://{{ base_url }}/service/rest/v1/security/privileges" -H "accept: application/json"`

### Random Admin Password
NXRM's upstream chart ships with a standardized password and an optional values parameter to randomize a password. The
problem with this approach it the user would be required to `exec` into the pod to retrieve the password. We are
leveraging the existing `nexus.env['NEXUS_SECURITY_RANDOMPASSWORD']` item to force the creation of the random password
on the pod. However, we are generating a random password via `randAlphaNum` and creating a Kubernetes secret. This
method allows us to overwrite the generated file containing the Nexus generated random password with a Kubernetes
secret to enable programmatic ingestion.

Ensure the following is present to enable the randomized Kubernetes password:
```bash
# values.yaml
nexus:
  env:
    - name: NEXUS_SECURITY_RANDOMPASSWORD
      key: "true"
...
secret:
  enabled: true
  mountPath: /nexus-data/admin.password
  subPath: admin.password
  readOnly: true
```

### License
We expect you to secure your license; the license will be provided as a binary. Encode the binary file as a base64 
encoded string, secure with sops, and place in `.Values.addons.nexusRepositoryManager.license_key`. The `_helpers.tpl`
will create a named template and generate the appropriate secret within the namespace. The chart will reference the 
license via a secret volumeMount to ensure the application starts licensed.
