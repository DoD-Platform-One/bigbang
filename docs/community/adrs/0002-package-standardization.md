# 2. Package Standardization

Date: 2025-03-11

## Status

Accepted

## Context

Right now the Big Bang project has a lot of packages that have similar structures but are named differently. This makes it difficult for developers to understand the project and navigate through it. The Big Bang team has been working on standardizing the package structure to make it more consistent and easier to understand.

## Decision

The Big Bang team will standardize the package structure by creating a package template that will be used for all new packages. The package template will include the following:

```
.
├── .gitignore
├── CHANGELOG.md
├── CODEOWNERS
├── CONTRIBUTING.md
├── LICENSE
├── README.md
├── renovate.json
├── chart
│   ├── .gitignore
│   ├── .helmignore
│   ├── Chart.lock
│   ├── Chart.yaml
│   ├── Kptfile
│   ├── README.md
│   ├── values.yaml
│   ├── templates
│   │   └── bigbang
│   │       ├── dashboards
│   │       │   └── .gitkeep
│   │       ├── istio
│   │       │   ├── authorization-policies
│   │       │   │   └── .gitkeep
│   │       │   ├── peer-authentications
│   │       │   │   └── .gitkeep
│   │       │   ├── service-entries
│   │       │   │   └── .gitkeep
│   │       │   ├── sidecars
│   │       │   │   └── .gitkeep
│   │       │   └── virtual-services
│   │       │       └── .gitkeep
│   │       └── network-policies
│   │           └── .gitkeep
│   └── tests
│       └── .gitkeep
├── docs
│   ├── DEVLEOPMENT_MAINTENANCE.md
│   └── ISTIO_HARDENED.md
└── tests
    └── test-values.yaml
```

This will be stubbed out and maintained in the [Master_Template](https://repo1.dso.mil/big-bang/repository-templates/master_template) repository. Issues will be created against existing packages in [the integrated](https://repo1.dso.mil/big-bang/product/packages) and [maintained](https://repo1.dso.mil/big-bang/product/maintained) repositories to update their package structure to match the template. This conformity needs to be added to the [Package Maintenance Tracks](https://repo1.dso.mil/big-bang/product/bbtoc/-/blob/master/process/Package%20Maintenance%20Tracks.md) as part of the promotion process.


## Consequences

If the team doesn't adopt this, there will not be a standard package structure in the Big Bang project.

If the team adopts this, the package structure in the Big Bang project will be more consistent and easier to understand.

This should be a public ADR because it is related to the architecture of the Big Bang project and will help the community understand the decisions that are being made in the project.
