# 3. Consolidating all packages under a single mapping

Date: 2025-04-23

## Status

Accepted

## Context

The current structure of The BigBang "umbrella" helm chart's values.yaml file has the following organization:

1. Global configuration keys that provide shared settings across all deployed packages
2. Individual keys for each `core` package with a consistent package schema
3. An `addons` key containing a mapping of additional packages that match the same schema as core packages

This structure has several limitations:

- It doesn't clearly separate global configuration from package-specific configuration
- It creates challenges given the fluidity of how packages are categorized
- The terminology of core vs addon is often conflated with "default" packages
- Any more granular categorizaton of packages becomes strained because the package type (package metadata) is codified as the value structure
- Iterating through all packages with helm templating (or any tooling) is clunky because core packages are at the top level while addon packages are nested

> [!NOTE]  
> Divorcing the package category (addons vs core) from the values structure creates an opportunity to introduce alternative package metadata mechanisms, but the implementation is considered out of scope for this document and will be addressed in a future ADR.

## Decision

We will restructure the values.yaml file to:

1. Move all packages (both core and addons) under a single `packages` key that will contain a mapping of all packages
2. Rename the existing `packages` key to `additionalPackages` for any secondary apps
3. Keep global configuration at the top level of values.yaml

## Consequences

### Positive

- Clear delineation between global configuration and package configuration
- Simplified iteration over all packages with helm templating and other tools
- Better foundation to create package "buckets/profiles" that are not defined by their structure in the values.yaml
- Sets us up to replace boilerplate package templates with reusable Helm helpers

### Negative

- Significant churn to update all templates in the Big Bang Helm chart to move from `.Values.<package.*` to `.Values.packages.<package>.*`
- All existing Big Bang deployments will require values migration

## Implementation

The implementation will involve:

1. Creating a new schema definition in values.schema.json that reflects the updated structure
2. Migrating all core package configurations from the top level to the new `packages` map
3. Migrating all addon package configurations from the `addons` map to the `packages` map
4. Updating all templates to reference the new structure
5. Providing migration documentation and migration script for existing deployments

## Example

Before:

```yaml
domain: dev.bigbang.mil

registryCredentials:
  registry: registry1.dso.mil
  username: ""
  password: ""
  email: ""

loki:
  # -- Toggle deployment of Loki.
  enabled: true
  git:
    repo: https://repo1.dso.mil/big-bang/product/packages/loki.git
    path: "./chart"
    tag: "6.27.0-bb.3"
  # other loki config...

addons:
  argocd:
    # -- Toggle deployment of ArgoCD.
    enabled: false
    git:
      repo: https://repo1.dso.mil/big-bang/product/packages/argocd.git
      path: "./chart"
      tag: "7.8.23-bb.1"
    # other argocd config...
```

After:

```yaml
domain: dev.bigbang.mil

registryCredentials:
  registry: registry1.dso.mil
  username: ""
  password: ""
  email: ""

packages:
  loki:
    # -- Toggle deployment of Loki.
    enabled: true
    git:
      repo: https://repo1.dso.mil/big-bang/product/packages/loki.git
      path: "./chart"
      tag: "6.27.0-bb.3"
    # other loki config...
  
  argocd:
    # -- Toggle deployment of ArgoCD.
    enabled: false
    git:
      repo: https://repo1.dso.mil/big-bang/product/packages/argocd.git
      path: "./chart"
      tag: "7.8.23-bb.1"
    # other argocd config...

additionalPackages:
  # Any secondary app configuration
```
