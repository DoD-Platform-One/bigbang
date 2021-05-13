# Post Renderers

[Flux V2](https://toolkit.fluxcd.io/) provides the ability to apply kustomizations on a Helm Release after rendering using a [Post Renderer](https://toolkit.fluxcd.io/components/helm/helmreleases/#post-renderers).  This feature provides significant flexibility to the Helm objects, and allows for adjusting values inside of Helm that are not exposed explicitly as part of the values file. Each `HelmRelease` is configured with a `postRenderer` pass through:

```yaml
...
jaeger:
  postRenderers:
    - kustomize:
    # Array of inline strategic merge patch definitions as YAML object.
    # Note, this is a YAML object and not a string, to avoid syntax
    # indention errors.
    patchesStrategicMerge:
    # Change operator deployment to be a rolling update
    - kind: Deployment
      apiVersion: apps/v1
      metadata:
        name: jaeger-operator
      spec:
        strategy:
          type: RollingUpdate
    patchesJson6902:
    # change priorityClassName
    - target:
        version: v1
        kind: Deployment
        name: jaeger-operator
        patch:
        - op: add
            path: /spec/template/priorityClassName
            value: system-cluster-critical
    images:
    # update image to a new tag
    - name: registry1.dso.mil/ironbank/opensource/jaegertracing/jaeger-operator
      newName: registry1.dso.mil/ironbank/opensource/jaegertracing/jaeger-operator
      newTag: 1.23.0
```
