# Big Bang Package: Supported Package Integration

After [graduating your package](https://repo1.dso.mil/platform-one/bbtoc/-/tree/master/process) and getting approval to add it to Big Bang, the following instructions must be completed.

[[_TOC_]]

## Prerequisites

- [Helm](https://helm.sh/docs/intro/install/)
- [Kubectl](https://kubernetes.io/docs/tasks/tools/#kubectl)
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- A multi-node Kubernetes cluster to deploy Big Bang and your package
- Graduated package Helm chart in a Git repository

## Package Updates

1. Have a Big Bang owner move the package's GitLab project from sandbox to `https://repo1.dso.mil/platform-one/big-bang/apps/<category>`.

1. Have a Big Bang maintainer create a new tag and release for your project that matches your Helm chart `version` in `chart/Chart.yaml`.

## Big Bang Updates

1. Open an issue under `https://repo1.dso.mil/platform-one/big-bang/bigbang/-/issues` to track your work for the new package.

1. Clone the [Big Bang Git repository](https://repo1.dso.mil/platform-one/big-bang/bigbang) to your machine using `git clone https://repo1.dso.mil/platform-one/big-bang/bigbang`

1. Make a branch from the BigBang chart repository `master` branch. You can automatically create a branch from the Repo1 Gitlab issue. Or, in some cases you might manually create the branch. Name the branch with your issue number. For example, if your issue number is `9999` then your branch name can be `9999-my-description`. It is best practice to make branch names short and simple.

1. Make sure the files described in this [document](./package-integration-flux.md) have been generated in `chart/templates/<your-package-name>` directory

1. More details about secret-*.yaml: The secret template is where the code for secrets go. Typically you will see secrets for imagePullSecret, sso, database, and possibly object storage. These secrets are a BigBang chart enhancement. They are created conditionally based on what the user enables in the config. For example if the app supports SSO and will need a Certificate Authority supplied to trust the connection to the IdP there should be a `secret-ca.yaml` template to populate a secret with the `sso.certificate_authority` value in the application namespace.

1. Merge your default package values from `<your-package-git-folder>/bigbang/values.yaml` into `chart/values.yaml`.  Only the "standard" keys used across packages should be used.  Keep in mind that values can be passed directly to the package using `.Values.<package>.values`

   > If your package is an `addon`, it falls into a different location than core packages.  In this case, you will need to update all your references from `.Values.<package>` to `.Values.addons.<package>`.

   Example:

   ```yaml
   addons:
     mypackage:
       enabled: false     # default to false
       git:
         repo: https://repo1.dsop.io/platform-one/big-bang/apps/developer-tools/mypackage.git
         path: "./chart"
         tag: "1.2.3-bb.0"
       sso:
         enabled: false   # default to false
         client_id: ""
       database:
         host: ""
         port: ""
         username: ""
         database: ""
         password: {} # unencoded stringData
       objectstorage:
         type: s3   # supported types are "s3" or "minio"
         endpoint: "" # ignored if type is "s3". used only for minio. example " http://minio.minio.svc.cluster.local:9000"
         host: s3.amazonaws.com  # used for gitlab backup storage
         region: us-west-1
         accessKey: ""
         accessSecret: ""
         bucketPrefix: ""  # optional. example: dev-
       values: {}
   ```

1. Edit `tests/test-values.yaml`. These are the settings that the CI pipeline uses to run a deployment test.  Set your Package to be enabled and add any other necessary values. Where possible reduce the number of replicas to a minimum to reduce strain on the CI infrastructure. When you commit your code the pipeline will run. You can view the pipeline in the Repo1 Gitlab console. Fix any errors in the pipeline output. The pipeline automatically runs a "smoke" test. It deploys bigbang on a k3d cluster using the test values file.

1. You will also need to create an MR into the pipeline templates to update [02_wait_for_helmreleases.sh](https://repo1.dso.mil/platform-one/big-bang/pipeline-templates/pipeline-templates/-/blob/master/scripts/deploy/02_wait_for_helmreleases.sh) and add your package's HR name to the core or addon lists.

    To test your pipeline changes you can make a draft MR pointing to your pipeline branch in `.gitlab-ci.yml`:
    ```
    include:
      - project: 'platform-one/big-bang/pipeline-templates/pipeline-templates'
        ref: your-branch
        file: '/pipelines/bigbang.yaml'
    variables:
      PIPELINE_REPO_BRANCH: 'your-branch'
    ```

1. Create an overrrides directory as a sibling directory next to the bigbang code directory. Put your override yaml files in this directory. The reason we do this is to avoid modifying the bigbang values.yaml that is under source control. You could accidentally commit it with your secrets. Avoid that mistake and create a local overrides directory. One option is to copy the tests/ci/k3d/values.yaml to make the override-values.yaml and make modifications. The file structure is like this:

    ```plaintext
    ├── bigbang/
    └── overrides/
        ├── override-values.yaml
        ├── registry-values.yaml
        └── any-other-values.yaml
    ```

    Make the registry-values yaml like this:

    ```yaml
    registryCredentials:
    - registry: registry1.dso.mil
      username: your-name
      password: your-pull-token
      email: xxx@xxx.xxx
    ```

    You will use these files as arguments in your helm commands.

1. Verify your Package works when deployed through bigbang. See the instructions below in the ```BigBang Development and Testing Cycle``` for the manual ```imperative``` way to deploy with helm upgrade commands. While testing you should use your package git branch instead of a tag. If you don't null the tag your branch will not get deployed. example:

    ```yaml
    addons:
      app1:
        git:
          tag: null
          branch: "999-your-dev-branch-name"
    ```

1. After you have tested BigBang integration complete a Package MR and contact the codeowners to create a release tag. Package release tags follow the naming convention of {UpstreamChartVersion}-bb.{BigBangVersion} – example 1.2.3-bb.0.

1. Make sure to change the chart/values.yaml file to point to the new release tag rather than your dev branch (i.e. tag: "1.2.3-bb.0" in place of branch: "999-your-dev-branch-name"). example:

    ```yaml
    addons:
      app1:
        git:
          tag: "1.2.3-bb.0"
    ```

1. When you are done developing the BigBang chart features for your Package make a merge request in "Draft" status and add a label corresponding to your package name (must match the name in `values.yaml`). Also add any labels for dependencies of the package that are NOT core apps. The merge request will start a pipeline and use the labels to determine which addons to deploy. Fix any errors that appear in the pipeline. When the pipeline has pass and the MR is ready take it out of "Draft" and add the `status::review` label. Address any issues raised in the merge request comments.

## BigBang Development and Testing Cycle

There are two ways to test BigBang, imperative or GitOps with Flux.  Your initial development can start with imperative testing.  But you should finish with GitOps to make sure that your code works with Flux.

### Imperative

You can manually deploy bigbang with helm command line. With this method you can test local code changes without committing to a repository. Here are the steps that you can iterate with "code a little, test a little". You should have previously created the ../overrides directory as described in step #10 above. From the root of your local bigbang repo:

```shell
# Deploy with helm while pointing to your override values files. 
# In this example the files are placed on your workstation at ../overrides/*
# Bigbang packages should create any needed secrets from the chart values
# If you have the values file encrypted with sops, temporarily decrypt it
helm upgrade -i bigbang ./chart -n bigbang --create-namespace -f ../overrides/override-values.yaml -f ../overrides/registry-values.yaml -f ./chart/ingress-certs.yaml

# Conduct testing
# If you make code changes you can run another helm upgrade to pick up the new changes
helm upgrade -i bigbang ./chart -n bigbang --create-namespace -f ../overrides/override-values.yaml -f ../overrides/registry-values.yaml -f ./chart/ingress-certs.yaml

# Tear down
helm delete bigbang -n bigbang
# Helm delete will not delete the bigbang namespace
kubectl delete ns bigbang
# Istio namespace will be stuck in "finalizing". So run the script to delete it.
./scripts/remove-ns-finalizer.sh istio-system
```

### GitOps with Flux

Using GitOps for development is NOT recommended. Your development iteration cycle time will be slowed down waiting for flux reconciliation. This is not an efficient use of your time. These instructions are included here for informational purposes. You can deploy your development code the same way a customer would deploy using GitOps. You must commit any code changes to your development branches because this is how GitOps works. There is a [customer template repository](https://repo1.dso.mil/platform-one/big-bang/customers/template) that has an example template for how to deploy using BigBang. You must fork or copy this repo to your own private repo. Make the necessary modifications as explained in the README.md. The setup information is not repeated here. Before committing code it is a good idea to manually run `helm template` and a `helm install` with dry run. This will reveal many errors before you make a commit. Here are the steps you can iterate:

```shell
# Verify chart code before committing
helm template bigbang ./chart -n bigbang -f ../customers/template/dev/configmap.yaml --debug
helm install bigbang ./chart -n bigbang -f ../customers/template/dev/configmap.yaml --dry-run
# Commit and push your code
# Deploy your bigbang template
kubectl apply -f dev/bigbang.yaml
# Monitor rollout
watch kubectl get pod,helmrelease -A
# Conduct testing
# Tear down
kubectl delete -f dev/bigbang.yaml
# Istio namespace will be stuck in "finalizing". So run the script to delete it. You will need 'jq' installed
./scripts/remove-ns-finalizer.sh istio-system

# If you have pushed code changes before the tear down, occasionally the bigbang deployments are not terminated because Flux has not had enough time to reconcile the helmreleases

# Re-deploy bigbang
kubectl apply -f dev/bigbang.yaml
# Run the sync script.
./scripts/sync.sh
# Tear down
kubectl delete -f dev/bigbang.yaml
./scripts/remove-ns-finalizer.sh istio-system
```

### Validation

In order to validate that the new package is running as expected, we recommend to check the following things

1. Make sure that the steps from the other documentation in `package-integration` directory has been completed

1. Deploy the package following the Imperative step described [above](#imperative)

1. Make sure that a namespace has been created for the package deployed (`kubectl get ns`)

1. The HR (Helm Release) reconciled successfully for the package (`kubectl get hr -A`)

1. All the pods and services we expected are up and running (`kubectl get po -n <Package Namespace>`)

1. Make sure all the pods are in a healthy state and have the right specs

1. Utilize grafana to make sure the pods have the right resources if needed

1. Create an MR and make sure it passes all the automated tests
