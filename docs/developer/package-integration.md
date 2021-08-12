# Integrate a Package with Bigbang Helm Chart

[[_TOC_]]

1. Make a branch from the BigBang chart repository master branch. You can automatically create a branch from the Repo1 Gitlab issue. Or, in some cases you might manually create the branch. You should name the branch with your issue number. If your issue number is 9999 then your branch name can be "9999-my-description". It is best practice to make branch names short and simple.

1. Create a directory for your package at `chart/templates/<your-package-name>`

1. Inside this folder will be various helm template files. The rule is one document per yaml file. You can copy one of the other package folders and tweak the code for your package. Gitlab is a good example to reference because it is one of the more complicated Packages. Note that the Istio VirtualService comes from the Package and is not created in the BigBang chart. The purpose of these helm template files is to create an easy-to-use spec for deploying supported applications. Reasonable and safe defaults are provided and any needed secrets are auto-created. We accept the trade off of easy deployment for complicated template code. More details are in the following steps.

   ```shell
   gitrepository.yaml  # Flux GitRepository. Is configured by BigBang chart values.
   helmrelease.yaml    # Flux HelmRelease. Is configured by BigBang chart values.
   namespace.yaml      # Contains the namespace and any needed secrets
   secret-*.yaml       # various template files that create any needed k8s secrets
   values.yaml         # Implements all the BigBang customizations of the package and passthrough for values.
   ```

1. More details about values.yaml:  Code reasonable and safe defaults but prioritize any user defined passthrough values wherever this makes sense. Avoid duplicating tags that are provided in the upstream chart values. Instead code reasonable defaults in the values.yaml template. The following is an example from Gitlab that handles SSO config. The code uses Package chart passthrough values if the user has entered them but otherwise defaults to the BigBang chart values or the Helm default values. Notice that the secret is not handled this way. The assumption is that if the user has enabled the BigBang SSO feature the secret will be auto created. In this case the user should not be overriding the secret. If the user wants to create their own secret they should not be enabling the BigBang SSO feature.  

   Note that helm does not handle any missing parent tags in the yaml tree. The 'if' statement and 'default' method throw 'nil' errors when parent tags are missing. The work-around is to inspect each level of the tree and assign an empty 'dict' if the value does not exist. Then you will be able to use 'hasKey' in your 'if' statements as shown below in this example from Gitlab. Having described all this, you should understand that coding conditional values is optional. The passthrough values will take priority regardless. But the overridden values will not show up in the deployed flux HelmRelease object if you don't code the conditional values. The value overrides will be obscured in the Package values secret. The only way to confirm that the overrides have been applied is to use `helm get values <releasename> -n bigbang` command on the deployed helm release. When the passthrough values show up in the HelmRelease object the Package configuration is much easier to see and verify. Use your own judgement on when to code conditional values.

   ```yaml
   global: 
     {{- if or .Values.addons.gitlab.sso.enabled .Values.addons.gitlab.objectStorage.endpoint }}
     appConfig:
     {{- end }}

       {{- if .Values.addons.gitlab.sso.enabled }}
       omniauth:
         enabled: true
         {{- $global := .Values.addons.gitlab.values.global | default dict }}
         {{- $appConfig := $global.appConfig | default dict }}
         {{- $omniauth := $appConfig.omniauth | default dict }}
         {{- if hasKey $omniauth "allowSingleSignOn" }}
         allowSingleSignOn: {{ .Values.addons.gitlab.values.global.appConfig.omniauth.allowSingleSignOn }}
         {{- else }}
         allowSingleSignOn: ['openid_connect']
         {{- end }}
         {{- if hasKey $omniauth "blockAutoCreatedUsers" }}
         blockAutoCreatedUsers: {{ .Values.addons.gitlab.values.global.appConfig.omniauth.blockAutoCreatedUsers }}
         {{- else }}
         blockAutoCreatedUsers: false
         {{- end }}

         providers:
           - secret: gitlab-sso-provider
             key: gitlab-sso.json
     {{- end }}

   ```

