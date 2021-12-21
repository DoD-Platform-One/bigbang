# Big Bang Package: Single Sign On (SSO)

Big Bang has configuration for Single Sign-On (SSO) authentication using an identity provider, like Keycloak.  If the package supports SSO, you will need to integrate Big Bang's configuration with the package.  If the package does not support SSO, an [authentication service](https://repo1.dso.mil/platform-one/big-bang/apps/core/authservice) can be used to intercept traffic and provide SSO.  This document details how to setup your package for either scenario.

## Prerequisites

The development environment can be set up in one of two ways: 
    1. Two k3d clusters with keycloak in one cluster and Big Bang and all other apps in the second cluster (see [this quick start guide](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/docs/guides/deployment_scenarios/sso_quickstart.md) for more information)
    2. One k3d cluster using metallb to have keycloak, Big Bang, and all other apps in the one cluster (see [this example config](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/docs/example_configs/keycloak-dev-values.yaml) for more information)

## Integration

### SSO Integration

All package SSO Integrations within BigBang require a `<package>.sso` block within the BigBang [chart values](../../../chart/values.yaml) for your package along with an enabled flag:

```yml
<package>:
    sso:
      enabled: true
```
Based on the authentication protocol implemented by the package being integrated, either Security Access Markup Language (SAML) or OpenID (OIDC), follow the appropriate example below.

#### OIDC
For SSO integration using OIDC, at a minimum this usually requires `sso.client_id` and `sso.client_secret` values under the same block above. We can then reference these values further down in either the template values for your package ([eg: Gitlab](../../../chart/templates/gitlab/values.yaml)) or [Authservice Values template](../../../chart/templates/authservice/values.yaml) if there is no built-in support for OIDC or SAML in the package. Authservice will be discussed in more detail further down.

```yml
<package>:
    sso:
      enabled: true
      client_id: "XXXXXX-XXXXXX-XXXXXX-APP" 
      client_secret: "XXXXXXXXXXXX"
```

* A `bigbang/chart/templates/<package>/secret-sso.yaml` may need to be created in order to auto-generate secrets if required by the upstream documentation. We can see in the Gitlab documentation for SSO the configuration is handled [via JSON configuration](https://docs.gitlab.com/ee/administration/auth/oidc.html) [within a secret](https://docs.gitlab.com/charts/charts/globals.html#providers). This `secret-sso.yaml` can conditionally be created when `<package>.sso.enabled=true` within the BigBang values.

    Example: [GitLab SSO Secret template](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/chart/templates/gitlab/secret-sso.yaml)

* If configuration isn't destined for a secret and the package supports SSO options directly via helm values we can create and reference the necessary options from the `<package>.sso` values block. For example, elasticsearch documentation specifies a few [values required to enable and configure OIDC](https://www.elastic.co/guide/en/elasticsearch/reference/master/oidc-guide.html#oidc-enable-token) that we can configure and set to be conditional on `<package>.sso.enabled`.

    Example: [ECK Values template](../../../chart/templates/logging/elasticsearch-kibana/values.yaml)

#### SAML
For SSO integration using SAML, review the upstream documentation specific to the package and create the necessary items to passthrough from BigBang to the package values under the `<package>.sso` key. For example, Sonarqube configures SSO settings through `sonarProperties` values, which are collected from defined values under `addons.sonarqube.sso` within BigBang and passed through in the [sonarqube Values template](../../../chart/templates/sonarqube/values.yaml).


### AuthService Integration
If SSO is not availble on the package to be integrated, Istio AuthService can be used for authentication. For AuthService integration, add `<package>.sso.client_id` and `<package>.sso.client_secret` definitions for the package within `../../chart/values.yaml`. Authservice has `global` settings defined and any values not explicitly set in this file will be inherited from the global values (like `authorization_uri`, `certificate_authority`, `jwks`, etc). Review the example below below of the jaeger specific chain configured within BigBang and passed through to the authservice values.

Example: [Jaeger chain in Authservice template values](../../../chart/templates/authservice/values.yaml)

In order to use Authservice, Istio injection is required and utilized to route all pod traffic through the Istio side car proxy and the associated Authentication and Authorization policies. 

1. The first step is to ensure your namespace template where you package is destined is istio injected, and the appropriate label is set in `chart/templates/<package>/namespace.yaml`.

Example: [Jaeger Namespace template](../../../chart/templates/jaeger/namespace.yaml)

1. Next is to make sure the following label is applied to the workload (pod/deployment/replicaset/daemonset/etc) that will be behind the Authservice gate:

```yml
...
{{- $<package>AuthserviceKey := (dig "selector" "key" "protect" .Values.addons.authservice.values) }}
{{- $<package>AuthserviceValue := (dig "selector" "value" "keycloak" .Values.addons.authservice.values) }}
...
metadata:
  labels:
    {{ $<package>AuthserviceKey }}: {{ $<package>AuthserviceValue }}
```

This label is set in the Authservice package, and is set to `protect=keycloak` by default, the above logic will check if anyone overwrites these values within their BigBang installation and overwrite the label accordingly.

Example: [Jaeger Values template](../../../chart/templates/jaeger/values.yaml)

## Validation
For validating package integration with Single Sign On (SSO), carry out the following basic steps:
1. Enable the package and SSO within Big Bang through the values added in the sections above
2. Using an internet browser, browse to your application (e.g. sonarqube.bigbang.dev)
3. If using built-in SAML/OIDC, click the login button, confirm a redirect to the Identity Provider happens. If using Authservice, confirm a redirect to the Identity Provider happens, prompting user sign in.
4. Sign in as a valid user
5. Successful sign in should return you to the application page
6. Confirm you are in the expected account within the application and that you are able to use the application

Note: An unsuccessful sign in may result in an `x509` cert issues, `invalid client ID/group/user` error, `JWKS` error, or other issues. 
