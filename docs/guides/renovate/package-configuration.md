# Renovate Configuration for Big Bang Customer Template

## Package Configuration

### Example Package Configuration

> The following example is for a user fork of the [customer template](https://repo1.dso.mil/big-bang/customers/template).

The first 10 lines set up the basics of what a Renovate ticket is expected to look like when created.  Package Rules is set up to use git-tags.  Regex Managers are detailed below.
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

#### RegEx Managers
This is where regex-based rules for updating dependencies are defined. This is where the majority of the work is done for Renovate. 

In this example the version of Big Bang tracked by the base/kustomization.yaml is the target of renovate. 
The regex targets `- git::https://repo1.dso.mil/platform-one/big-bang/bigbang.git//base?ref=1.41.0` setting `1.41.0` as a capture group.

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
> The same concept can be applied to dev/kustomization.yaml or the kustomization for any folder for a specific environment


Targeting packages requires a more complex regex statement.  In this example we are asking renovate to update the version number of `git.tag` where `git.repository` matches the `depName`

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
## Package Configuration Options
The following options are commonly used to configure the options of Renovate:

### regexManagers
Several `regexManagers` are defined in the package configuration example, each with a specific `fileMatch` path and `matchStrings` regex. It can accept an array of objects. Below is some of the common properties of those objects.

#### File Match

The `fileMatch` array is a list of files that you want to parse.  It uses a regular expression match on the files starting in the repository base directory.  For example `["^chart/values\\.yaml$"]` will match the `chart/values.yaml` file.

#### Match Strings

`matchString` is used to identify the current version, data source type, dependency name or current digest in a file.   You must use special capture groups in regex to identify these items, or create a template for Renovate to understand.  The following are required to be captured:

- `<currentValue>`: This is the current version or tag of the dependency (e.g. v1.2.3)
- `<datasource>`: This is the type of the dependency.  For Big Bang packages you will want to use `git-tags`.
- `<depName>`: This is the name of the dependency and is uses as the repository for the dependency when looking it up in the registry

You can optionally capture `<currentDigest>` as the SHA256 digest for an image if you want renovate to replace this value.

To capture a group, you simply use [regex named groups](https://www.regular-expressions.info/refext.html).

See [Renovate Configuration](https://docs.renovatebot.com/configuration-options/#regexmanagers) for more details.

### Dashboard options
#### dependencyDashboard
When the Dependency Dashboard is enabled, Renovate will create a new issue in the configured repository. This issue acts as a "dashboard" where you can get an overview of the status of all updates. It can accept a boolean value.

#### dependencyDashboardHeader
This key sets a header for the dependency dashboard which lists tasks to be completed by the user in the form of the issue description on Gitlab. The header will appear at the top of the dependency dashboard. In the given example, the header contains a checklist for reviewing the BB release notes/changelog. It can accept a string.

#### dependencyDashboardTitle
This key is used to set the title for the dependency dashboard. In the example, it is set as "Renovate: Upgrade Big Bang". It can accept a string.

> See [Renovate Configuration](https://docs.renovatebot.com/configuration-options/#dependencydashboard) for more info.


### packageRules
This key provides an array of rules that define how packages are matched and grouped. In the example, any matching package with the datasource `git-tags` will be grouped under the name `Big Bang`. It can accept an array of objects see [Renovate Package Rules Docs](https://docs.renovatebot.com/configuration-options/#packagerules) for more info.

## Additional Package Configuration Options

### baseBranches
This key is used to specify the base branches for Renovate to compare against. It can accept an array of strings. In the example yaml, Renovate will compare against the `main` branch.

### configWarningReuseIssue
This key specifies whether to reuse an existing pull request for updates, and whether to warn if an existing pull request cannot be re-used. It can accept a boolean value.

### draftPR
This key specifies whether the generated pull requests should be marked as drafts. It can accept a boolean value.

### enabledManagers
This key specifies which dependency managers to enable. In the example, Renovate will use `regex`.  It can accept an array of strings.

### ignorePaths
This key lists the file paths for Renovate to ignore when checking dependencies. It can accept an array of strings.

### labels
This key assigns labels to the created pull requests. In the example a `renovate` label is applied. It can accept an array of strings.

### commitMessagePrefix
This key sets a prefix that will be added to commit messages. It can accept a string.

### separateMajorMinor
This key specifies whether to separate major/minor updates into separate pull requests. It can accept a boolean value.

### ignoreDeps 
The configuration field allows you to define a list of dependency names to be ignored by Renovate. Currently it supports only "exact match" dependency names and not any patterns. It can accept an array of strings.


In conclusion, the `renovate.json` file allows us to configure the Renovate bot to keep our Helm chart repository up-to-date with the latest dependencies, by using various settings to suit our needs.
