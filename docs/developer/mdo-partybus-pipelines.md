# MDO Pipelines Overview

At times Big Bang will have code for a plugin/binary/extension/etc that we'll need to fork/create/re-host and when we do so we should have the code ran through a PartyBus MDO pipeline and the resulting artifact used within the Platform.

1. Create a repo for the code within repo1 under https://repo1.dso.mil/platform-one/big-bang/apps/product-tools/
1. This repo will need to be mirrored to code.il2.dso.mil. Create issue for the MDO team within [Jira IL2](https://jira.il2.dso.mil/servicedesk/customer/portal/73) as a "New Pipeline Request" and state that you would like a pipeline and repo created from this repo1 link.
1. Create access token within repo1 project for the IL2 cloning, browse to Settings for the project > Access Tokens > check `read_repository` with a role of `Reporter` enter a name mentioning `partybus-il2` and ensure there is a date of expiration set for 1 year from this creation time > Click `Create project access token` and save the output at the top of the page to send to the MDO team over chat.il4 when prompted.
1. Once mirroring to code.il2 is successful the pipeline will start running and depending on the languange, will run it's specific lint and unit testing stages and eventually get to trufflehog, fortify, dependencyCheck & sonarqube stages at the end. If any of these are throwing errors you will have to investigate why and can open issues to gain exceptions for any false-positives or other issues within [JIRA IL2](https://jira.il2.dso.mil/servicedesk/customer/portal/73) with a "Pipeline Exception Request".
