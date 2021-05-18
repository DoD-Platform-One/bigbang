# Kiali

Istio UI, chart.

Originaly sourced from [upstream](), and minimally modified.

## Upstream Changes



## Iron Bank

You can `pull` the registry1 image(s) [here](https://registry1.dso.mil/harbor/projects/3/repositories/opensource%2Fistio-1.7%2Foperator-1.7) and view the container approval [here](https://ironbank.dso.mil/ironbank/repomap/opensource/istio-1.7).

## OpenID Authentication

You can pass through your OpenID configuration through to kiali via values in Big Bang:

```yaml
kiali:
  sso:
    enabled: true
    client_id: "platform1_a8604cc9-f5e9-4656-802d-d05624370245_bb8-kiali"
    client_secret: "EXAMPLE_SECRET_HASH"
```

The above configuration will auto complete a Keycloak Endpoint in the Kiali Resource and utilize the provided client_id and client_secret values.

### If you would like to use an auth provider other than Keycloak:

```yaml
kiali:
  values:
    cr:
      spec:
        auth:
          strategy: openid
          openid:
            client_id: ""
            issuer_uri: "https://ENDPOINT_URL/AUTH"
            scopes:
            - openid
            - email
            username_claim: email
```

More information about settings for Kiali's OpenID support: https://kiali.io/documentation/latest/configuration/authentication/openid/

### Resolving openid auth cert issues.
Kiali allows for skipping TLS verification for OpenID Auth communications. They do not have support for mounting or specifying a PEM certificate to the pod or resource.

```yaml
kiali:
  values:
    cr:
      spec:
        auth:
          openid:
            insecure_skip_verify_tls: true
```

https://kiali.io/documentation/latest/configuration/authentication/openid/#_using_an_openid_provider_with_a_self_signed_certificate
