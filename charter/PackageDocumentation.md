# Package Documentation

## Documentation Needed

For every package, we need to inform users how to configure the application.
This includes:

* Pre-installation configuration parameters
* Post-installation package configuration
* SSO Integration

## Delivery Method

The documentation should be versioned along-side the package as it is released. The end user also needs a consistent way to view this documentation when BigBang and addons are installed into a Kubernetes Cluster. This should over time have parity with features that are offered on Party Bus.

## Tooling

### Needs

* Documentation should be easily accessible to an end user when BigBang is installed
* Needs to be air-gapped friendly for those in disconnected environments
* Links should be clickable within the documentation. i.e. sonarqube.bigbang.dev might be sonarqube.customer.mil

### What is Hugo

Hugo is a website template engine. It can take a group of files and create a static website from them. Input can be a variety of formats including markdown.

### BigBang Usage of Hugo

Since we already write documentation in markdown, little work will be needed to convert these markdown files into something Hugo can render. The idea is to enforce a directory structure for the documentation so that Hugo can pull in relevant documentation and render it once installed.

The documentation should include:

* Purpose of the tool or add-on
* Recommended post-installation configuration
* Optional post-installation configuration
* Additional configuration that can be done on the tool through automation

## Hugo Specifics

### How it works

1. Each package contains a docs folder with the file structure below.
2. When the documentation package spins up, it reaches out to all the relevant repos and downloads the docs folder into the hugo container.
3. The container than does a hugo compile with all the documentation to give us our static site.

### Directory Structure

```text
package
|--docs
   |  index.html [landing page for application within hugo]
   |  overview.md [Overview of application, purpose, and default config options]
   |  keycloak.md [Manual or automated steps to configure sso]
   |  example-optional-config.md [Additional files for optional configuration for the app]
```

### Formatting Needed

Each file should start with a block that looks as follows:

```text
+++
draft = false

title = "ArgoCD Overview"
author = "Big Bang Team"

virtualServices = ["argocd"]
+++
```

By including this at the top of a markdown file, hugo can now render this page.

### CI/CD pipeline additions

* Ensure that docs meet the standards when changes occur
