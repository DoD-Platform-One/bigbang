# Using Network Policies in Big Bang

## What are Network Policies

Kubernetes allows Big Bang operators to utilize [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) to control the network traffic into or out of the various pods of a Kubernetes cluster. These network policies allow you to restrict incoming and outgoing traffic to or from a given set of pods using selectors. [Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/) allow you to select which pods a given networkPolicy will apply to. 

Network Policies are added as needed to supplement other good security practices; such as proper usage of TLS, only exposing necessary ports, and using other standard controls. However, Network Policies allow you to express additional control over what can connect to the pods in your cluster from outside; which pods in your kubernetes cluster can speak to each other internally; and which things those pods can initiate connections to outside of the cluster.

## Package Types and Support Levels

The mechanisms described in this document are natively available for:

- all bigbang core packages (such as kyverno, monitoring, istio, etc)
- all bigbang supported addon packages (such as minio, etc)
- select community supported addons (jira, confluence)

For the purposes of this document, "customer defined package" and "community supported package" may be used interchangably and the techniques for one will apply equally to the other. However, customer defined packages will need to implement support for the networkpolicy control mechanism themselves if they want to make use of this functionality. See the [developer guide](../../developer/package-integration/network-policies.md) for how to implement this functionality in a customer defined package. 

## Enabling or Disabling Network Policies

BigBang core and addon packages ship with various network policies already configured. You can turn these networking policies on and off by setting a global flag and a per-component flag. Community supported packages may or may not provide the same mechanism for managing networking policies - check the documentation for the given community supported package for confirmation or additional instructions.

```
# This will turn support on or off for network policies writ-large across the bigbang suite
networkPolicies:
  enabled: [true|false]

# For bigbang core packages, this will turn on or off support for network policies in a core component
CORE_PACKAGE_NAME:
  values:
    networkPolicies:
      enabled: [true|false]

# For bigbang supported addon packages, this will turn on or off support for network policies in a specific addon
addons:
  ADDON_PACKAGE_NAME:
    values:
      networkPolicies:
        enabled: [true|false]

# For user defined packages deployed using the wrapper chart, this will turn on or off support for network policies in that package
package:
  PACKAGE_NAME:
    values:
      networkPolicies:
        enabled: [true|false]
```

## Crafting and Delivering Additional Network Policies

Sometimes you will want to apply additional [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/) to further isolate certain pods in your deployment. BigBang has adopted standardized mechanisms for crafting and deploying these Network Policies through the values provided to your BigBang core, supported addon or packages deployed with the big bang wrapper chart.

For BigBang core packages, you place these rules inside of the values for the given component:

```
CORE_PACKAGE_NAME:
  values:
    networkPolicies:
      enabled: true
      additionalPolicies: []
```

For BigBang supported addon packages, you place these rules inside of the values for the given package:

```
addons:
  ADDON_PACKAGE_NAME:
    values:
      networkPolicies:
        enabled: true
        additionalPolicies: []
```

For packages deployed with the wrapper chart, you add these rules inside of the values for the package:

```
packages:
  PACKAGE_NAME:
    values:
      networkPolicies:
        enabled: true
        additionalPolicies: []
```

In all cases, the `additionalPolicies` entry should be a list of YAML objects, each describing a single [Network Policy](https://kubernetes.io/docs/concepts/services-networking/network-policies/). You can add as many of these as you like. Consult [the upstream Kubernetes documentation](https://kubernetes.io/docs/concepts/services-networking/network-policies/) for more information on Network Policies, and what you can do with them.

```
additionalPolicies:
  - name: example-egress-policy-all-pods
      spec:
      podSelector: {}
      policyTypes:
      - Egress
      egress:
      - to:
          - ipBlock:
              cidr: 172.20.0.0/12
  - name: example-ingress-policy-all-pods
      spec:
      podSelector: {}
      policyTypes:
      - Ingress
      ingress:
      - from:
          - ipBlock:
              cidr: 172.20.0.0/12
```

## References

* [Kubernetes Network Policies Documentation](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
* [Kubernetes Labels and Selectors Documentation](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/)
* [Big Bang Developer Guide for Package Implementation](../../developer/develop-package.md)
* [Big Bang Developer Guide for Package Integration regarding Network Policies](../../developer/package-integration/network-policies.md)

For more information regarding the behavior of a specific core, supported addon or community supported package, you should always reference the documentation for the specific package in question. Information specific to any given package is outside the scope of this documentation.