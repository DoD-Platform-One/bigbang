# Configuring Istio Gateways in Big Bang

[[_TOC_]]

## Overview

Big Bang uses
[Istio Gateways](https://istio.io/latest/docs/reference/config/networking/gateway/)
to manage ingress and egress traffic to and from the service mesh. Gateways
handle traffic routing, TLS termination, and protocol management for all Big
Bang packages. This document explains how to configure and customize gateways to
meet your deployment requirements.

## Default Gateway Configuration

Big Bang deploys two default gateways out of the box:

### Public Gateway

The **public** gateway is configured for standard TLS termination (mode:
`SIMPLE`). It listens on ports 8080 (HTTP) and 8443 (HTTPS) and automatically
redirects HTTP traffic to HTTPS.

```yaml
istioGateway:
  values:
    gateways:
      public:
        gateway:
          servers:
            - hosts:
                - "*.{{ domain }}"
              port:
                name: http
                number: 8080
                protocol: HTTP
              tls:
                httpsRedirect: true
            - hosts:
                - "*.{{ domain }}"
              port:
                name: https
                number: 8443
                protocol: HTTPS
              tls:
                credentialName: public-cert
                mode: SIMPLE
```

The public gateway handles TLS termination, decrypting HTTPS traffic at the
gateway and forwarding unencrypted traffic to backend services within the mesh.

### Passthrough Gateway

The **passthrough** gateway is configured for TLS passthrough (mode:
`PASSTHROUGH`). It forwards encrypted traffic directly to backend services,
which handle TLS termination themselves.

```yaml
istioGateway:
  values:
    gateways:
      passthrough:
        gateway:
          servers:
            - hosts:
                - "*.{{ domain }}"
              port:
                name: http
                number: 8080
                protocol: HTTP
              tls:
                httpsRedirect: true
            - hosts:
                - "*.{{ domain }}"
              port:
                name: https
                number: 8443
                protocol: HTTPS
              tls:
                mode: PASSTHROUGH
```

This mode is typically used for applications like Keycloak that must manage
their own TLS certificates.

## Gateway Configuration Structure

Gateway configuration in Big Bang follows a three-tier structure:

### 1. Gateway Certificates (`gatewayCerts`)

Define TLS certificates that will be stored as Kubernetes secrets and referenced
by the gateway:

```yaml
istioGateway:
  values:
    gateways:
      <gateway-name>:
        gatewayCerts:
          - name: <cert-name>
            tls:
              key: "<private-key-pem>"
              cert: "<certificate-pem>"
              ca: "<optional-ca-bundle-pem>"
```

### 2. Gateway Resource (`gateway`)

Configure the Istio Gateway custom resource, defining protocol, ports, hosts,
and TLS settings:

```yaml
istioGateway:
  values:
    gateways:
      <gateway-name>:
        gateway:
          servers:
            - hosts:
                - "*.example.com"
              port:
                name: https
                number: 8443
                protocol: HTTPS
              tls:
                credentialName: <cert-name>
                mode: SIMPLE
```

### 3. Upstream Configuration (`upstream`)

Configure the underlying gateway deployment, including labels, image pull
settings, and Kubernetes resource specifications:

```yaml
istioGateway:
  values:
    gateways:
      <gateway-name>:
        upstream:
          labels:
            istio: ingressgateway # Required: must be 'ingressgateway' or 'egressgateway'
          imagePullPolicy: IfNotPresent
          imagePullSecrets:
            - name: private-registry
          serviceAccount:
            create: true
            name: <gateway-name>-service-account
```

The `istio` label is **required** and determines whether the gateway functions
as an ingress or egress gateway.

## Common Configuration Examples

### Setting TLS Certificates for the Public Gateway

To configure custom TLS certificates for the default public gateway:

```yaml
istioGateway:
  values:
    gateways:
      public:
        gatewayCerts:
          - name: public-cert
            tls:
              key: |
                -----BEGIN PRIVATE KEY-----
                MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQC...
                -----END PRIVATE KEY-----
              cert: |
                -----BEGIN CERTIFICATE-----
                MIIDXTCCAkWgAwIBAgIJAKL0UG+mRKuLMA0GCSqGSIb3DQEBBQUA...
                -----END CERTIFICATE-----
```

> **Note:** Certificates should be stored in encrypted values files (e.g., using
> SOPS) to protect sensitive key material.

### Creating a Custom Ingress Gateway

Create a new ingress gateway with custom hostname and TLS configuration:

```yaml
istioGateway:
  values:
    gateways:
      custom: # Name will be templated to 'custom-ingressgateway'
        gatewayCerts:
          - name: custom-cert
            tls:
              key: "<my-key>"
              cert: "<my-cert>"
        upstream:
          labels:
            istio: ingressgateway # Required
        gateway:
          servers:
            - hosts:
                - "*.mydomain.com"
              port:
                name: http
                number: 8080
                protocol: HTTP
              tls:
                httpsRedirect: true
            - hosts:
                - "*.mydomain.com"
              port:
                name: https
                number: 8443
                protocol: HTTPS
              tls:
                credentialName: custom-cert
                mode: SIMPLE
```

### Creating an Egress Gateway

Configure an egress gateway to control outbound traffic from the service mesh:

```yaml
istioGateway:
  values:
    gateways:
      outbound: # Name will be templated to 'outbound-egressgateway'
        upstream:
          labels:
            istio: egressgateway # Required for egress functionality
        gateway:
          servers:
            - port:
                number: 443
                name: tls
                protocol: TLS
              hosts:
                - "*"
              tls:
                mode: ISTIO_MUTUAL
```

For more information on egress gateway configuration, see:

- [Istio Egress Gateway Documentation](https://istio.io/latest/docs/tasks/traffic-management/egress/egress-gateway/)
- [Istio Egress SNI Blog](https://istio.io/latest/blog/2023/egress-sni/)

### Disabling an Existing Gateway

To disable a default gateway (e.g., the passthrough gateway):

```yaml
istioGateway:
  values:
    gateways:
      passthrough: {} # Empty object disables the gateway
```

## Package Integration with Gateways

### Directing Package Traffic to Specific Gateways

Big Bang packages can be configured to use specific gateways through the
`ingress.gateway` setting. By default, packages use the `public` gateway.

```yaml
# Direct Grafana to use the public gateway (default)
grafana:
  ingress:
    gateway: "public"

# Direct Keycloak to use the passthrough gateway
addons:
  keycloak:
    ingress:
      gateway: "passthrough"

# Direct monitoring to use a custom gateway
monitoring:
  ingress:
    gateway: "custom"
```

### Gateway Name Resolution

Gateway names are automatically resolved to the format
`istio-gateway/<name>-<type>gateway`:

| Configuration Value | Resolved Gateway Name                      |
| ------------------- | ------------------------------------------ |
| `"public"`          | `istio-gateway/public-ingressgateway`      |
| `"passthrough"`     | `istio-gateway/passthrough-ingressgateway` |
| `"custom"`          | `istio-gateway/custom-ingressgateway`      |
| `"outbound"`        | `istio-gateway/outbound-egressgateway`     |

This resolution is handled automatically by Big Bang, and packages reference
gateways using only the short name (e.g., `"public"`).

## Advanced Configuration

### Using Post-Renderers with Gateways

The `istioGateway` package supports advanced post-renderer configurations.
Post-renderers can be applied globally to all gateways or selectively to
specific gateways.

#### Global Post-Renderer (All Gateways)

Apply a post-renderer to all gateway deployments:

```yaml
istioGateway:
  postRenderers:
    - kustomize:
        patches:
          - target:
              kind: Deployment
              name: .*
            patch: |-
              - op: add
                path: /metadata/annotations/bigbang.dev~1example
                value: example
```

#### Gateway-Specific Post-Renderer

Apply a post-renderer only to a specific gateway:

```yaml
istioGateway:
  postRenderers:
    public: # Only applies to the public gateway
      - kustomize:
          patches:
            - target:
                kind: Deployment
                name: .*
              patch: |-
                - op: add
                  path: /metadata/annotations/bigbang.dev~1example
                  value: example
```

> **Note:** You cannot mix array-style and map-style post-renderers. Choose one
> approach for all gateway post-renderers.

For more information on post-renderers, see
[Post Renderers Documentation](postrenderers.md).

### Network Policies for Gateways

Gateways deployed in the `istio-gateway` namespace use Big Bang's
[bb-common network policy implementation](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/network-policies/README.md)
for automatic baseline network policy generation.

#### Automatic NetworkPolicy Generation

For all gateways configured in Big Bang's `istioGateway` values (both default
and user-created), the gateway configuration is automatically introspected to
generate baseline network policy configurations that work in most use cases.

**Default Baseline Configuration:**

- **Ingress**: Gateways allow connections from any known private subnet range
  (`10.0.0.0/8`, `172.16.0.0/12`, or `192.168.0.0/16`)
- **Egress**: Gateways allow outbound connections to any Kubernetes workload

This baseline configuration is set as a default value for each gateway's
`HelmRelease`, which means your values configuration can always override it.

#### Modifying the Global `load-balancer-subnets` Ingress Definition

To restrict gateway ingress to specific load balancer subnets across all
gateways, configure the global `load-balancer-subnets` definition:

```yaml
# Top-level `networkPolicies` in Big Bang values
# NOT `istioGateway.values.<gateway-name>.networkPolicies`
networkPolicies:
  ingress:
    definitions:
      load-balancer-subnets:
        from:
          - ipBlock:
              cidr: 10.100.101.0/24 # Load balancer subnet A
          - ipBlock:
              cidr: 10.100.102.0/24 # Load balancer subnet B
```

##### Client IP Preservation

If you are using a cloud provider load balancer that supports client IP
preservation and you've enabled that feature, you may need to be less
restrictive with your ingress rules to allow traffic from the original client IP
addresses. In such cases, consider allowing traffic from the broader private IP
ranges (e.g., `0.0.0.0/0` for IPv4 or `::/0` for IPv6) or specific known client
IPs.

```yaml
networkPolicies: # globally or per-gateway with istioGateway.values.<gateway-name>.networkPolicies
  ingress:
    definitions:
      load-balancer-subnets:
        from:
          - ipBlock:
              cidr: 0.0.0.0/0
          - ipBlock:
              cidr: ::/0
```

#### Modifying `load-balancer-subnets` Per Gateway

To configure different load balancer subnets for a specific gateway:

```yaml
istioGateway:
  values:
    gateways:
      special:
        networkPolicies:
          ingress:
            definitions:
              load-balancer-subnets:
                from:
                  - ipBlock:
                      cidr: 10.200.201.0/24 # Special subnet X
                  - ipBlock:
                      cidr: 10.200.202.0/24 # Special subnet Y
```

This overrides the global `load-balancer-subnets` definition for only the
`special` gateway while other gateways continue using the global configuration.

#### Disabling Generated Ingress Policy

To disable the automatically generated ingress policy for a specific gateway and
manage it entirely on your own:

```yaml
istioGateway:
  values:
    gateways:
      <gateway-name>:
        networkPolicies:
          ingress:
            to:
              # Key format: <gateway-name>-ingressgateway:[port1,port2,...]
              # Ports must match the gateway's server port configuration
              <gateway-name>-ingressgateway:[8080,8443]:
                from:
                  definition:
                    # Set to false to disable the generated ingress policy
                    load-balancer-subnets: false
```

> **Note:** The key is generated based on the gateway's name
> (`<gateway-name>-ingressgateway`) and server port configuration. The ports are
> represented as a JSON array in the order they are defined in the gateway's
> `servers` configuration.

#### Modifying Gateway Egress Policy

By default, gateways allow outbound connections to any Kubernetes workload. To
restrict this connectivity:

```yaml
istioGateway:
  values:
    gateways:
      <gateway-name>:
        networkPolicies:
          egress:
            from:
              <gateway-name>-ingressgateway:
                to:
                  k8s:
                    # Set to false to remove the default egress policy
                    "*": false
```

After disabling the default egress policy, you can add specific egress rules as
needed for your use case.

For more information on network policy configuration, see:

- [bb-common Network Policy Implementation](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/network-policies/README.md)

## TLS Modes

Istio gateways support multiple TLS modes:

| Mode               | Description               | Use Case                                         |
| ------------------ | ------------------------- | ------------------------------------------------ |
| `SIMPLE`           | Standard TLS termination  | Most packages; gateway decrypts traffic          |
| `PASSTHROUGH`      | Forward encrypted traffic | Packages managing their own TLS (e.g., Keycloak) |
| `MUTUAL`           | Mutual TLS authentication | Client certificate authentication                |
| `ISTIO_MUTUAL`     | Istio mutual TLS          | Egress gateways, mesh-to-mesh communication      |
| `AUTO_PASSTHROUGH` | SNI-based routing         | Multi-tenant scenarios                           |

For more details, see
[Istio TLS Settings Documentation](https://istio.io/latest/docs/reference/config/networking/gateway/#ServerTLSSettings-TLSmode).

## Troubleshooting

### Gateway Pods Not Starting

Check that the `upstream.labels.istio` field is set correctly:

```bash
kubectl get pods -n istio-gateway
kubectl describe pod <gateway-pod-name> -n istio-gateway
```

Ensure the label is either `ingressgateway` or `egressgateway`.

### TLS Certificate Issues

Verify that TLS secrets are created correctly:

```bash
kubectl get secrets -n istio-gateway
kubectl describe secret <cert-name> -n istio-gateway
```

Ensure certificate and key are in PEM format and properly base64-encoded in the
secret.

### Package Not Routing Through Gateway

Check the VirtualService configuration for the package:

```bash
kubectl get virtualservice -n <package-namespace>
kubectl describe virtualservice <package-name> -n <package-namespace>
```

Verify that the `gateways` field references the correct gateway in the format
`istio-gateway/<name>-ingressgateway`.

### Network Policy Blocking Traffic

Review network policies in the `istio-gateway` namespace:

```bash
kubectl get networkpolicies -n istio-gateway
kubectl describe networkpolicy <policy-name> -n istio-gateway
```

Ensure ingress rules allow traffic from your load balancer or source CIDR
ranges.

## References

- [Istio Gateway Documentation](https://istio.io/latest/docs/reference/config/networking/gateway/)
- [Istio Virtual Service Documentation](https://istio.io/latest/docs/reference/config/networking/virtual-service/)
- [bb-common Network Policy Implementation](https://repo1.dso.mil/big-bang/product/packages/bb-common/-/blob/main/docs/network-policies/README.md)
- [Big Bang Post Renderers Documentation](postrenderers.md)
- [Big Bang Base Configuration Reference](base-config.md)
