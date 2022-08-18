# Gitlab

## Overview

[Gitlab](https://about.gitlab.com/) is an open-source with premium offering, self-hostable Git repository, build system and container registry.

Big Bang's implementation uses the [Gitlab Helm Chart](https://docs.gitlab.com/charts/) to provide custom resources and manage the application.

A more detail view of Big Bang's implementation of Gitlab can be found in the [package docs](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab/-/tree/main/chart/doc).

## Big Bang Touch Points

### UI

The Gitlab UI is the primary way of interacting with Gitlab. The UI is accessible via a web application on the cluster at the DNS name "gitlab" (e.g. gitlab.bigbang.com). The UI provides access to all Gitlab features.

### Logging

Gitlab has a logging mechanism built in that logs all relevant events in a json format. More detailed information can be found in their [logging docs](https://docs.gitlab.com/ee/administration/logs.html).

### Monitoring

Monitoring has been configured to use the Bigbang monitoring package (Prometheus and Grafana). This is automatically enabled by having monitoring enabled in the main values file.

```yaml
# Monitoring
#
monitoring:
  # -- Toggle deployment of Monitoring (Prometheus, Grafana, and Alertmanager).
  enabled: true

```

### Health Checks

Gitlab provides built in health checks.

```shell
GET /-/health
```

Example request

```shell
curl "https://gitlab.example.com/-/health"
```

Gitlab also provides a separate liveness and readiness probes.

```shell
GET /-/readiness
GET /-/readiness?all=1
```

Example request

```shell
curl "https://gitlab.example.com/-/readiness"
```

```shell
GET /-/liveness
```

Example request

```shell
curl "https://gitlab.example.com/-/liveness"
```

More information can be found in the gitlab documentation [here](https://docs.gitlab.com/ee/user/admin_area/monitoring/health_check.html).

## High Availability

Gitlab is for the most part a monolithic application. As such it depends on Kubernetes itself for HA.

## Single Sign On (SSO)

Gitlab can be integrated with Keycloak for single sign on. Full documentation can be found in the package docs [here](https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab/-/blob/main/docs/keycloak.md).

## Licensing

GitLab is built on an open core model. GitLab Community Edition is open source, with an MIT Expat license. GitLab Enterprise Edition is built on top of Community Edition.

GitLab Enterprise Edition uses the same core, but adds additional features and functionality on top of that. These additional features are under a proprietary license that makes the code published source-available.

Bigbang currently used the community edition. This can be overwritten in the values.yaml file.

```yaml
## doc/installation/deployment.md#deploy-the-community-edition
  edition: ce
```

More information about GitLab licensing can be found [here](https://about.gitlab.com/install/ce-or-ee/) for the information page and [here](https://gitlab.com/gitlab-org/gitlab/blob/master/LICENSE) for the actual license.

## Storage

### Database Storage

Gitlab uses a Postgresql database to store all metadata for git repositories as well as all business logic around the UI and workflows within the application. By default Bigbang will install a internal Postgres instance to support Gitlab. The recommended approach is to provision and use an external Postgres instance.

You can configure an external database by providing the values needed in the Bigbang values.yaml file under the Gitlab section. Entering connection info will automatically disable the deployment of an internal database and will deploy using the external instance.

```yaml
    database:
      # -- Hostname of a pre-existing PostgreSQL database to use for Gitlab.
      # Entering connection info will disable the deployment of an internal database and will auto-create any required secrets.
      host: ""

      # -- Port of a pre-existing PostgreSQL database to use for Gitlab.
      port: 5432

      # -- Database name to connect to on host.
      database: "" # example: gitlab

      # -- Username to connect as to external database, the user must have all privileges on the database.
      username: ""

      # -- Database password for the username used to connect to the existing database.
      password: ""

```

### File Storage

Gitlab uses S3, Minio, or another S3-style storage for file storage. By default Big Bang deploys an in-cluster Minio instance for this purpose, but you have the option to point to an external Minio or S3 if desired. See the below example for the values to supply:

```yaml
    objectStorage:
      # -- Type of object storage to use for Gitlab, setting to s3 will assume an external, pre-existing object storage is to be used.
      # Entering connection info will enable this option and will auto-create any required secrets
      type: ""         # supported types are "s3" or "minio"

      # -- S3 compatible endpoint to use for connection information.
      # examples: "https://s3.amazonaws.com" "https://s3.us-gov-west-1.amazonaws.com" "http://minio.minio.svc.cluster.local:9000"
      endpoint: ""

      # -- S3 compatible region to use for connection information.
      region: ""

      # -- Access key for connecting to object storage endpoint.
      accessKey: ""

      # -- Secret key for connecting to object storage endpoint.
      # Unencoded string data. This should be placed in the secret values and then encrypted
      accessSecret: ""

      # -- Bucket prefix to use for identifying buckets.
      # Example: "prod" will produce "prod-gitlab-bucket"
      bucketPrefix: ""

```

## Dependencies

Additional pass-throughs for dependencies that deviate from rationalized standards can be passed using the values: tag in the main Bigbang values.yaml.

```yaml
# -- Values to passthrough to the gitlab runner chart: https://repo1.dso.mil/platform-one/big-bang/apps/developer-tools/gitlab-runner.git
    values: {}
```
