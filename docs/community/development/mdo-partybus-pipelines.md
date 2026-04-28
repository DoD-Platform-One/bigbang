# Mission DevOps (MDO) PartyBus Pipelines Overview

PartyBus maintains pipeline infrastructure to build, scan, and accredit applications for Certificate to Field (CTF). PartyBus supports use cases that include custom code for plugins, binaries, and/or extensions.

To request a new pipeline for an application that requires hosting in PartyBus, submit a request through the PartyBus Service Desk in [Jira IL2](https://jira.il2.dso.mil/servicedesk/customer/portal/73). Create the issue as a **“New Pipeline Request”** and clearly state that you would like a pipeline and repository created.

PartyBus repositories can also be configured to mirror repositories created in the Big Bang group in Repo1.

---

## Hosting a Mirrored Repository in PartyBus

1. Create a repository for your code in Repo1

2. Request mirroring to `code.il2.dso.mil` by creating an issue for the MDO team in [Jira IL2](https://jira.il2.dso.mil/servicedesk/customer/portal/73).  
   - Select **“New Pipeline Request.”**  
   - State that you would like a pipeline and repository created from the provided Repo1 link.

3. Create a project access token in the Repo1 project for IL2 cloning:
   - Navigate to **Settings → Access Tokens** in the project.
   - Select the `read_repository` scope.
   - Set the role to `Reporter`.
   - Name the token with a clear reference, such as `partybus-il2`.
   - Set the expiration date to one year from the creation date.
   - Click **“Create project access token.”**
   - Save the generated token (displayed at the top of the page) and provide it to the MDO team via `chat.il4` when prompted.

4. After mirroring to `code.il2.dso.mil` is complete, the pipeline will begin running automatically.
   - Depending on the application’s language, the pipeline will execute language-specific linting and unit testing stages.
   - It will then run security and quality scanning stages, including `TruffleHog`, `Fortify`, `Dependency-Check`, and `SonarQube`.

If any stages fail, investigate the cause. For false positives or issues requiring exceptions, submit a **“Pipeline Exception Request”** in [Jira IL2](https://jira.il2.dso.mil/servicedesk/customer/portal/73).
