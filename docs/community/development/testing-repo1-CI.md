# Testing repo1 CI against a dedicated runner

This page will describe how to deploy bigbang with a GitLab Runner that is connected to repo1. Source documentation for GitLab Runner is available at https://docs.gitlab.com/runner/.

## Why

* You need to test GitLab Runner configuration against repo1
* You need to test integrating CI pipelines to infrastructure or other bigbang services.

## How

### Request access

You will need either of these:

* Admin access to a repo on repo1
* Or access to create personal repos under your account on repo1

Contact the Big Bang Government Team Lead to request access.

### Create gitlab runner and token

1. Go to *Settings -> CI/CD* on the repo you want to test against.
1. Expand the *Runners* section and click *New project runner*
1. Select *Run untagged jobs* and *Lock to current projects* and click *Create runner*
1. On the next page Copy the *runner authentication token* for later

### Deploy a k8s cluster and install flux

by default the easiest way to test is to spin up a cluster using the k3d-dev.sh script.
you can follow the directions <https://repo1.dso.mil/big-bang/bigbang/-/blob/master/docs/developer/aws-k3d-script.md>

### Deploy Big Bang

1. Create an overrides file with the following content, along with any additional [configuration settings](https://docs.gitlab.com/runner/executors/kubernetes/#configuration-settings) you need to test

```yaml
# enable grafana alloy to push traces to
addons:
  alloy:
    enabled: true

# enable gitlabrunners for ci-tracing
  gitlabRunner:
    enabled: true
    values:
      # set the url to repo1
      gitlabUrl: https://repo1.dso.mil
      runners:
        # use custom config and remove cloneUrl paramaters
        config: |
          [[runners]]
            [runners.kubernetes]
              pull_policy = "always"
              namespace = "{{.Release.Namespace}}"
              image = "{{ printf "%s/%s:%s" .Values.runners.job.registry .Values.runners.job.repository .Values.runners.job.tag }}"
              helper_image = "{{ printf "%s/%s:%s" .Values.runners.helper.registry .Values.runners.helper.repository .Values.runners.helper.tag }}"
              image_pull_secrets = ["private-registry"]
            [runners.kubernetes.pod_security_context]
              run_as_non_root = true
              run_as_user = 1001
            [runners.kubernetes.helper_container_security_context]
              run_as_non_root = true
              run_as_user = 1001
            [runners.kubernetes.pod_labels]
              "job_id" = "${CI_JOB_ID}"
              "job_name" = "${CI_JOB_NAME}"
              "pipeline_id" = "${CI_PIPELINE_ID}"
              "app" = "gitlab-runner"
```

1. Deploy BigBang with the above override file

```bash
helm upgrade -i bigbang ./chart -n bigbang --create-namespace -f ./docs/assets/configs/example/policy-overrides-k3d.yaml -f ../overrides/registry-values.yaml -f ./chart/ingress-certs.yaml -f ../overrides/gitlabrunner-test.yaml
```

1. Create a secret with the token for the runner
Replace *runnertoken* with the token that was created for the runner.

```bash
kubectl -n gitlab-runner create secret generic gitlab-gitlab-runner-secret --from-literal=runner-registration-token=runnertoken --from-literal=runner-token=runnertoken
```

1. Validate that the runner is connected to repo1. Goto the repo on repo1 then *Settings->CI/CD*, expand the *Runners* section the runner should be marked as green.
1. Now create a CI workflow for the repo and let it run, it should choose the gitlab runner on your k3d cluster.
