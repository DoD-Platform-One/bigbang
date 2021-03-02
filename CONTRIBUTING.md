# Contributing

Thanks for contributing to this repository!

This repository follows the following conventions:

* [Semantic Versioning](https://semver.org/)
* [Keep a Changelog](https://keepachangelog.com/)
* [Conventional Commits](https://www.conventionalcommits.org/)

Development requires the Kubernetes CLI tool as well as a local Kubernetes cluster. [k3d](https://k3d.io) is recommended as a lightweight local option for standing up Kubernetes clusters.

To contribute a change:

1. Create a branch on the cloned repository
2. Make the changes in code.
3. Write tests using [cypress](https://www.cypress.io) and [Conftest](https://conftest.dev)
4. Make commits using the [Conventional Commits](https://www.conventionalcommits.org/) format. This helps with automation for changelog. Update `CHANGELOG.md` in the same commit using the [Keep a Changelog](https://keepachangelog.com). Depending on tooling maturity, this step may be automated.
5. Open a merge request using one of the provided templates. If this merge request is solving a preexisting issue, add the issue reference into the description of the MR.
6. During this time, ensure that all new commits are rebased into your branch so that it remains up to date with the `main` branch.
7. Wait for a maintainer of the repository (see CODEOWNERS) to approve.
8. If you have permissions to merge, you are responsible for merging. Otherwise, a CODEOWNER will merge the commit.
