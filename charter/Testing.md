# Testing

There are multiple phases of testing for an application to get into a customer environment

## Types of Changes

* New Iron Bank Image
* Changes to Manifests for deployments
* Helm Chart Tests to verify operation within the cluster
* Newly supported configurations of application

## Testing Platform

Big Bang Applications will leverage GitLab Runners to execute these common BigBang Pipelines.  Each Big Bang application is required to use the Big Bang Pipelines, whose functionality is outlined here.

A detailed description of the pipelines and how to execute the testing process on a local system is described in the README.md in <https://repo1.dso.mil/platform-one/big-bang/pipeline-templates/pipeline-templates>.  

## Application Testing

When a Big Bang application developer submits changes to a particular Big Bang application, the application needs to be tested to ensure functionality, as well as compliance with core [Package Requirements](PackageRequirements.md).  

A core feature of all testing capabilities is its ability to be run locally by developers using their own environment, or by other teams looking to test proposed changes to the application (e.g. IronBank as part of container creation).  The GitLab pipelines will be simple wrappers around these common testing and deployment tools.

### Linting

Initial phases of the applications tests will focus on compliance with approved formatting and rendering policies for BigBang.  

### Smoke Deployments

The next phase of testing for each application will be to stand up healthy on a lightweight Kubernetes cluster.  The GitLab Runners will standup a ephemeral Kubernetes cluster for use for the deployment, deploy the application and its dependencies and ensure the application comes up "Healthy". The testing configuration will allow for a configuration of the application and the ability to define and test functionality.  

Each "Test" scenario will contain the following information:

1. The Kubernetes cluster to stand up.  Initial implementations will only allow customization of a k3d cluster.
2. Application configuration files.  Once a repository format/tool is decided, this may look like a Helm values file, or a set of Kustomization overlays on a base deployment.
3. A smoke test configuration file.  Format TBD based on tool decided.  Look at Locust.io, Selenium, Citrus

The Smoke tests will be run internal on the Kubernetes cluster via a Job.  The testing framework will inject a configuration object provided in the repo as a configmap for the job and run the job, ensure its successful, and provide the logs back to the user CI/CD pipeline for review.

### Helm Chart Testing

The Big Bang application pipelines have the ability to execute one or more [Helm Chart tests](https://helm.sh/docs/topics/chart_tests)
after a chart has been deployed to the cluster.  Helm tests deploy one or more pods/containers and any other supporting
kubernetes objects in order to verify that the application is operational.
  
For example, the  Minio instance package has additional CLI testing capabilities via the use of Helm Chart Tests.  These
tests invoke the MC command line tool to create, delete, populate, and retrieve information from Minio buckets.  Examples of
other types of Helm Chart Tests including:

* Validate that your configuration from the values.yaml file was properly injected.
* Make sure your username and password work correctly for the configuration
* Use CLI or API tests to access the application

The package pipelines have been enhanced to execute the "helm test" command and dump the log files of the tests results.

In order to add Helm Chart tests to your application, the following enhancements need to be made to the Helm Chart.

* A test directory is added to templates/ directory within the helm chart.  This directory contains Kubernetes object
definitions which are deployed only when a "helm Test" command is executed.  As an example, tests can be YAML files that
execute pods with containers, deploy config maps, secrets, or other objects.
* When a files contain a pod / container definition that executions tests, the container must return success or failure
(i.e., the container should exit successfully with an exit 0 for a test to be considered a success).
* Each test object definition must contain a "helm.sh/hook: test-success" annotation telling Helm that this object is a
test and should only be deployed when tests are executed. The following example create a configmap that is only
created during testing.

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: "{{ .Release.Name }}-cypress-test-configmap"
  annotations:
    "helm.sh/hook": test-success
    "helm.sh/hook-weight": "5"
    sidecar.istio.io/inject: "false"
  labels:
    helm-test: enabled
    {{- include "minio.labels" . | nindent 4 }}
  namespace: {{ .Release.Namespace }}
data:
{{ (.Files.Glob "cypress/*").AsConfig | indent 2 }}

```

Also note that the "helm.sh/hook-weight" can be used to order the creation and execution of test objects.

## Umbrella Testing

The end consumable is the [Umbrella Application](BigBang.md).  As new versions of Big Bang Applications become available, those changes need to be integrated into the Umbrella and tested.  Each Merge Request into the Umbrella Repo requires passing of an [Upgrade Tests](#upgrade-tests) and the [End to End Tests](#end-to-end-tests) for all mock environments.

### Environments

The Umbrella application will be tested for functionality with customer focused kubernetes environments.  As the Integration team works with customers to adopt Big Bang, the team will provide feedback to Umbrella Test Environments to provide representative environments to perform full End to End regression tests.  A representative environment for the e2e tests is Mock Fences, which attempts to mirror the Fences environment owned by GBSD.

Each Environment will contain the Infrastructure as Code (IaC) to deploy the base infrastructure that Big Bang will be deployed onto.  These tests will not validate that upgrades to IaC are successful.

### Upgrade Tests

The Umbrella application is responsible for not only deploying fresh environments, but managing the upgrades to existing environments.  As a result, a key component of testing is to validate that upgrades are successful.  The Umbrella test script will stand up the applications with the latest current release and then apply an upgrade to the changes in the Merge Request and ensure there is a safe process for upgrading.  If there are custom scripts needed to perform the upgrade, the umbrella application will have those configured as part of the application definition.

### End to End Tests

The GitLab job will then identify each set of smoke tests defined in each application and execute those tests on the upgraded mock environment to assure proper functionality of each application.

## Single Sign On (SSO)

Part of testing shall provide tests for Single Sign On verification that applications are able to be configured to use Keycloak.  For each application that has an SSO option, Keycloak will be deployed into the ephemeral cluster and the application will be configured to use the deployment for SSO.  The application will be required to have smoke tests that validate the ability to log into Keycloak.

## Testing Infrastructure

### Application Testing Infrastructure

The GitLab runners used for testing BigBang Applications will stand up dynamic [K3d](https://k3d.io/) or [Kind](https://kind.sigs.k8s.io/docs/) clusters.  To do this dynamically in Kubernetes, the pods need access to the host.  As a result, Big Bang with deploy and managed a separate Kubernetes cluster that GitLab will use to deploy ephemeral Kubernetes clusters for testing.

This cluster will remain separate from the environment running GitLab since the use of privileged containers could pose a security risk to adjacent pods on the nodes.

### Umbrella Testing Infrastructure

The GitLab Runners used for Umbrella testing will be provided appropriate service account credentials to provision mock environments.  For AWS environments, the environment will reside in the same project as GitLab.  For other cloud providers, a dedicated project will be provisioned to be used exclusively by BigBang Umbrella testing.  As a result, there must be the ability to have concurrent environments in the same cloud project.

#### Umbrella Clusters

Clusters for testing the Umbrella app will be provisioned from vendors that allow for creation of dev and test clusters without licencing limitations.  Vendors will be required to provide

1. A repository inside <https://repo1.dso.mil/platform-one/distros> to maintain code
2. A GitLab pipeline task that provisions their distribution: [Vendor Distribution Integration](VendorDistroIntegration.md)
