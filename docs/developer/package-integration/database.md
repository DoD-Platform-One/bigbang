# Database Integration

If the package you are integrating connects to a database, you will need to follow the instructions below to integrate this feature into Big Bang.

## Prerequisites

- Existing database

## Integration

Stateful applications in Big Bang use two different common patterns to connect to a database. For development purposes, a third pattern is also available, but is not recommended for production.

1. Package charts accept value inputs for hostname, username, and password. The package chart generates the required Kubernetes Secret and/or ConfigMap.

2. Package chart accepts a secret name where all the DB connection info is defined. In these cases, we generate the secret in the Big Bang umbrella chart.

3. DEVELOPMENT ONLY: many charts have an optional dependency on a PostgreSQL (or other database) chart. In these cases, the package chart will use the PostgreSQL chart to create a database and user for the package. This is not recommended for production because it is ephemeral and not persistent.

The following steps can be used to configure a database:

1. Add database values for the package in bigbang/chart/values.yaml

  **NOTE:** Names of key/values may differ based on the specific package application. Please refer to package chart values to validate key/value pairs are valid. Refer to specific application documentation for additional information on connecting to a database.

```yaml
<package>
  database:
    # -- Hostname of a pre-existing PostgreSQL database to use.
    host: ""
    # -- Port of a pre-existing PostgreSQL database to use.
    port: ""
    # -- Database name to connect to on host.
    database: ""
    # -- Username to connect as to external database, the user must have all privileges on the database.
    username: ""
    # -- Database password for the username used to connect to the existing database.
    password: ""
```

Example: [Anchore](https://repo1.dso.mil/big-bang/bigbang/-/blob/10d43bea9351b91dfc6f14d3b0c2b2a60fe60c6a/chart/values.yaml#L882)

**Next details the first way packages connect to a pre-existing database.**

1. Package charts accept values for hostname, username, and/or password. The package chart generates the required Secret and/or ConfigMap.

    * Add a conditional statement to `bigbang/chart/templates/<package>/values` that will check if the database values exist and creates the necessary postgresql values.

    * To disable internal package StatefulSet database: input server, database, username, and port database values. Internal database is disabled by setting `enabled: false`.

    * If database values are NOT provided, then the internal package StatefulSet database is enabled by default with default credentials.

```yaml
# External Postgres config
{{- with .Values.<package>.database }}
postgresql:
  {{- if and .host .username .password .database .port }}
  # Use external database
  enabled: false
  postgresqlServer: {{ .host }}
  postgresqlDatabase: {{ .database }}
  postgresqlUsername: {{ .username }}
  service:
    port: {{ .port }}
  {{- else }}
  # Use internal database, defaults are fine
  enabled: true
  {{- end }}
{{- end }}
```

Example: [Anchore](https://repo1.dso.mil/big-bang/bigbang/-/blob/10d43bea9351b91dfc6f14d3b0c2b2a60fe60c6a/chart/templates/anchore/values.yaml#L49)

**The alternative way packages connect to a pre-existing database is detailed below.**

1. Package chart accepts a secret name where all the DB connection info is defined. In these cases, we make the secret in the BB chart.

    * Add conditional statement in `chart/templates/<package>/values.yaml` to add values for database secret, if database values exist. Otherwise, the internal database is deployed.

```yaml
{{- with .Values.addons.<package>.database }}
{{- if and .username .password .host .port .database }}
database:
  secret: "<package>-database-secret"
{{- else }}
postgresql:
  image:
    pullSecrets:
      - private-registry
  install: true
{{- end }}
{{- end }}
```

Example: [Mattermost](https://repo1.dso.mil/big-bang/bigbang/-/blob/10d43bea9351b91dfc6f14d3b0c2b2a60fe60c6a/chart/templates/mattermost/mattermost/values.yaml#L49)

    * Create manifest that uses database values to create the database secret referenced above.

```yaml
{{- if .Values.addons.<package>.enabled }}
{{- with .Values.addons.<package>.database }}
{{- if and .username .password .host .port .database }}
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: <package>-database-secret
  namespace: <package>
  labels:
    {{- include "commonLabels" $ | nindent 4}}
stringData:
  DB_CONNECTION_CHECK_URL: "postgres://{{ .username }}:{{ .password }}@{{ .host }}:{{ .port }}/{{ .database }}?connect_timeout=10&sslmode={{ .ssl_mode | default "disable" }}"
  DB_CONNECTION_STRING: "postgres://{{ .username }}:{{ .password }}@{{ .host }}:{{ .port }}/{{ .database }}?connect_timeout=10&sslmode={{ .ssl_mode | default "disable" }}"
{{- end }}
{{- end }}
{{- end }}
```

Example: [Mattermost](https://repo1.dso.mil/big-bang/bigbang/-/blob/10d43bea9351b91dfc6f14d3b0c2b2a60fe60c6a/chart/templates/mattermost/mattermost/secret-database.yaml)

## Validation

For validating connection to the external database in your environment or testing in CI pipeline, you will need to add the database specific values to your overrides file or `./tests/test-values.yaml` respectively.

Mattermost Example:

```yaml
addons:
  mattermost:
    enabled: true
    database:
      host: "mm-postgres.bigbang.dev"
      port: "5432"
      username: "admin"
      password: "Pa55w0rd"
      database: "db1
```
