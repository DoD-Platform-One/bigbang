# Package Development

Package is the term we use for an application that has been prepared to be deployed with the Big Bang helm chart. Big Bang Packages are wrappers around Helm charts. All of the pertinent information should be included in the chart/values.yaml for configuration of the Package. These values are then available to be overridden in the Big Bang chart/values.yaml file. The goal of these Packages is to take something that might be very complex and simplify it for consumers of Big Bang. Rational and safe defaults should be used where possible while also allowing for overriding values when fine-grained control is needed. As much as possible, test after each step so that the errors don't pile up; "code a little, test a little." The steps are provided in the following:

1. Create a repository under the appropriate group (e.g., Security Tools, Developer Tools, Collaboration Tools) in [Repo1](https://repo1.dso.mil/big-bang/apps).
2. Create a "main" branch that will serve as the master branch.
3. There are two ways to start a new package.  
    1. If there is no upstream helm chart, we create a helm chart from scratch. Here is a T3 video that demonstrates creating a new helm chart. Create a directory called "chart" in your repo, change to the chart directory, and scaffold a new chart in the chart directory.
        ```shell
        # Scaffold new helm chart
        mkdir chart
        cd chart
        helm create name-of-your-application
        ```
    2. If there is an existing upstream chart, we use the passthrough chart pattern. This involves creating a "passthrough" chart that includes the upstream chart as a dependency. Create a `chart` directory and add a `Chart.yaml` that defines the upstream chart as a dependency:
        ```shell
        # Create chart directory structure
        mkdir -p chart/templates/bigbang
        ```
        Create `chart/Chart.yaml` with the upstream chart as a dependency:
        ```yaml
        apiVersion: v1
        version: 6.9.0-bb.0
        appVersion: 6.9.0
        name: your-package-name
        engine: gotpl
        description: Your Package Helm chart for Kubernetes
        dependencies:
          - name: upstream-chart-name
            version: 6.9.0
            repository: https://upstream-helm-repo.example.com
            alias: upstream
        kubeVersion: ">=1.23.0-0"
        annotations:
          bigbang.dev/maintenanceTrack: bb_integrated
          helm.sh/images: |
            - name: your-app
              image: registry1.dso.mil/ironbank/path/to/your-app:6.9.0
        ```
4. Run a helm dependency update that will download the upstream chart as a dependency as well as any external sub-chart dependencies. Commit any *.tgz files that are downloaded into the "charts" directory. The reason for doing this is that BigBang Packages must be able to be installed in an air-gap without any internet connectivity.
    ```shell
    helm dependency update ./chart
    ```
5. Edit the Chart.yaml and set the chart `version:` number to be compliant with the charter versioning which is {UpstreamChartVersion}-bb.{BigBangVersion}. Note that the chart version is not the same thing as the application version. If this is a patch to an existing Package chart then increment the {BigBangVersion}. Here is an example from Gitlab Runner.
    ```yaml
    apiVersion: v1
    name: gitlab-runner
    version: 0.19.2-bb.3
    appVersion: 13.2.2
    description: GitLab Runner
    ```
6. In the values.yaml replace public upstream images with IronBank hardened images using the `upstream` key. The image version should be compatible with the chart version. Here is a command to identify the images that need to be changed.
    ```shell
    # list images from the upstream chart
    helm template <releasename> ./chart -n <namespace> -f chart/values.yaml | grep image:
    ```
    Add the image overrides, **do not** copy the upstream defaults, in your package's `values.yaml` using the `upstream` key to pass values to the upstream chart. Also add the "imagePullSecrets" tag if not already there. Here is an example:
    ```yaml
    # Big Bang specific values
    networkPolicies:
      enabled: true
    
    # Values passed to upstream chart
    upstream:
        nameOverride: "kiali-operator"

        image:
            repo: registry1.dso.mil/ironbank/opensource/kiali/kiali-operator
            tag: v2.12.0
            pullPolicy: IfNotPresent
            pullSecrets:
            - private-registry
    ```
7. Add a VirtualService if your application has a back-end API or a front-end GUI. Create the VirtualService in the sub-directory  "chart/templates/bigbang/VirtualService.yaml". You will need to manually create the "bigbang" directory. It is convenient to copy VirtualService code from one of the other Packages and then modify it. You should be able to load the application in your browser if all the configuration is correct.
8. Add NetworkPolices templates in the sub-directory "chart/templates/bigbang/networkpolicies/*.yaml." The intent is to lock down all ingress and egress traffic except for what is required for the application to function properly. Start with a deny-all policy and then add additional policies to open traffic as needed. Refer to the other Packages code for examples. The [Gitlab package](https://repo1.dso.mil/big-bang/product/packages/gitlab/-/tree/main/chart/templates/bigbang/networkpolicies) is a good/complete example.
9. Add a Continuous Integration (CI) pipeline to the Package and configure Renovate for automated dependency updates. A Package should be able to be deployed by itself, independently from the Big Bang chart. The Package pipeline takes advantage of this to run a Package pipeline test. The package testing is done with a helm test library. Reference the [pipeline documentation](https://repo1.dso.mil/big-bang/pipeline-templates/pipeline-templates#setting-up-your-project-with-pipelines) for how to create a pipeline and also [detailed instructions](https://repo1.dso.mil/big-bang/apps/library-charts/gluon/-/blob/master/docs/bb-tests.md) in the gluon library.
    Configure Renovate to automatically update the upstream chart dependency by adding a `renovate.json` file:
    ```json
    {
        "baseBranches": ["main"],
        "configWarningReuseIssue": false,
        "dependencyDashboard": true,
        "dependencyDashboardTitle": "Renovate: Upgrade MyPackage Package Dependencies",
        "draftPR": true,
        "enabledManagers": ["helm-values","regex", "helmv3"],
        "ignorePaths": ["chart/charts/**"],
        "labels": ["renovate"],
        "packageRules": [
            {
            "matchDatasources": ["docker"],
            "groupName": "Ironbank"
            },
            {
                "matchPackageNames": ["registry1.dso.mil/ironbank/big-bang/base"],
                "allowedVersions": "!/8.4/"
            }      
        ],
        "regexManagers": [
            {
                "fileMatch": ["^chart/values\\.yaml$"],
                "matchStrings": [
                    "(repo|image_name|repository)\\S*:\\s*(?<depName>\\S+).*\n\\s+(tag|image_version):\\s*(?<currentValue>.+)"
                ],
                "datasourceTemplate": "docker"
            },
            {
                "fileMatch": ["^chart/Chart\\.yaml$"],
                "matchStrings": [
                    "- MyPackage:\\s*(?<currentValue>.+)",
                    "appVersion:[^\\S\\r\\n]+(?<currentValue>.+)"
                ],
                "extractVersionTemplate": "^v(?<version>.*)$",
                "depNameTemplate": "registry1.dso.mil/ironbank/opensource/mypackage/mypackage",
                "datasourceTemplate": "docker"
            },
            {
                "fileMatch": ["^chart/Chart\\.yaml$"],
                "matchStrings": [
                    "image:[^\\S\\r\\n]+(?<depName>.+):(?<currentValue>.+)"
                ],
                "datasourceTemplate": "docker"
            }
        ],
        "separateMajorMinor": false,
        "postUpdateOptions": ["helmUpdateSubChartArchives"]
    }
    ```
10. Documentation for the Package should be included. A "docs" directory would include all detailed documentation. Reference other Packages for examples.
    1. You should include a `DEVELOPMENT_MAINTENANCE.md` file in this directory. Outlined in this file should the following: 
        * How to update the package.
        * How to deploy the package in a test environment.
        * How to test the package.
        * A list of modifications that were made from the upstream chart.
            * There shouldn't be many modifications from the upstream chart. The goal is to use the upstream chart as much as possible.
            * The modifications will likely be kustomizations that will have to live in the umbrella chart.
        * A list of known issues.
11. Add the following markdown files to complete the Package. Reference other that Packages for examples of how to create them.
    ```shell
    CHANGELOG.md      <  standard history of changes made  
    CODEOWNERS        <  list of the code maintainers. Minimum of two people from separate organizations  
    CONTRIBUTING.md   <  instructions for how to contribute to the project  
    README.md         <  introduction and high level information  
    ```
12. Create a top-level tests directory and inside put a test-values.yaml file that includes any special values overrides that are needed for CI pipeline testing. Refer to other packages for examples. But this is specific to what is needed for your package.
    ```shell
    mkdir tests
    touch test-values.yaml
    ```
13. At a high level, a Package structure should look like this (below) when you are finished.
    ```plaintext
    packageRepo/
    ├── chart/
    │   ├── charts/
    │   │ └── upstream-chart-*.tgz
    │   ├── templates/
    │   │ └── bigbang/
    │   │     ├── networkpolicies/
    │   │     │ ├── egress-*.yaml
    │   │     │ └── ingress-*.yaml
    │   │     └── virtualservice.yaml
    │   ├── tests/
    │   │ ├── cypress/
    │   │ └── scripts/
    │   ├── Chart.yaml
    │   └── values.yaml
    ├── docs/
    │   ├── DEVELOPMENT_MAINTENANCE.md
    │   ├── documentation-file-1.md
    │   └── documentation-file-2.md
    ├── tests/
    │   └── test-values.yaml
    ├── CHANGELOG.md
    ├── CODEOWNERS
    ├── CONTRIBUTING.md
    ├── README.md
    └── renovate.json
    ```
14. Merging code should require approval from a minimum of two codeowners. To set up merge requests to work properly with CODEOWNERS approval, change these settings in your project:
    1. Under Settings → General → Merge Request Approvals, change "Any eligible user" "Approvals required" to 1. Also ensure that "Require new approvals when new commits are added to an MR" is checked.
    2. Under Settings → Repository → Protected Branches, add the main branch with "Developers + Maintainers" allowed to merge, "No one" allowed to push, and "Codeowner approval required" turned on.
    3. Under Settings → Repository → Default Branch, ensure that main is selected.
15. Development Testing Cycle: Test your Package chart by deploying with helm. Test frequently so you don't pile up multiple layers of errors. The goal is for Packages to be deployable independently of the bigbang chart. Most upstream helm charts come with internal services like a database that can be toggled on or off. If available use them for testing and CI pipelines. In some cases this is not an option. You can manually deploy required in-cluster services in order to complete your development testing.  Here is an example of an in-cluster postgres database.
    ```shell
    helm repo add bitnami https://charts.bitnami.com/bitnami
    helm install postgres bitnami/postgresql -n postgres --create-namespace --set postgresqlPostgresPassword=postgres --set postgresqlPassword=postgres
    # test it
    kubectl run postgresql-postgresql-client --rm --tty -i --restart='Never' --namespace default --image bitnami/postgresql --env="PGPASSWORD=postgres" --command -- psql --host postgres-postgresql-headless.postgres.svc.cluster.local -U postgres -d postgres -p 5432
    # Postgres commands
    \l             < list tables
    \du            < list users
    \q             < quit
    ```
    Here is an example of an in-cluster object storage service using MinIO (api compatible with AWS S3 storage)
    ```shell
    helm repo add minio https://helm.min.io/
    helm install minio minio/minio --set accessKey=myaccesskey --set secretKey=mysecretkey -n minio --create-namespace
    # test and configure it
    kubectl run minio-mc-client --rm --tty -i --restart='Never' --namespace default --image minio/mc --command -- bash
    # MinIo commands
    mc alias set minio http://minio.minio.svc.cluster.local:9000 myaccesskey mysecretkey      < set a connection alias
    mc mb minio/myBucket          < make a bucket
    mc ls minio                   < list the buckets
    ```
    Create a local directory on your workstation where you store your helm values override files. Don't make test changes in the Package values.yaml because they could accidentally be committed. The most convenient location is in a sibling directory next to the Package repo. Here is an example directory structure:
    ```plaintext
    ├── PackageRepo/
    └── overrides/
          └── override-values.yaml
    ```
    Here are the dev test steps you can iterate:
    ```shell
    # Test that the helm chart templates successfully and examine the output to insure expected results
    helm template <releasename> ./chart -n <namespace> -f ../overrides/override-values.yaml
    # Deploy with helm
    helm upgrade -i <releasename> ./chart -n <namespace> --create-namespace -f ../overrides/override-values.yaml
    # Conduct testing
    # Tear down
    helm delete <releasename> -n <namespace>
    # Manually delete the namespace to insure that everything is gone
    kubectl delete ns <namespace>
    ```
16. Wait to create a git tag release until integration testing with BigBang chart is completed. You will very likely discover more Package changes that are needed during BigBang integration. When you are confident that the Package code is complete, squash commits and rebase your development branch with the "main" branch.
    ```shell
    git rebase origin/main
    git reset $(git merge-base origin/main $(git rev-parse --abbrev-ref HEAD))
    git add -A
    git commit -m "feat: example conventional commit"
    git push --force
    ```
17. Then, create a merge request to branch "main."
18. After the merge create a git tag following the charter convention of {UpstreamChartVersion}-bb.{BigBangVersion}. The tag should exactly match the chart version in the Chart.yaml.
example: `1.2.3-bb.0`
19. Integrate the package using the [Package Integration Documents](package-integration/README.md).

## Private registry secret creation

In some instances you may wish to manually create a private-registry secret in the namespace or during a helm deployment. There are a couple of ways to do this:

1. The first way is to add the secret manually using kubectl. This method is useful for standalone package testing/development.
    ```shell
    kubectl create secret docker-registry private-registry --docker-server="https://registry1.dso.mil" --docker-username='Username' --docker-password="CLI secret" --docker-email=<your-email> --namespace=<package-namespace>
    ```
2. The second is to create a yaml file containing the secret and apply it during a helm install. This method is applicable when installing your new package as part of the Big Bang chart. In this example the file name is "reg-creds.yaml":

    Create the file with the secret contents:
    ```yaml
    registryCredentials:
    registry: registry1.dso.mil
    username: ""
    password: ""
    email: ""
    ```
    Then include a reference to your file during your helm install command by adding the below `-f` to your Big Bang install command:
    ```shell
    -f reg-creds.yaml
    ```

## Converting a Package from `kpt` to "passthrough"

In some cases, you may need to convert a Package that was initially developed using `kpt` to the "passthrough" chart pattern. This involves creating a new `Chart.yaml` file and restructuring the Package to use the upstream chart as a dependency. See the [upstream package integration documentation](package-integration/upstream.md) for more details. Follow these steps:
1. **Edit `Chart.yaml`** to define the upstream chart as a dependency. Remove unnecessary default templates and add the upstream chart under the `dependencies` section:
    ```yaml
    dependencies:
      - name: <upstream-chart-name>
        version: <upstream-version>
        repository: <upstream-repo-url>
        alias: upstream
    ```
2. **Run `helm dependency update`** to fetch the upstream chart and commit the resulting `.tgz` files in `chart/charts/`.
3. **Transfer customizations**: Move any custom values you previously used to override the upstream chart into the `upstream` key in `chart/values.yaml`. Only include new default overrides under the `upstream` key. Do not copy default values from the upstream chart.
4. **Update templates**: Move any custom Kubernetes manifests (e.g., network policies, VirtualService) into `chart/templates/bigbang/` as needed.
5. **Remove upstream templates and files**: Remove any templates that were part of the upstream chart and are now handled by the passthrough chart. Remove any unnecessary files that were part of the `kpt` structure.
5. **Test the new passthrough chart** by templating and deploying with Helm to ensure all overrides and dependencies work as expected.
6. **Update documentation** to reflect the new chart structure and usage.
7. **Update the Umbrella Chart**: If this Package is part of the Big Bang umbrella chart, update the umbrella chart's `values.yaml`. Ensure that the umbrella chart's values file reflects any necessary overrides for the new passthrough chart. Specifically consider adding a commented out section for the `upstream` block under the values for the passthrough chart to show some common configuration options.
    ```yaml
        values: {}
        # EXAMPLE: Use Tetrate's Enterprise FIPS compatible Istio image
        # upstream:
        #   global:
        #     hub: registry1.dso.mil/ironbank/tetrate/istio
    ```
