# Istio Hardened
Big Bang has added the `.Values.istio.hardened` map attibute to the values of applications that can be istio-injected (when `.Values.istio.enabled` is `true`).  This document walks through the impact of setting `.Values.istio.hardened: true` on how traffic is managed within a given istio-injected package.

## Prerequisites
In order for `.Values.istio.hardened.enabled: true` to have any impact, the package must also have `.Values.istio.enabled: true` set.  This is because all of the resources created by setting `.Values.istio.hardened.enabled: true` are applied to the istio service mesh, which includes istio sidecar proxies.  If there are no istio proxies, then no mesh components exist in the namespace and therefore istio Kubernetes resources in the namespace will not effect anything.

## REGISTRY_ONLY Istio Sidecar resources
When `.Values.istio.hardened.enabled: true` is set, a `Sidecar` resource is applied to the package's namespace that sets the outboundTrafficPolicy of the Sidecar to `REGISTRY_ONLY`.  What this means is that for pods with an istio-proxy running as a "sidecar", the only egress traffic allowed is for traffic that is destinated for a service that exists within the istio service mesh registry.

By default, all Kubernetes Services are added to this registry.  However, cluster-external hostnames, IP addresses, and other endpoints will NOT be reachable with this Sidecar in place.  For example, if an application attempts to reach out to the Kubernetes API Service at `kubernetes.default.svc.cluster.local` (or any of it's SANs), the request will not be blocked by the Sidecar.  Conversely, if the application attempts to reach out to s3.us-gov-west-1.amazonaws.com, the request with fail unless there is a ServiceEntry (see below) that adds s3.us-gov-west-1.amazonaws.com to the service mesh registry. This Sidecar is added in order to provide defense in depth, working alongside NetworkPolicies to prevent data exfiltration by malicious actors.

## ServiceEntry Istio resources
Because some application have well-documented requirements to reach out to cluster external endpoints (S3 is one common example), Big Bang has added ServiceEntries to get those endpoints included in the Istio service registry.  If we missed one, please open an issue detailing what endpoint needs to be whitelisted with a ServiceEntry.  Alternatively, you can create your own whitelisted endpoints by using the `.Values.istio.hardened.customServiceEntries` list, which will generate a ServiceEntry according to the `.spec` map you set.

> `customServiceEntries` is there for *edge cases* that may be specific to your requirements, and not all `customServiceEntries` may be appropriate for all Big Bang users.

### Example customServiceEntry
To create a ServiceEntry for google, the corresponding customServiceEntry attribute could be set:
```yaml
istio:
  enabled: true
  hardened:
    enabled: true
    customServiceEntries:
     - name: "allow-google"
       enabled: true
       spec:
         hosts:
           - google.com
         location: MESH_EXTERNAL
         ports:
           - number: 443
             protocol: TLS
             name: https
         resolution: DNS
```

This would result in the following ServiceEntry being created:
```yaml
apiVersion: networking.istio.io/v1beta1
kind: ServiceEntry
metadata:
  name: allow-google
  namespace: my-app-namespace
spec:
  hosts:
  - google.com
  location: MESH_EXTERNAL
  ports:
  - name: https
    number: 443
    protocol: TLS
  resolution: DNS
```

For more information on writting ServiceEntries, see [this documentation](https://istio.io/latest/docs/reference/config/networking/service-entry/)

## Authorization Policies
[Istio Authorization Policies](https://istio.io/latest/docs/reference/config/security/authorization-policy/#AuthorizationPolicy) will be created provided `istio.enabled` and `istio.hardened.enabled` are set to `true`. There is a default deny policy which will deny everything that is not explicitly allowed with another policy. Denials look like a 403 with the message `RBAC: access denied`. Other policies that are created might include allow ingress gateways, allow monitoring, or allow a supported service that needs access to these resources. You will find these listed under `istio.hardened` as named objects that have 3 properties: `enabled`, `namespaces`, and `principals`. There are also templates which allow you to create custom authorization policies through additional values, these are described in greater detail below. The last rules to note are global rules. These are any rules created in the `istio-system` namespace. Rather than affecting just the `istio-system` namespace, they will apply to all namespaces.

### Rules
Apart from the default deny, most rules will be explicit allows. Included rules will be for other supported packages. Any other rules will need to be created with the templates described below. Rules affect a namespace. Rules go on the "server" in the "client-server" relationship.

Application Order:
1. If there are any CUSTOM policies that match the request, evaluate and deny the request if the evaluation result is deny.
1. If there are any DENY policies that match the request, deny the request.
1. If there are no ALLOW policies for the workload, allow the request.
1. If any of the ALLOW policies match the request, allow the request.
1. Deny the request.

### Templates
Templates are just an easy way to inject more authorization policies by just modifying values files. They essentially allow you to pass in a name and spec, then have it deploy an authorization policy with that spec in the `.Release.Namespace`. They also allow you to enable/disable specific policies for development, debugging, and other purposes.

If you pass these partial values:
```yaml
istio:
  hardened:
    customAuthorizationPolicies:
    - name: "allow-my-namespace"
      enabled: true
      spec:
        selector:
          matchLabels:
            app.kubernetes.io/name: "server-app"
        action: ALLOW
        rules:
        - from:
          - source:
              namespaces:
              - "my-namespace"
```

This policy would be generated:
```yaml
apiVersion: security.istio.io/v1
kind: AuthorizationPolicy
metadata:
  name: "allow-my-namespace"
  namespace: {{ $.Release.Namespace }}

spec:
  selector:
    matchLabels:
      app.kubernetes.io/name: "server-app"
  action: ALLOW
  rules:
  - from:
    - source:
        namespaces:
        - "my-namespace"
```
