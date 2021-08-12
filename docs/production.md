# Big Bang Production

Table of Contents

- [Big Bang Production](#big-bang-production)
  - [Production Deployment](#production-deployment)

## Production Deployment

The gatekeeper `values` section should resemble below when deploying to production.
```
# OPA Gatekeeper
#
gatekeeper:
  # -- Toggle deployment of OPA Gatekeeper.
  enabled: true
  git:
    repo: https://repo1.dso.mil/platform-one/big-bang/apps/core/policy.git
    path: "./chart"
    tag: "3.5.1-bb.2"

  # -- Flux reconciliation overrides specifically for the OPA Gatekeeper Package
  flux: {}

  # -- Values to passthrough to the gatekeeper chart: https://repo1.dso.mil/platform-one/big-bang/apps/core/policy.git
  values:
      violations:
        allowedDockerRegistries:
          match:
            excludedNamespaces: 
              - kube-system # ignored as the kubernetes distro cannot be controlled

  # -- Post Renderers.  See docs/postrenders.md
  postRenderers: []
```

To validate it was deployed correctly on your cluster run the following command:

`kubectl get k8sallowedrepos.constraints.gatekeeper.sh/allowed-docker-registries -o yaml`

You should only see `kube-system` under `excludedNamespaces` section.

Output:
```
  name: allowed-docker-registries
  resourceVersion: "10390"
  uid: b51b3887-3cf8-4495-b37e-fb8ef31755db
spec:
  enforcementAction: deny
  match:
    excludedNamespaces:
    - kube-system
    kinds:
    - apiGroups:
      - ""
      kinds:
      - Pod
  parameters:
    exemptContainers: []
    repos:
    - registry1.dso.mil
    - registry.dso.mil
```


