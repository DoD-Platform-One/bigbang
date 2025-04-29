# Backstage

Backstage is an open source framework for building developer portals.  It 
enables users to configure and centralize data, documentation, links, 
and general information about their components and applications and their 
human-legible resources into one navigation area.  This enables users to track
and visualize information in one centralized location.

## Architecture

Backstage as it relates to bigbang will provide users with a way to register
their existing addon components and appliations through the use of [catalog and component YAML](https://backstage.io/docs/features/software-catalog/)
files that are built and stored parallel to the code they represent.  These
will allow users to define their own software catalogs efficiently as part of 
their workflow, providing an effective source of truth that is easily visualized
and navigated through backstage.  Bigbang provides catalogs for existing bigbang
components and some addons.

## Big Bang Touchpoints

### Licensing

Backstage is open-source,
[licensed under Apache License 2.0](https://github.com/backstage/backstage/blob/master/LICENSE).

### UI

Backstage provides a UI for both management, navigation, search, andother 
necessary functions as part of its standard offerings.  Backstage catalog
enables users to search and add/edit components, user groups, users, system 
definitions (component groups), file / resource locations, APIs, among other things.
It utilizes [options for local or remote YAML catalog definitions](https://backstage.io/docs/features/software-catalog/configuration) to store 
catalog YAML remotely as code, and add them into backstage at deployment seamlessly via values.

### Storage

Bigbang Backstage is capable of integrating with an external postgresql database only at this time.
These values are defined in the backstage chart.

### Logging

Backstage writes its logs to stderr. These logs will be picked up by the
logging collector configured within the cluster.

Monitoring has been configured to use the Bigbang monitoring package (Prometheus and Grafana). This is automatically enabled by having monitoring enabled in the main values file.

```yaml
# Monitoring
#
monitoring:
  # -- Toggle deployment of Monitoring (Prometheus, Grafana, and Alertmanager).
  enabled: true

```

### Health Checks

Backstage has liveness and readiness checks available at the following paths:
<https://backstage.com>/.backstage/health/v1/readiness
<https://backstage.com>/.backstage/health/v1/liveness
These endpoints return 200 OKs, and a JSON {"status": "ok"} response.

## Single Sign On (SSO)

Backstage can be integrated with Keycloak for single sign on. Full documentation can be found in the package docs [here](https://repo1.dso.mil/big-bang/product/packages/backstage/-/blob/main/docs/KEYCLOAK.md).  If you already have keycloak available, you may configure backstage addon values at `addons.backstage.sso` within bigbang chart/values.yaml.
