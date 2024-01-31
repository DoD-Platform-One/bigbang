# Big Bang Package Readme Generation

Note the Big Bang package README.md is separate from the README.md included as part of the upstream chart. See ArgoCD for an example, [Big Bang package README.md](https://repo1.dso.mil/big-bang/product/packages/argocd/-/blob/main/README.md?ref_type=heads) vs [upstream chart README.md](https://repo1.dso.mil/big-bang/product/packages/argocd/-/blob/main/chart/README.md?ref_type=heads)

Each package value in values.yaml should have a comment descriptor above the value. We generate the package README.md using a script that expects this format. The README.md will contain a table with default configurations and descriptors pulled from the comments.

# This is a comment for the value below
enabled: false

# This comment describes the purpose of the configurable value below
strategy: scalable
