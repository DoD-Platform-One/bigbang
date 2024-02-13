# Holocron

## Overview
Holocron is a software delivery metrics tracker and aggregator. It is designed to provide key insights into potential pain points for software delivery teams and help facilitate more efficient development. Holocron is an opinionated tool displaying goals for work in progress, continuous integration, and keeping piplines, branches, and merge requests from becoming stale. It also tracks how much effort is spent on different types of work, how often bugs are introduced, and how quickly tickets are resolved. It is an open-source project developed in-house at Platform One.

### Architecture

| Component | Description |
| --- | --- |
| Holocron Dashboard | Frontend allowing communication with the API to configure teams, value streams, and organizations and view their collected metrics. |
| Holocron API | Backend server connecting to the database, receives requests from the frontend and can potentially be integrated with a custom UI solution. |
| Postgresql Database | Holocron requires a Postgresql database for persistence. |
| SSO | (Optional) Holocron can utilize RBAC if there is an SSO service enabled. |
| Collector GitLab Build | (Optional) Periodically collects build data (pipelines) from a targeted GitLab instance. |
| Collector GitLab SCM |(Optional) Periodically collects SCM data (commits, branches, etc.) from a targeted GitLab instance. |
| Collector GitLab Workflow | (Optional) Periodically collects workflow data (tickets) from a targeted GitLab instance. |
| Collector Jira Workflow | (Optional) Periodically collects workflow data (tickets) from a targeted Jira instance. |
| Collector SonarQube Project Analysis | (Optional) Periodically collects project issue data (code smells, vulnerabilities, etc.) from a targeted SonarQube instance. |

**Note: While all collectors are optional, Holocron won't have any metrics and as such no value if none are utilized.**
