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

If you change the admin user's password via the UI you also must update the secret. Failure to do so will result
in proxy/saml job failures on subsequent upgrades.

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

### Nexus Package Upgrades
If you are upgrading from versions prior to `42.0.0-bb.4` there are considerations to make for upgrade paths and inclusion of new values. In `42.0.0-bb.4` this package was updated to change the user for metrics collection `basicAuth` from `admin` to a `metrics` user. This was in an effort to reduce the permissions of the user with credentials stored in kubernetes.

#### New Installation
The recommended process for new installations of this package include:
- set `.Values.monitoring.serviceMonitor.createMetricsUser` to `true`
- set `.Values.secret.enabled` to `true`
- reconcile the package and ensure the target in prometheus for nexus is `UP`
- set `.Values.monitoring.serviceMonitor.createMetricsUser` to `false`
- set `.Values.secret.enabled` to `false`
  - This will remove the admin credentials secret from persisting in the cluster.

#### Package Upgrade
The recommended process for upgrading an existing installation include:
- set `.Values.monitoring.serviceMonitor.createMetricsUser` to `true`
- set `.Values.secret.enabled` to `true`
- set `.Values.custom_admin_password` to your current admin password
- set `.Values.monitoring.serviceMonitor.createMetricsUser` to `false`
- set `.Values.secret.enabled` to `false`
  - This will remove the admin credentials secret from persisting in the cluster.

### License
We expect you to secure your license; the license will be provided as a binary. Encode the binary file as a base64
encoded string, secure with sops, and place in `.Values.addons.nexusRepositoryManager.license_key`. The `_helpers.tpl`
will create a named template and generate the appropriate secret within the namespace. The chart will reference the
license via a secret volumeMount to ensure the application starts licensed.

### NXRM Dependent Packages
Nexus IQ Server requires Nexus Repository Manager.
