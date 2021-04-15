# Affinity

# Kiali Operator

To configure the Kiali operator with an affinity or toleration, use the top level configuration:


```yaml
affinity: {}
tolerations: []
```


## Kiali

To configure the kiali deployment with affinity or toleration, use the following, which is copied from the Kiali example CR

```yaml
# Affinity definitions that are to be used to define the nodes where the Kiali pod should be contrained.
# See the Kubernetes documentation on Assigning Pods to Nodes for the proper syntax for these three
# different affinity types.
#    ---
cr:
    spec:
        affinity:
            node: {}
            pod: {}
            pod_anti: {}
        # A list of tolerations which declare which node taints Kiali can tolerate.
        # See the Kubernetes documentation on Taints and Tolerations for more details.
        #    ---
        tolerations: []
```