# Package Development

Package is the term we use for an application that has been prepared to be deployed with the BigBang helm chart. BigBang Packages are wrappers around Helm charts. All of the pertinent information should be included in the chart/values.yaml for configuration of the Package. These values are then available to be overridden in the BigBang chat values.yaml file. The goal of these Packages is to take something that might be very complex and simplify it for consumers of BigBang. Rational and safe defaults should be used where possible while also allowing for overriding values when fine-grained control is needed. As much as possible test after each step so that the errors don't pile up, "code a little, test a little". Here are the steps:

1. Create a repository under the appropriate group ( example: Security Tools, Developer Tools, Collaboration Tools) in [Repo1](https://repo1.dso.mil/platform-one/big-bang/apps).

1. Create a "main" branch that will serve as the master branch.

1. There are two ways to start a new Package.  
   A. If there is no upstream helm chart we create a helm chart from scratch. Here is a T3 video that demonstrates creating a new helm chart. Create a directory called "chart" in your repo, change to the chart directory, and scaffold a new chart in the chart directory

   ```bash
   # scaffold new helm chart
   mkdir chart
   cd chart
   helm create name-of-your-application
   ```

   B. If there is an existing upstream chart we will use it and modify it. Essentially we create a "fork" of the upstream code. Use kpt to import the helm chart code into your repository. Note that kpt is not used to keep the Package code in sync with the upstream chart. It is a one time pull just to document where the upstream chart code came from. Kpt will generate a Kptfile that has the details. Do not manually create the "chart" directory.  The kpt command will create it. Here is an example from when Gitlab Package was created. It is a good idea to push a commit "initial upstream chart with no changes" so you can refer back to the original code while you are developing.

   ```bash
   kpt pkg get https://gitlab.com/gitlab-org/charts/gitlab.git@v4.8.0 chart
   ```

1. Run a helm dependency update that will download any external sub-chart dependencies. Commit any *.tgz files that are downloaded into the "charts" directory. The reason for doing this is that BigBang Packages must be able to be installed in an air-gap without any internet connectivity.

   ```bash
   helm dependency update
   ```

1. Edit the Chart.yaml and set the chart ```version:``` number to be compliant with the charter versioning which is {UpstreamChartVersion}-bb.{BigBangVersion}. Note that the chart version is not the same thing as the application version. If this is a patch to an existing Package chart then increment the {BigBangVersion}. Here is an example from Gitlab Runner.

   ```yaml
   apiVersion: v1
   name: gitlab-runner
   version: 0.19.2-bb.3
   appVersion: 13.2.2
   description: GitLab Runner
   ```

1. Some upstream helm charts have a file called "requirements.yaml" that contains internet links to external dependencies. Point all external links to the local file system. Also delete the dependency lock file that was generated during the previous step. Again, BigBang Packages must be able to be installed in an air-gap without any internet connectivity. It will look like this example from Gitlab.

   ```yaml
   dependencies:
   - name: gitlab
     version: '*.*.*'
     repository: file://./charts/gitlab
   - name: cert-manager
     version: 0.10.1
     repository: file://./charts/cert-manager-v0.10.1.tgz
     condition: certmanager.install
     alias: certmanager
   ```

1. In the values.yaml replace public upstream images with IronBank hardened images. The image version should be compatible with the chart version. Here is a command to identify the images that need to be changed.

   ```bash
   # list images
   helm template <releasename> ./chart -n <namespace> -f chart/values.yaml | grep image:
   ```

   Add the "imagePullSecrets" tag if not already there.  You can still test without the private-registry secret existing if your k8s cluster is configured with the pull credentials. Here is an example from Gitlab Package.

   ```yaml
   registry:
     enabled: true
     host: "registry.bigbang.dev"
     image:
       repository: registry1.dso.mil/ironbank/gitlab/gitlab/gitlab-container-registry
       tag: 13.7.2
       pullSecrets:
       - name: private-registry
   ```

1. Add a VirtualService if your application has a back-end API or a front-end GUI. Create the VirtualService in the sub-directory  "chart/templates/bigbang/VirtualService.yaml". You will need to manually create the "bigbang" directory. It is convenient to copy VirtualService code from one of the other Packages and then modify it. You should be able to load the application in your browser if all the configuration is correct.

1. Add a continuous integration(CI) pipeline to the Package. Copy the ./gitlab-ci.yml from another Package and add it to your Package.

   ```yaml
   include:
     - project: 'platform-one/big-bang/pipeline-templates/pipeline-templates'
       ref: master 
       file: '/templates/package-tests.yml'
   ```

1. If the Package requires dependencies to be installed before it can function properly add a ./tests/dependencies.yaml file to specify these. A great example of where this is required is packages that require an operator or a database.

   ```yaml
   dependencyname:
     git: "https://repo1.dso.mil/platform-one/big-bang/apps/DEPENDENCY.git" # Required: Git clone link for the dependency
     namespace: "namespace" # Optional: Specify the namespace to install the dependency chart, this will default to the "dependencyname" for the yaml block
     branch: "master" # Optional: Specify a specific branch/tag to install the dependency from
   ```

1. Add CI pipeline test to the Package. A Package should be able to be deployed by itself, independently from the BigBang chart. The Package pipeline takes advantage of this to run a Package pipeline test. Create a test directory and a test yaml file at "tests/test-values.yml".  Set any values that are necessary for this test to pass.  The pipeline automatically creates an image pull secret "private-registry-mil".  All you need to do is reverence that secret in your test values. You can view the pipeline status from the Repo1 console. Keep iterating on your Package code and the test code until the pipeline passes. Refer to the test-values.yml from other Packages to get started. The repo structure must match what the CI pipeline code expects.

   If your pipeline deploys a customresource (i.e. istio-controlplane deploys an "istiooperator" resource) you should add a wait script to make sure these resources are running properly before Cypress runs. Review this [README](https://repo1.dso.mil/platform-one/big-bang/pipeline-templates/pipeline-templates#using-the-infrastructure-in-your-package-ci-gitlab-pipeline) for how to set this up. The pipeline will run configuration tests, install your helm chart, and run cypress tests. If there is no UI or external facing API that could be tested using Cypress do not include those files and the pipeline will automatically skip over cypress testing.

   ```
   |-- .gitlab-ci.yml
   |-- chart
   |   |-- Chart.yml
   |   |-- charts
   |   |-- templates
   |   `-- values.yml
   `-- tests
       |-- cypress
       |   `-- integration
       |       `-- health.spec.js
       |-- cypress.json
       |-- main-test-gateway.yml
       `-- test-values.yml
   ```

1. Documentation for the Package should be included. A "docs" directory would include all detailed documentation. Reference other that Packages for examples.

1. Add the following markdown files to complete the Package. Reference other that Packages for examples of how to create them.

   ```  
   CHANGELOG.md      <  standard history of changes made  
   CODEOWNERS        <  list of the code maintainers. Minimum of two people from separate organizations  
   CONTRIBUTING.md   <  instructions for how to contribute to the project  
   README.md         <  introduction and high level information  
   ```

1. The Package structure should look like this when you are finished
![package-structure](uploads/ab22cc8f1d4295b84ddf9fc80a8fc4bc/package-structure.png)

1. Merging code should require approval from a minimum of 2 codeowners. To setup merge requests to work properly with CODEOWNERS approval change these settings in your project:  
Under Settings → General → Merge Request Approvals, change "Any eligible user" "Approvals required" to 1. Also ensure that "Require new approvals when new commits are added to an MR" is checked.  
Under Settings → Repository → Protected Branches, add the main branch with "Developers + Maintainers" allowed to merge, "No one" allowed to push, and "Codeowner approval required" turned on.  
Under Settings → Repository → Default Branch, ensure that main is selected.  

1. Development Testing Cycle: Test your Package chart by deploying with helm. Test frequently so you don't pile up multiple layers of errors. The goal is for Packages to be deployable independently of the bigbang chart. Most upstream helm charts come with internal services like a database that can be toggled on or off. If available use them for testing and CI pipelines. In some cases this is not an option. You can manually deploy required in-cluster services in order to complete your development testing.  
   Here is an example of an in-cluster postgres database

   ```bash
   helm repo add bitnami https://charts.bitnami.com/bitnami
   helm install postgres bitnami/postgresql -n postgres --create-namespace --set postgresqlPostgresPassword=postgres --set postgresqlPassword=postgres
   # test it
   kubectl run postgresql-postgresql-client --rm --tty -i --restart='Never' --namespace default --image bitnami/postgresql --env="PGPASSWORD=postgres" --command -- psql --host postgres-postgresql-headless.postgres.svc.cluster.local -U postgres -d postgres -p 5432
   # postgres commands
    \l             < list tables
    \du            < list users
    \q             < quit
   ```

   Here is an example of an in-cluster object storage service using MinIO (api compatible with AWS S3 storage)

   ```bash
   helm repo add minio https://helm.min.io/
   helm install minio minio/minio --set accessKey=myaccesskey --set secretKey=mysecretkey -n minio --create-namespace
   # test and configure it
   kubectl run minio-mc-client --rm --tty -i --restart='Never' --namespace default --image minio/mc --command -- bash
   # MinIo commands
   mc alias set minio http://minio.minio.svc.cluster.local:9000 myaccesskey mysecretkey      < set a connection alias
   mc mb minio/myBucket          < make a bucket
   mc ls minio                   < list the buckets
   ```

   Here are the dev test steps you can iterate:

   ```bash
   # test that the helm chart templates successfully and examine the output to insure expected results
   helm template <releasename> ./chart -n <namespace> -f chart/values.yaml
   # deploy with helm
   helm upgrade -i <releasename> ./chart -n <namespace> --create-namespace -f chart/values.yaml
   # conduct testing
   # tear down
   helm delete <releasename> -n <namespace>
   # manually delete the namespace to insure that everything is gone
   kubectl delete ns <namespace>
   ```

1. Wait to create a git tag release until integration testing with BigBang chart is completed.  You will very likely discover more Package changes that are needed during BigBang integration. When you are confident that the Package code is complete, squash commits and rebase your development branch with the "main" branch.

   ```bash
   git rebase origin/main
   git reset $(git merge-base origin/main $(git rev-parse --abbrev-ref HEAD))
   git add -A
   git commit -m "feat: example conventional commit"
   git push --force
   ```

1. Then, create a merge request to branch "main"

1. After the merge create a git tag following the charter convention of {UpstreamChartVersion}-bb.{BigBangVersion}. The tag should exactly match the chart version in the Chart.yaml.
example:    1.2.3-bb.0
