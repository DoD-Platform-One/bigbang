# Umbrella

Work in progress umbrella package

## Directory Structure

```bash
├── base                                            # common non-env specific
    ├── cert-manager
        ├── kustomization.yaml
        ├── ...
    ├── flux-system
        ├── kustomization.yaml
        ├── ...
    ├── gatekeeper
        ├── kustomization.yaml
        ├── ...
    ├── istio
        ├── kustomization.yaml
        ├── ...
    ├── logging
        ├── kustomization.yaml
        ├── ...
    ├── monitoring
        ├── kustomization.yaml
        ├── ...
├── aws                                             # assumes running on aws
    ├── base
        ├── bootstrap
            ├── gitrepositories
            ├── kustomizations
        ├── cert-manager
        ├── flux-system
        ├── gatekeeper
        ├── istio
        ├── logging
        ├── monitoring
    ├── instance
├── on-prem                                         # assumes running on-prem
    ├── base
        ├── bootstrap
            ├── sources
            ├── apps
    ├── instance
├── azure                                           # assumes running on azure
    ├── base
        ├── bootstrap
            ├── sources
            ├── apps
    ├── instance
```