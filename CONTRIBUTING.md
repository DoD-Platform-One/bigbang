# Contributing

Thanks for contributing to this repository!

This repository follows the following conventions:

* [Semantic Versioning](https://semver.org/)
* [Keep a Changelog](https://keepachangelog.com/)
* [Conventional Commits](https://www.conventionalcommits.org/)

Development requires the Kubernetes CLI tool as well as a local Kubernetes cluster. [K3D](https://k3d.io/) is recommended as a lightweight local option for standing up Kubernetes clusters.

To contribute a change:

1. Create a branch on the cloned repository with a descriptive name, prefixed with your name or a tracking number (for work items). For example, `bb-123/add-ingress` is an appropriate branch name.
1. Make code changes.  Test the changes in your local environment before pushing them to Git.
1. Make commits using the [Conventional Commits](https://www.conventionalcommits.org/) format. This helps with automation for changelog. Update `CHANGELOG.md` in the same commit using the [Keep a Changelog](https://keepachangelog.com). Depending on tooling maturity, this step may be automated.
1. Write tests using [KUTTL](https://kuttl.dev) and [Conftest](https://conftest.dev)
1. Open a merge request using one of the provided templates. Reference any issues fixed in the merge request.
1. During this time, ensure that all new commits are rebased into your branch so that it remains up to date with the `main` branch.
1. Wait for a maintainer of the repository (see CODEOWNERS) to approve.
1. If you have permissions to merge, you are responsible for merging. Otherwise, a CODEOWNER will merge the commit.
