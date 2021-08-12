# Developer Documentation

[[_TOC_]]

## Charter

The [BigBang Charter](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/tree/master/charter) is required reading for BigBang developers. Study all the documents carefully before you start developing.  The Charter lays out the policies, requirements, and responsibilities for the BigBang product and the supported Packages (applications). At a high level, the BigBang product is a helm chart that wraps the deployment of DevSecOps applications (Packages). The goal of BigBang is to hide the complexity of deploying and integrating the supported Packages. Customers should be able to easily deploy and configure a DevSecOps environment. BigBang is intended to deploy on any OCI/CNCF compliant Kubernetes cluster.

## Communications

Join Mattermost channels to ask questions and communicate with the team. The team also has a daily Scrum at 8:15 am MST. The link for the stand up is found on the [Big Bang Group Calendar](https://confluence.il2.dso.mil/display/BB1/calendar/dfb757d4-110c-4aac-80d8-516fd2d0cea8?calendarName=Big%20Bang%20Group%20Calendar). Here is the list of relevant Mattermost channels for BigBang development:  

* [Value Stream - Big Bang](https://chat.il2.dso.mil/platform-one/channels/team---big-bang)
* [Topic - Big Bang Documentation](https://chat.il2.dso.mil/platform-one/channels/topic-big-bang-documentation)

## Big Bang Framework

Big Bang is a helm chart of helm charts. Big Bang uses [Flux 2](https://fluxcd.io/) to deploy [Helm](https://helm.sh/) charts. The Helm charts that are deployed by BigBang are called Packages. The [Package repositories](https://repo1.dso.mil/platform-one/big-bang/apps) are organized into groups such as core, security tools, developer tools, collaboration tools, etc.

## Set up a development environment

[Development Environment](./development-environment.md)

## Package Development

[Develop a Big Bang Package](./develop-package.md)

## Add Package to Big Bang

[Integrate Package with Big Bang](./package-integration.md)
