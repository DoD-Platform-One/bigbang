
# Fortify
## Overview
Micro Focus Fortify Software Security Center(SSC) or simply "**[Fortify](https://www.microfocus.com/en-us/cyberres/application-security/software-security-center)"**, is a centralized management and analysis facility for application data gathered and processed using Fortify analysis products and tools(**Fortify Static Code Analyzer, Fortify WebInspect, and Audit WorkBench**, etc), providing visibility to an organization's entire application security program to help resolve security vulnerabilities across the software portfolio. It is a platform where users can review, audit, prioritize, and manage remediation efforts, track software security testing activities, and measure improvements via the management dashboard and reports to optimize static and dynamic application security test results. Fortify SSC helps to provide an accurate picture and scope of the application security posture across the enterprises.
### Architecture
- [Fortify Architecture](https://www.microfocus.com/documentation/fortify-software-security-center/2310/SSC_Help_23.1.0/index.htm#SSC_UG/A_Install_Env.htm?TocPath=Part%2520I%253A%2520Deploying%2520Fortify%2520Software%2520Security%2520Center%257CPreparing%2520for%2520%2520Fortify%2520Software%2520Security%2520Center%2520Deployment%257C_____2)

The following table provides descriptions of the required and optional Fortify Software Security Center installation components in the illustration.

| Component | Description |
| --- | --- |
| Fortify SSC Server | Fortify Software Security Center is delivered as a Web Archive (WAR) file run by Tomcat Server or as a Helm chart for Kubernetes deployment. |
| SSC database |Third‑party database that Fortify Software Security Center requires to store user and artifact data. Before you put Fortify Software Security Center into production, you must install a supported third‑party database. |
| Third‑party LDAP authentication server | (Optional) You can configure Fortify Software Security Center to use LDAP authentication. |
| Defect‑tracking server |(Optional) You can configure Fortify Software Security Center to enable bug submission directly to Bugzilla, Jira, ALM, Azure DevOps Server, or a customized bug‑tracking system. For information about how to create a customized bug-tracking system, see [Authoring Bug Tracker Plugins](https://www.microfocus.com/documentation/fortify-software-security-center/2310/SSC_Help_23.1.0/Content/SSC_UG/Author_Plugins.htm). |
| Third‑party email server |(Optional) You can configure Fortify Software Security Center to use an external SMTP email server to send alerts to application collaborators. |
| Fortify Static Code Analyzer analysis agent |(Optional) Fortify Static Code Analyzer scans source code and identifies issues. |
| Audit Workbench and IDE plugins |Audit Workbench and Fortify IDE plugins can be used as alternative source‑code auditing tools. |
| Jenkins\ Azure DevOps\ Bamboo |Use these plugins to scan source code (using Fortify Static Code Analyzer) and upload scan results. |
| Fortify ScanCentral SAST |(Optional) Fortify Static Code Analyzer users can use ScanCentral SAST to offload processor-intensive code analysis tasks from their build machines to a group of machines (sensors) provided for this purpose. |
| Fortify ScanCentral DAST |(Optional) A dynamic application security testing tool that you can use to configure and run dynamic scans of your web applications from Fortify Software Security Center. |
| Fortify WebInspect |(Optional) Analysis agent that connects with Fortify WebInspect agents to retrieve potential dynamic issues. |
| Fortify Security Content update server |Used to acquire and update Security Content. |

**Important! **Fortify does not support load balancing across multiple Fortify Software Security Center servers.

## Big Bang Touchpoints

### KyvernoPolicies

When deploying to k3d, the `validationFailureAction` for the `restrict-host-path-mount-pv` policy should be set to `audit`. This can be done by modifying `chart/values.yaml` file or passing an override file with the values set as seen below. This is for development purposes only: production should use the default setting of `enforce`.

```yaml
kyvernoPolicies:
  values:
    policies: 
      restrict-host-path-mount-pv:
        validationFailureAction: audit
```

## Licensing
By default, Big Bang will deploy Fortify without a license. if you have a license, you can add your license via the values file as shown below:

```yaml
addons:
  fortify:
    fortify_license: |
      <license>
```

**Note**: This should be added via encrypted values to protect the license