1. More details about secret-*.yaml: The secret template is where the code for secrets go. Typically you will see secrets for imagePullSecret, sso, database, and possibly object storage. These secrets are a BigBang chart enhancement. They are created conditionally based on what the user enables in the config.

1. Edit the chart/templates/values.yaml.  Add your Package to the list of Packages.  Just copy one of the others and change the name. This supports adding chart values from a secret. Pay attention to whether this is a core Package or an add-on package, the toYaml values are different for add-ons. This template allows a Package to add chart values that need to be encrypted in a secret.

1. Edit the `chart/values.yaml`.  Add your Package to the bottom of the core section if a core package or addons section if an add-on. You can copy from one of the other packages and modify appropriately.  Some possible tags underneath your package are [enabled, git, sso, database, objectstorage].  Avoid duplicating value tags from the upstream chart in the BigBang chart. The goal is not to cover every edge case. Instead code reasonable defaults in the helmrelease template and allow customer to override values in addons.`<packageName>.values`

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

1. Edit tests/ci/k3d/values.yaml. These are the settings that the CI pipeline uses to run a deployment test.  Set your Package to be enabled and add any other necessary values. Where possible reduce the number of replicas to a minimum to reduce strain on the CI infrastructure. When you commit your code the pipeline will run. You can view the pipeline in the Repo1 Gitlab console. Fix any errors in the pipeline output. The pipeline automatically runs a "smoke" test. It deploys bigbang on a k3d cluster using the test values file.

1. Add your packages name to the ORDERED_HELMRELEASES list in scripts/deploy/02_wait_for_helmreleases.sh.

1. Verify your Package works when deployed through bigbang. While testing you should use a git branch instead of tag, (i.e. replace tag: "1.2.3-bb.0" with branch: "main").  After you have tested BigBang integration, tag the commit in your Package following the convention of {UpstreamChartVersion}-bb.{BigBangVersion} – example 1.2.3-bb.0.

1. Make sure to change the chart/values.yaml file to point to the tag rather than your branch (i.e. tag: "1.2.3-bb.0" in place of branch: "bb-9999").

1. When you are done developing the BigBang chart features for your Package make a merge request in "Draft" status and add a label corresponding to your package name (must match the name in `values.yaml`). Also add any labels for dependencies of the package that are NOT core apps. The merge request will start a pipeline and use the labels to determine which addons to deploy. Fix any errors that appear in the pipeline. When the pipeline has pass and the MR is ready take it out of "Draft" and add the `status::review` label. Address any issues raised in the merge request comments.

## BigBang Development and Testing Cycle

There are two ways to test BigBang, imperative or GitOps with Flux.  Your initial development can start with imperative testing.  But you should finish with GitOps to make sure that your code works with Flux.

### Imperative

You can manually deploy bigbang with helm command line. With this method you can test local code changes without committing to a repository. Here are the steps that you can iterate with "code a little, test a little".  From the root of your local bigbang repo:

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
hack/remove-ns-finalizer.sh istio-system
```

### GitOps with Flux

You can deploy your development code the same way a customer would deploy using GitOps. You must commit any code changes to your development branches because this is how GitOps works. There is a [customer template repository](https://repo1.dso.mil/platform-one/big-bang/customers/template) that has an example template for how to deploy using BigBang. You can create a branch from one of the other developer's branch or start clean from the master branch. Make the necessary modifications as explained in the README.md. The setup information is not repeated here. This is a public repo so DO NOT commit unencrypted secrets. Before committing code it is a good idea to manually run `helm template` and a `helm install` with dry run.  This will reveal many errors before you make a commit. Here are the steps you can iterate:
  
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
hack/remove-ns-finalizer.sh istio-system

# If you have pushed code changes before the tear down, occasionally the bigbang deployments are not terminated because Flux has not had enough time to reconcile the helmreleases

# Re-deploy bigbang
kubectl apply -f dev/bigbang.yaml
# Run the sync script.
hack/sync.sh
# Tear down
kubectl delete -f dev/bigbang.yaml
hack/remove-ns-finalizer.sh istio-system
```
