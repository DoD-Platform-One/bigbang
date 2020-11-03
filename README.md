# Umbrella

Work in progress umbrella package

## Usage

```
# As a helm chart
helm install bigbang chart/ -n flux-system

# If you don't like helm
helm template bigbang chart/ -n flux-system | kubectl apply -f -
```

You can also point a `HelmRelease` to this repository as so:

```yaml
---
apiVersion: source.toolkit.fluxcd.io/v1beta1
kind: GitRepository
metadata:
  name: umbrella
  namespace: flux-system
spec:
  url: https://repo1.dsop.io/platform-one/big-bang/apps/sandbox/umbrella.git
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: bigbang
  namespace: flux-system
spec:
  chart:
    spec:
      chart: chart/
      sourceRef:
        kind: GitRepository
        name: umbrella
        namespace: flux-system
```

The `umbrella` helm chart is configurable through a variety of means, please see [TODO]() for more info.