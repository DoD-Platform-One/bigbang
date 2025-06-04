# Migrating from Istio Operator to Helm based Istio

## Timeline

- The new Istio Helm packages
  [istio-crds](https://repo1.dso.mil/big-bang/product/packages/istio-crds),
  [istiod](https://repo1.dso.mil/big-bang/product/packages/istiod), and
  [istio-gateway](https://repo1.dso.mil/big-bang/product/packages/istio-gateway)
  are _Beta_ in
  [Big Bang 2.51](https://repo1.dso.mil/big-bang/bigbang/-/releases)
- These packages will be generally available and stable for production use in
  2.52 (or 2.53)
- The
  [istio-operator](https://repo1.dso.mil/big-bang/product/packages/istio-operator)
  and
  [istio-controlplane](https://repo1.dso.mil/big-bang/product/packages/istio-controlplane)
  packages will no longer be present in Big Bang 3.0
- Therefore, migrate from Istio Operator to Istio Helm in BB 2.53 or 2.54 before
  upgrading BB to 3.0

## Considerations

- The helm packages update Istio from 1.23 to 1.25
- The Istio Operator is _End of Life_ and does not support versions of Istio
  after 1.23
- Istio 1.23 is only supported
  [through April 2025](https://istio.io/latest/docs/releases/supported-releases/#:~:text=1.25%2C%201.26%2C%201.27-,1.23,-Yes)

### Understanding the New Gateways Pattern

The new `istio-gateway` package works a little differently than other packages
in Big Bang. To make it easier on our consumers to deploy their own custom
`Gateway` resources, the values are iterated over to create separate
`HelmRelease` resources for each `Gateway`. By default, Big Bang uses this
feature to create two gateway `HelmRelease` resources: `public-ingressgateway`,
and `passthrough-ingressgateway`. You can override any of the settings for these
charts by configuring values under `istioGateway.values.gateways.public` and
`istioGateway.values.gateways.passthrough`, respectively.

#### Gateway name and namespace changes

To better align with Istio's guidance, we're separating the `Gateway` resources
and deployments from the `istio-system` `Namespace` and adding them to a new
`Namespace`: `istio-gateway`.

A consequence of this change is that `VirtualService` resources not managed and
maintained by the Big Bang team will need to update their references to these
new `Gateway` definitions.

Example: A `VirtualService` referencing the `istio-system/public` `Gateway` will
now need to reference `istio-gateway/public-ingressgateway` instead. It's
possible to create these `VirtualService` resources before migrating to the new
`istioGateway` package to minimize downtime as workload traffic shifts.

#### How `istioGateway` values are used

Everything nested under the gateway name is passed entirely to the
`istio-gateway` chart. The only exception is `tls`. That's used to create a
`Secret` in the Big Bang umbrella chart.

Example:

```yaml
istioGateway:
  values:
    gateways:
      custom:
        # This does not get passed to the gateway-api chart.
        # Instead, a `Secret` is created called for each certificate listed
        # in the gateway namespace composed of these values
        gatewayCerts:
          - name: custom-cert
            tls:
              cert: ...
              key: ...
              ca: ...

        # These values are used to configure the `Gateway` CR we
        # create in the istio-gateway chart.
        gateway:
          servers:
            - hosts:
                - "*.example.com"
              port:
                name: http
                number: 8080
                protocol: HTTP
              tls:
                httpsRedirect: true
            - hosts:
                - "*.example.com"
              port:
                name: https
                number: 8443
                protocol: HTTPS
              tls:
                credentialName: custom-cert # this should match the <name> property in the list of certs under <gatewayCerts> to select the right secret
                mode: SIMPLE

        # Everything under upstream gets passed through our istio-gateway chart
        # to the istio-maintained istio/gateway chart
        upstream:
          imagePullPolicy: Always

          imagePullSecrets:
            - name: private-registry

          labels:
            istio: ingressgateway # we require this to be one of `ingressgateway` or `egressgateway`
```

#### Custom Gateway Examples

If Big Bang is deployed with these values:

```yaml
istioGateway:
  values:
    gateways:
      custom:
        upstream:
          labels:
            istio: ingressgateway # required to be ingressgateway or egressgateway
      special:
        upstream:
          labels:
            istio: ingressgateway
```

The Big Bang chart will template out two `HelmRelease` resources in addition to
the default `public` and `passthrough` gateways:

```yaml
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: custom-ingressgateway
...
---
apiVersion: helm.toolkit.fluxcd.io/v2
kind: HelmRelease
metadata:
  name: special-ingressgateway
```

By default, the values for these `HelmRelease` resources will be augmented to
include a default `imagePullPolicy` and default `imagePullSecrets` in order to
seamlessly pull images from IronBank. You can of course override these if
necessary.

## Migration Process

Istio can be migrated from the old operator packages to the new helm-based
packages in-place with a few steps.

> 🚧 <span style="color: orange">**WARNING**</span>
>
> This process will require downtime for your configured gateways. Previously,
> Gateways were configued via the `istio` package. With 3.0, we're splitting
> concerns and making gateways configurable with the `istioGateway` package. Due
> to this change, your gateways will be destroyed and recreated. If you're using
> an external load balancer (e.g AWS NLB, Azure LB, or MetalLB), it's likely
> this process will change your load balancer's hostname/IP address. If this
> happens, the DNS records for your load balancer will need to be updated.

### Step 1 : Swap `istio` for `istioCRDs` and `istiod`

Disable the old istio package and enable the new `istioCRDs` and `istiod`
packages:

```yaml
istioOperator:
  enabled: true
istio:
  enabled: false

istioCRDs:
  enabled: true
istiod:
  enabled: true
istioGateway:
  enabled: false
```

Give the cluster a few minutes for all helm releases to become `ready`.

### Step 2 : Disable `istioOperator` and enable `istioGateway`

Removal of the operator and the enablement of the new gateway package
reinstantiates cluster gateways.

When migrating gateway configurations, see
[the examples here](../../../chart/values.yaml#L227-282) as a reference to
format values and configure postRenderers.

```yaml
istioOperator:
  enabled: false
istio:
  enabled: false

istioCRDs:
  enabled: true
istiod:
  enabled: true
istioGateway:
  enabled: true
```

After all helm releases become `ready` once again, verify gateway(s) recieves an
external IP:

```bash
kubectl get svc -n istio-gateway
NAME                  TYPE         CLUSTER-IP    EXTERNAL-IP  PORT(S)
public-ingressgateway LoadBalancer 10.43.110.109 172.16.88.88 15021:31155/TCP,80:31302/TCP,443:31046/TCP
```

There have been reports of orphaned `LoadBalancer` `Service`s left in the `istio-system` namespace after the migration, that were originally deployed by the operator. It's unclear what causes this to happen, and it is not consistently reproducible, but they should be checked for, as they will incur cloud costs.

```bash
kubectl -n istio-system get service --field-selector spec.type=LoadBalancer
NAMESPACE      NAME                         TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)                                      AGE
istio-system   passthrough-ingressgateway   LoadBalancer   10.43.57.3     172.20.1.240   15021:31859/TCP,80:32262/TCP,443:31243/TCP   2m15s
istio-system   public-ingressgateway        LoadBalancer   10.43.156.28   172.20.1.241   15021:31241/TCP,80:31688/TCP,443:31597/TCP   2m15s
```

If these still exist post-migration, they should be deleted.

The migration process is now complete.

## Troubleshooting

Below are a few tips for troubleshooting if the migration did not go as smoothly
as expected.

### Services are unreachable

```
upstream connect error or disconnect/reset before headers. retried and the latest reset reason: remote connection failure, transport failure reason: TLS_error:|268435581:SSL routines:OPENSSL_internal:CERTIFICATE_VERIFY_FAILED:TLS_error_end
```

To resolve this issue, cycle all Istio injected pods allowing their
reconnection.

The below bash script iterates across all `istio-injected` namespaces and
recycles all pods:

```bash
# in istio-injected namespaces, recycle pods
for namespace in `kubectl get ns -o custom-columns=:.metadata.name --no-headers -l istio-injection=enabled`
do
    echo -e "\n♻️ recycling pods in namespace: $namespace"
    for pod in `kubectl get pods -o custom-columns=:.metadata.name --no-headers -n $namespace`
    do
        kubectl delete pod $pod -n $namespace
    done
done
```

Pods should return to `ready` within a few minutes.

### Reconcile Helm Releases

If may be necessary to synchronize helm releases managed by Flux when they
become _out of sync_.

The `flux` CLI must be [installed](https://fluxcd.io/flux/installation/) to use
this bash script that iterates across all helm releases initiating a
[reconciliation](https://fluxcd.io/flux/cmd/flux_reconcile_helmrelease):

```bash
# reconcile all of big bang's helm releases w/ flux
for hr in `kubectl get hr --no-headers -n bigbang | awk '{ print $1 }'`
do
    echo -e '\n☸️ reconciling hr:' $hr
    flux reconcile hr $hr -n bigbang --with-source
done
```

All services in the cluster should once again be reachable.

### Other Resources

- [Diagnostic Tools for Istio](https://istio.io/latest/docs/ops/diagnostic-tools)
- [Troubleshooting tips](https://github.com/istio/istio/wiki/Troubleshooting-Istio)
