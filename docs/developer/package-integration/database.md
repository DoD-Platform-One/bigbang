# Big Bang Package: Database Integration

If the package you are integrating connects to a database, you will need to follow the instructions below to integrate this feature into Big Bang.

## Prerequisites

- Existing database

## Integration

There are currently 2 typical ways in bigbang that packages connect to a database.

1. Package charts accept values for host, user, pass, etc and the chart makes the necessary secret, configmap etc.

2. Package chart accepts a secret name where all the DB connection info is defined. In these cases we make the secret in the BB chart.

Both ways will first require the following step:

Add database values for the package in bigbang/chart/values.yaml

  Note: Names of key/values may differ based on the application being integrated. Please refer to package chart values to ensure key/values coincide and application documentation for additional information on connecting to a database.

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

Example: [Anchore](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/10d43bea9351b91dfc6f14d3b0c2b2a60fe60c6a/chart/values.yaml#L882)

**Next details the first way packages connect to a pre-existing database.**

1. Package charts accept values for host, user, pass, etc and the chart makes the necessary secret, configmap etc...

- add a conditional statement to `bigbang/chart/templates/<package>/values` that will check if the database values exist and creates the necessary postgresql values.

  If database values are present, then the internal database is disabled by setting `enabled: false` and the server, database, username, and port values are set.

  If database values are NOT present then the internal database is enabled and default values declared in the package are used.

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

Example: [Anchore](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/10d43bea9351b91dfc6f14d3b0c2b2a60fe60c6a/chart/templates/anchore/values.yaml#L49)

**The alternative way packages connect to a pre-existing database is detailed below.**

1. Package chart accepts a secret name where all the DB connection info is defined. In these cases we make the secret in the BB chart..

- add conditional statement in `chart/templates/<package>/values.yaml` to add values for database secret, if database values exist. Otherwise the internal database is deployed.

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

Example: [Mattermost](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/10d43bea9351b91dfc6f14d3b0c2b2a60fe60c6a/chart/templates/mattermost/mattermost/values.yaml#L49)

- create manifest that uses database values to create the database secret referenced above

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

Example: [Mattermost](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/10d43bea9351b91dfc6f14d3b0c2b2a60fe60c6a/chart/templates/mattermost/mattermost/secret-database.yaml)

## Validation

For validating connection to the external database in your environment or testing in CI pipeline you will need to add the database specific values to your overrides file or `./tests/test-values.yaml` respectively.

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
