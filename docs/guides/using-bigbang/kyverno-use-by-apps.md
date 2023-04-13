# List Of Big Bang Applications That Are Using Kyverno

## Gitlab Runner
In order for Gitlab Runner auto registration to work the runner must be deployed in the `gitlab` namespace or have a copy of the 'gitlab-runner-secret' in its separate namespace. The Big Bang helm chart deploys Gitlab Runner in a separate namespace. Gitlab Runner uses Kyverno to copy the gitlab runner secret. There are alternate options if Kyverno is not wanted.
1. By default Gitlab Runner uses Kyverno to support auto registration
2. The runner token can be added to value overrides.
3. The gitlab-runner-secret can be manually copied to the `gitlab-runner` namespace. 

## Fluentbit
In order for Fluentbit to automatically have a connection setup for for Elastic the Elastic root password and certificate secrets must be copied from the `logging` namespace to `fluentbit`. Kyverno is leveraged to copy these automatically. There are alternatives if using Kyverno is not desired:
1. By default Kyverno is used for auto-connection.
2. `fluentbit.values.additionalOutputs.elasticsearch` could be used to setup a connection with Elastic rather than the auto-connection.
3. Secrets can be manually copied to the `fluentbit` namespace.
