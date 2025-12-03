# Renovate

[[_TOC_]]

## Deployment of Renovate

Follow the [Extra Package Deployment Guide](../../installation/environments/extra-package-deployment.md)

### Example Deployment Values
``` yaml
packages:
  renovate:
    enabled: true
    git:
      repo: https://repo1.dso.mil/big-bang/product/packages/renovate.git
      tag: 32.38.0-bb.1
    values:
      networkPolicies:
        enabled: "{{ $.Values.networkPolicies.enabled }}"
      istio:
        enabled: "{{ $.Values.istiod.enabled }}"
      cronjob:
        schedule: '0 1 * * *'
      renovate:
        config: |
        {
            "platform": "gitlab",
            "endpoint": "https://gitlab.example.com/api/v4",
            "token": "your-gitlab-renovate-user-token",
            "autodiscover": "false",
            "dryRun": true,
            "printConfig": true,
            "repositories": ["username/repo", "orgname/repo"]
        }
```

### Config
The configuration sets up a self-hosted instance of Renovate that connects with a platform. In the example, we connect to GitLab using the GitLab API v4 at a specified URL.

#### Auth
It is recommended to use a repository-scoped auth token with developer access for least privilege.

#### Repositories
The repositories key in this self-hosted renovate configuration specifies which repositories should be included in the update checks performed by renovate Accepts an array of strings or objects.

