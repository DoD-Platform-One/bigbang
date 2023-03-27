# List Of Big Bang Applications That Are Using Kyverno

## Gitlab Runner
In order for Gitlab Runner auto registration to work the runner must be delpoyed in the "gitlab" namespace or have a copy of the 'gitlab-runner-secret' in its separate namespace. The Big Bang helm chart deploys gitlab Runner in a separate namespace. Gitlab Runner uses Kyverno to copy the gitlab runner secret. There are alternate options if Kyverno is not wanted.
1. By default Gitlab Runner uses Kyverno to support auto registration
2. The runner token can be added to value overrides.
3. The gitlab-runner-secret can be manually copied to the gitlab-runner namespace. 
