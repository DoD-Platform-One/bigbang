# Welcome 👋

We appreciate you taking time to contribute to Big Bang pipelines!

&nbsp;

## Overview

- Big Bang pipelines run on a [GitLab Runner](https://docs.gitlab.com/runner/) in a Kubernetes cluster that we manage

- This [diagram](https://docs.gitlab.com/runner/executors/kubernetes.html#kubernetes-executor-interaction-diagram) depicts the overall flow of how GitLab Runner pipeline jobs are executed in Kubernetes

- Each pipeline job is executed in an ephemeral Kubernetes pod

- We build and manage [container images](https://repo1.dso.mil/big-bang/pipeline-templates/pipeline-templates/-/tree/master/dockerfiles) that are used in our pipelines. These images provide the environment that most of our pipeline jobs are executed in

- If you want to learn more about Big Bang pipelines, checkout the [readme](https://repo1.dso.mil/big-bang/pipeline-templates/pipeline-templates/-/blob/master/README.md) and this Big Bang developer [doc](https://repo1.dso.mil/big-bang/bigbang/-/blob/master/docs/developer/ci-workflow.md)