See [Self Hosted Configuration](https://docs.renovatebot.com/self-hosted-configuration/#self-hosted-configuration-options) for more details

### Cron Job
Refer to the [Scheduling Renovate Guide](#handling-scheduling-in-the-chart).

### Individual Package Configuration
The configuration file for Renovate is called `renovate.json` and is located in each project's root directory. See [Package Configuration](#package-configuration)

## Handling Scheduling in the Chart

To handle scheduling in the chart for a Renovate configuration, you can use a Kubernetes CronJob object, which allows you to schedule jobs to run at specific intervals. To configure the scheduling, you will need to modify the schedule field in the cronjob section of the values.yaml file.

The schedule option allows you to define times of week or month for Renovate updates. Running Renovate around the clock can be too "noisy" for some projects. To reduce the noise, you can use the schedule config option to limit the time frame in which Renovate will perform actions on your repository. You can use the standard Cron syntax and Later syntax to define your schedule.

The default value for schedule is `0 1 * * *` for at `01:00 everyday`.

The easiest way to define a schedule is to use a preset if one of them fits your requirements. Refer to the schedule presets for details and feel free to request a new one in the source repository if you think others would also benefit from it.

### Additional Examples

Otherwise, here are some text schedules that are known to work:
```
every weekend
before 5:00am
after 10pm and before 5:00am
after 10pm and before 5am every weekday
on friday and saturday
every 3 months on the first day of the month
* 0 2 * *
```
##### Cron Syntax
```R
*    *    *    *    *
-    -    -    -    -
|    |    |    |    |
|    |    |    |    +----- day of the week (0 - 6) (Sunday=0)
|    |    |    +---------- month (1 - 12)
|    |    +--------------- day of the month (1 - 31)
|    +-------------------- hour (0 - 23)
+------------------------- minute (0 - 59)
```

> For example, to run the Renovate job every day at 1:00 AM, you would set the schedule field to `0 1 * * *`.

### Other Options

You can also configure other options in the CronJob section, including: suspend to temporarily disable the job, concurrencyPolicy to control how multiple instances of the job are run, and startingDeadlineSeconds to specify the maximum amount of time to wait for a job to start before considering it failed.

* `suspend`: If set to `true`, the job will be suspended and will not be executed.
* `concurrencyPolicy`: This determines how the job handles concurrent executions. Valid values are `Allow`, `Forbid`, and `Replace`.
* `failedJobsHistoryLimit`: This defines the number of failed jobs that will be kept in history.
* `successfulJobsHistoryLimit`: This defines the number of successful jobs that will be kept in history.
* `jobRestartPolicy`: This determines how the job will be restarted when it fails. Valid values are `Never` and `OnFailure`.
* `jobBackoffLimit`: This defines the maximum number of retries that can be attempted before the job is considered failed.
* `startingDeadlineSeconds`: This defines the deadline for starting the job. If the job is not started before the deadline, it will be cancelled.

Once you have configured the schedule in the values.yaml file, you can deploy the Renovate chart using `helm install` or `helm upgrade` commands. The Renovate job will then run according to the specified schedule.

### Example Yaml
```yaml
packages:
  renovate:
    enabled: true
    git:
      repo: https://repo1.dso.mil/big-bang/product/packages/renovate.git
      tag: 32.38.0-bb.1
    values:
      cronjob:
        # At 01:00 every day
        schedule: '0 1 * * *'
        # -- If it is set to true, all subsequent executions are suspended. This setting does not apply to already started executions.
        suspend: false
        annotations: {}
        labels: {}
        concurrencyPolicy: ''
        failedJobsHistoryLimit: ''
        successfulJobsHistoryLimit: ''
        jobRestartPolicy: Never
        jobBackoffLimit: ''
        startingDeadlineSeconds: ''

  ``` 

## Renovate Configuration for Big Bang Customer Template

### Package Configuration

#### Example Package Configuration

> The following example is for a user fork of the [customer template](https://repo1.dso.mil/big-bang/customers/template).

The first ten lines set up the basics of what a Renovate ticket is expected to look like when created. Package Rules is set up to use git-tags. Regex Managers are detailed below.
```json
{
    "baseBranches": ["main"],
    "configWarningReuseIssue": false,
    "dependencyDashboard": true,
    "dependencyDashboardHeader": "- [ ] Review Big Bang changelog/release notes.",
    "dependencyDashboardTitle": "Renovate: Upgrade Big Bang",
    "draftPR": true,
    "enabledManagers": ["regex"],
    "labels": ["renovate"],
    "commitMessagePrefix": "",
    "separateMajorMinor": false,
    "packageRules": [
          {
            "groupName": "Big Bang",
            "matchDatasources": ["git-tags"]
          }
        ],
    "regexManagers": [
        {
            "fileMatch": ["^base/kustomization\\.yaml$"],
            "matchStrings": [
              ".+?ref=+(?<currentValue>.+)"
            ],
            "depNameTemplate": "https://repo1.dso.mil/big-bang/bigbang.git",
            "datasourceTemplate": "git-tags",
            "versioningTemplate": "regex:^(?<major>\\d+)\\.(?<minor>\\d+)\\.(?<patch>\\d+)$"
        },
        {
            "fileMatch": ["^dev/kustomization\\.yaml$"],
            "matchStrings": [
              "tag:\\s+\"(?<currentValue>.+)\""
            ],
            "depNameTemplate": "https://repo1.dso.mil/big-bang/bigbang.git",
            "datasourceTemplate": "git-tags",
            "versioningTemplate": "regex:^(?<major>\\d+)\\.(?<minor>\\d+)\\.(?<patch>\\d+)$"
        },
        {
            "fileMatch": ["^dev/configmap\\.yaml$"],
            "matchStrings": [
              "git:\\s+repo:\\s+(?<depName>.+)\\s+tag:\\s+\"(?<currentValue>.+)\""
            ],
            "datasourceTemplate": "git-tags",
            "versioningTemplate": "regex:^(?<major>\\d+)\\.(?<minor>\\d+)\\.(?<patch>\\d+)-bb\\.(?<build>\\d+)$"
        }
    ],
}
```

##### RegEx Managers
This is where regex-based rules for updating dependencies are defined. This is where the majority of the work is done for Renovate. 

In this example, the version of Big Bang tracked by the base/kustomization.yaml is the target of renovate. 
The regex targets `- git::https://repo1.dso.mil/big-bang/bigbang.git//base?ref=1.41.0` setting `1.41.0` as a capture group.

```json
  {
      "fileMatch": ["^base/kustomization\\.yaml$"],
      "matchStrings": [
        ".+?ref=+(?<currentValue>.+)"
      ],
      "depNameTemplate": "https://repo1.dso.mil/big-bang/bigbang.git",
      "datasourceTemplate": "git-tags",
      "versioningTemplate": "regex:^(?<major>\\d+)\\.(?<minor>\\d+)\\.(?<patch>\\d+)$"
  }
```
> The same concept can be applied to dev/kustomization.yaml or the kustomization for any folder for a specific environment.


Targeting packages requires a more complex regex statement.  In this example, we are asking renovate to update the version number of `git.tag` where `git.repository` matches the `depName`

```json
    {
      "fileMatch": ["^dev/configmap\\.yaml$"],
      "matchStrings": [
        "git:\\s+repo:\\s+(?<depName>.+)\\s+tag:\\s+\"(?<currentValue>.+)\""
      ],
      "depNameTemplate": "https://repo1.dso.mil/big-bang/product/packages/kyverno.git",
      "datasourceTemplate": "git-tags",
      "versioningTemplate": "regex:^(?<major>\\d+)\\.(?<minor>\\d+)\\.(?<patch>\\d+)-bb\\.(?<build>\\d+)$"
   }
```

```yaml
kyverno:
  git:
    repo: https://repo1.dso.mil/big-bang/product/packages/kyverno.git
    tag: "2.6.5-bb.2"
  values:
    replicaCount: 1
```
### Package Configuration Options
The options that are commonly used to configure the options of Renovate include the following: regexManagers, Dashboard options, and packageRules.

#### regexManagers
Several `regexManagers` are defined in the package configuration example, each with a specific `fileMatch` path and `matchStrings` regex. It can accept an array of objects. Provided below are several of the common properties of those objects.

##### File Match

The `fileMatch` array is a list of files that you want to parse.  It uses a regular expression match on the files starting in the repository base directory.  For example `["^chart/values\\.yaml$"]` will match the `chart/values.yaml` file.

##### Match Strings

`matchString` is used to identify the current version, data source type, dependency name or current digest in a file. You must use special capture groups in regex to identify these items, or create a template for Renovate to understand. The following are required to be captured:

- `<currentValue>`: This is the current version or tag of the dependency (e.g. v1.2.3).
- `<datasource>`: This is the type of the dependency.  For Big Bang packages you will want to use `git-tags`.
- `<depName>`: This is the name of the dependency and is uses as the repository for the dependency when looking it up in the registry.

You can optionally capture `<currentDigest>` as the SHA256 digest for an image if you want renovate to replace this value.

To capture a group, you simply use [regex named groups](https://www.regular-expressions.info/refext.html).

See [Renovate Configuration](https://docs.renovatebot.com/configuration-options/#regexmanagers) for more details.

#### Dashboard Options

##### dependencyDashboard
When the dependencyDashboard is enabled, Renovate will create a new issue in the configured repository. This issue acts as a "dashboard" where you can get an overview of the status of all updates. It can accept a boolean value.

##### dependencyDashboardHeader
This key sets a header for the dependencyDashboard which lists tasks to be completed by the user in the form of the issue description on Gitlab. The header will appear at the top of the dependencyDashboard. In the given example, the header contains a checklist for reviewing the BB release notes/changelog. It can accept a string.

##### dependencyDashboardTitle
This key is used to set the title for the dependencyDashboard. In the example, it is set as "Renovate: Upgrade Big Bang". It can accept a string.

> Refer to [Renovate Configuration](https://docs.renovatebot.com/configuration-options/#dependencydashboard) for more information.

#### packageRules
This key provides an array of rules that define how packages are matched and grouped. In the example, any matching package with the datasource `git-tags` will be grouped under the name `Big Bang`. It can accept an array of objects see [Renovate packageRules Docs](https://docs.renovatebot.com/configuration-options/#packagerules) for more info.

### Additional Package Configuration Options

#### baseBranches
This key is used to specify the base branches for Renovate to compare against. It can accept an array of strings. In the example yaml, Renovate will compare against the `main` branch.

#### configWarningReuseIssue
This key specifies whether to reuse an existing pull request for updates, and whether to warn if an existing pull request cannot be re-used. It can accept a boolean value.

#### draftPR
This key specifies whether the generated pull requests should be marked as drafts. It can accept a boolean value.

#### enabledManagers
This key specifies which dependency managers to enable. In the example, Renovate will use `regex`.  It can accept an array of strings.

#### ignorePaths
This key lists the file paths for Renovate to ignore when checking dependencies. It can accept an array of strings.

#### labels
This key assigns labels to the created pull requests. In the example a `renovate` label is applied. It can accept an array of strings.

#### commitMessagePrefix
This key sets a prefix that will be added to commit messages. It can accept a string.

#### separateMajorMinor
This key specifies whether to separate major/minor updates into separate pull requests. It can accept a boolean value.

#### ignoreDeps 
The configuration field allows you to define a list of dependency names to be ignored by Renovate. Currently, it supports only "exact match" dependency names and not any patterns. It can accept an array of strings.

In conclusion, the `renovate.json` file allows us to configure the Renovate bot to keep our Helm chart repository up-to-date with the latest dependencies, by using various settings to suit our needs.
