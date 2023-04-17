---
revision_date: Last edited April 14, 2023
tags:
  - blog
---

# Breaking Changes in Big Bang 2.0

This is part 2 in a series of Big Bang 2.0 blog posts. If you haven't already, read through part 1 [here](./big-bang-2-0.md) which provides some backstory on why the team thought 2.0 was necessary and what changes are included. This post will dive more into the specific breaking changes and how these will affect you as a user.

## Values Key Changes

As mentioned in the first post, a number of values keys will be changing in order to standardize naming. Some of these keys already changed in BB 1.x, but had backwards compatibility previously. In 2.0 usage of the new keys will be required. When evaluating the upgrade for your own deployment, these are the specific key translations/changes you will need to make if you were using them in 1.x:
- `istiooperator` -> `istioOperator`
- `kyvernopolicies` -> `kyvernoPolicies`
- `kyvernoreporter` -> `kyvernoReporter`
- `logging` -> `elasticsearchKibana`
- `eckoperator` -> `eckOperator`
- `mattermostoperator` -> `mattermostOperator`
- `nexus` -> `nexusRepositoryManager`

Note that your upgrade to 2.0 will fail if you do not modify your values as seen above. Big Bang is now maintaining a [values schema](https://helm.sh/docs/topics/charts/#schema-files) to enforce strict adherence to the allowed/required keys within Big Bang. For reference Big Bang's values schema is located [here](https://repo1.dso.mil/big-bang/bigbang/-/blob/master/chart/values.schema.json). You can also leverage the script in `/scripts/values-translate-2-0.sh <values file path>` to perform these translations for you (note that this is a relatively simple script and may not work for your use case).

## Namespace Changes

Connected with name standardization as well as package isolation, several packages will be moving to different namespaces in 2.0. These packages are all "state-less" with no persistent storage, so there is no requirement to backup anything from the previous version before upgrading. Specific packages moving:
- Fluentbit: Moving from `logging` namespace to `fluentbit` namespace
- Promtail: Moving from `logging` namespace to `promtail` namespace
- Gitlab Runner: Moving from `gitlab` namespace to `gitlab-runner` namespace

Also note that Fluentbit (if connecting to Elasticsearch) and Gitlab Runner now have a dependency on Kyverno if relying on the "auto" authentication/token setup. In both cases Kyverno is leveraged to copy secrets between namespaces. This does not mean that you need to use `kyvernoPolicies` as well - you could continue to use Gatekeeper for policy enforcement and deploy Kyverno exclusively for this use case (although we do encourage Kyverno adoption). If you do not want to deploy Kyverno there are several alternative options listed below.

Gitlab Runner Alternatives:
- Get a token from your Gitlab instance and add it via values (`addons.gitlabRunner.values.runnerRegistrationToken`)
- Manually copy the secret from the `gitlab` namespace to the `gitlab-runner` namespace

Fluentbit Alternatives:
- Leverage `fluentbit.values.additionalOutputs.elasticsearch` and `fluentbit.values.additionalOutputs.disableDefault`=`true` to setup a connection with Elastic, rather than using the auto-connection
- Manually copy secrets from the `logging` namespace to the `fluentbit` namespace. You will need to copy both the certs secret (`logging-ek-es-http-certs-public`) as well as the auth secret (`logging-ek-es-elastic-user`)

Beyond the new requirement for Kyverno, changes to a namespace can affect labels and pod/svc names in some cases, so be aware of this if you are leveraging these packages in connection with anything on top of Big Bang. All components within Big Bang have been adjusted to account for these changes already.

## Default Package Changes

As mentioned in the previous post - Big Bang will deploy by default with a new opensource set of core packages in 2.0. If you are using any of the below packages and want to continue using them in 2.0, make note of the changes you will need to perform:
- Twistlock: Set `twistlock.enabled` to true; set `neuvector.enabled` to false
- Fluentbit: Set `fluentbit.enabled` to true; set `promtail.enabled` to false
- Elasticsearch/Kibana: Set `elasticsearchKibana.enabled` to true; set `loki.enabled` to false
- Gatekeeper: Set `gatekeeper.enabled` and `clusterAuditor.enabled` to true; set `kyverno.enabled`, `kyvernoReporter.enabled`, and `kyvernoPolicies.enabled` to false
- Jaeger: Set `jaeger.enabled` to true; set `tempo.enabled` to false

Provided you make the above adjustments you will be able to deploy with the same set of packages you were using in 1.x. Example values for each of the above are provided in a reference file [here](../docs/assets/configs/example/core-packages-1-x.yaml).

## HelmRelease / GitRepository Name Changes

Beyond the above mentioned name changes you may also notice some `HelmRelease` and `GitRepository` names change in 2.0. For the most part these should have no effect on anything directly in Big Bang, but they are important to be aware of if you maintain automation/applications on top of what is provided by Big Bang. Changes to the `HelmRelease` name specifically could affect pod/svc names and labels, so these are enumerated below:
- Fluentbit: `fluent-bit` -> `fluentbit`
- Kyverno Policies: `kyvernopolicies` -> `kyverno-policies`
- Kyverno Reporter: `kyvernoreporter` -> `kyverno-reporter`

## Is that it?

That's it! This blog post lays out all of the breaking changes in 2.0, and hopefully also provides you with a clear path forward for what you need to change before upgrading.

Continue reading about Big Bang 2.0 in [part 3 of this series](./2-0-new-features.md), which is focused specifically on the new features included in 2.0.
