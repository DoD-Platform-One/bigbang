# Sonatype Nexus Repository Manager (NXRM) Documentation

## Table of Contents
- [NXRM SSO Integration](docs/keycloak.md)
- [NXRM High Availability](docs/general.md#high-availability)
- [NXRM Storage](docs/general.md#storage)
- [NXRM Database](docs/general.md#database)
- [NXRM Dependent Packages](#nxrm-dependent-packages)
- [NXRM BigBang Caveats, Notes, etc.](#bigbang-additions-comments-and-important-information)

## Iron Bank
You can `pull` the Iron Bank image [here](https://registry1.dso.mil/harbor/projects/3/repositories/sonatype%2Fnexus%2Fnexus) and view the container approval [here](https://ironbank.dso.mil/repomap/sonatype/nexus).

## Helm
Please reference complete list of providable variables [here](https://github.com/sonatype/helm3-charts/tree/master/charts/nexus-repository-manager#configuration)

```bash
git clone https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/nexus-repository-manager.git
helm install nexus-repository-manager chart
```
## BigBang Additions, Comments, and Important Information

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

### NXRM Dependent Packages
Nexus IQ Server requires Nexus Repository Manager.