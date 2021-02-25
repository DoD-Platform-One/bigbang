# This page where different types of documentation can be found:

## How this document is organized 
* Each type of documentation will have it's own section that covers
  - Summary of the use / purpose of the documentation
  - What you can expect to find here
  - How it should be organized if applicable 
  - Where it should be located
  - Any nuances around this documentation type

## Use Cases / Purpose / Types of Documentation: 
### 1. Big Bang Overview Docs: 
  - Should explicitly spell out the value of Big Bang in terms a Non technical PM can understand.
  - Engineer who has never seen Big Bang before should be able to get a concrete understanding of Big Bang via:
    - Architecture Diagram(s) needed to understand overview should exist here
    - A Component Maturity Matrix (This can explicitly list what's available and set expectations on mature vs new features)
  - A link + description of this should live in the root README.md of the [BB UHC Repo](https://repo1.dso.mil/platform-one/big-bang/bigbang).
  - This should live in /docs/overview.md of the [BB UHC Repo](https://repo1.dso.mil/platform-one/big-bang/bigbang).
  - This content https://confluence.il2.dso.mil/pages/viewpage.action?spaceKey=BB1&title=BigBang+UHC+Generic+Architecture+Diagram should be moved into /docs/overview.md

### 2. Big Bang Quick Start Demo, Code, and Docs: 
  - This should have example code + user friendly spell it out for me documentation that a random DoD Service member with little to no prior knowledge of Docker / Kubernetes, but access to hardware or a cloud account can use to spin up Big Bang Demo from scratch with minimal intervention.
  - This should live in a [quickstart repo](https://repo1.dso.mil/platform-one/quick-start/big-bang)
   A Nice thing about docs living in another repo is that we can be more lax when it comes to giving team members rights to a documentation repo / we can allow anyone on the team to review anyone elses MR before commiting instead of requiring only code owners to approve.
  - A link + description of this should live in the root README.md of the [BB UHC Repo](https://repo1.dso.mil/platform-one/big-bang/bigbang).
  - This should have a link to BB workshop, and BB workshop's public repo should have a link to a video walkthrough of the BB quickstart uploaded to git lfs (the video should stay out of the demo repo to optimize cloning)
  - An Architecture Diagram of how the quickstart works / leverages k3d should exist
  - Besides CI, this is the only place where non production demo hack type documenetation should exist. So shortcuts like using docker flux, not using a git repo to inject the BB UHC input helm values, using personal registry1 creds vs Iron Bank Robot Credential, k3d deployment helper scripts can exist here.    
  - [The following Big Bang Onboarding Residency Lab-Guides](https://repo1.dso.mil/platform-one/onboarding/big-bang/big-bang-residency-internal/-/tree/master/Lab-Guides) should be moved here
    - 17-Take-Home-DIY-Lab-Env

### 3. Post Installation Package Configuration Docs: 
  - Should exist in the repo of each individual package, and a documentation server hosted on BigBang as outlined [here](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/charter/PackageDocumentation.md). 
  - [The following Big Bang Onboarding Residency Lab-Guides](https://repo1.dso.mil/platform-one/onboarding/big-bang/big-bang-residency-internal/-/tree/master/Lab-Guides) should be moved into documentation of individual package repos
    - 08-Istio
    - 13-Prometheus-Operator-Stack
    - 14-Consolidated-Logging

### 4. Internet Connected Production Deployment Docs:
  - This should have BB Residency level of detail
  - The customer template repo https://repo1.dso.mil/platform-one/big-bang/customers/template     
   Should be renamed and moved to https://repo1.dso.mil/platform-one/big-bang/deployments/bb-internet-connected     
   (It'd act as a template + documentation on how to customize the template to a customers deployment env)
   A Nice thing about docs living in another repo is that we can be more lax when it comes to giving team members rights to a documentation repo / we can allow anyone on the team to review anyone elses MR before commiting instead of requiring only code owners to approve.     
  - A link + description of this should live in the root README.md of the [BB UHC Repo](https://repo1.dso.mil/platform-one/big-bang/bigbang).
  - [The following Big Bang Onboarding Residency Lab-Guides](https://repo1.dso.mil/platform-one/onboarding/big-bang/big-bang-residency-internal/-/tree/master/Lab-Guides) should be moved here
    - 01-Preflight-Access-Checks 
    - 04-Big-Bang-Prep-Work-and-Deployment
    - 05-Secrets-with-Mozilla-SOPS
    - 06-install-umbrella
    - 15-Customizing-and-Extending-Big-Bang
    - 16-Debug-Scenarios
  - The [current docs in the BB UHC repo](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/tree/master/docs) should be moved here as well / all of these docs should be merged together.

### 5. Internet Disconnected Production Deployment Docs: 
  - This would be where the BB Airgap solution team would store code and docs for the BB official upstream airgap deployment solution.
  - Should exist here https://repo1.dso.mil/platform-one/big-bang/deployments/bb-internet-disconnected 
   A Nice thing about docs living in another repo is that we can be more lax when it comes to giving team members rights to a documentation repo / we can allow anyone on the team to review anyone elses MR before commiting instead of requiring only code owners to approve.     
  - After it's stable a link + description of this should live in the root README.md of the [BB UHC Repo](https://repo1.dso.mil/platform-one/big-bang/bigbang).
  
### 6. Developer Contribution Docs: 
  - Only the latest version matters, and maybe improving docs around developer environment / process / doing things like updating a broken link should be allowed to be added to a master document faster / not go through the same level of scrutiny as a code merge where only Josh/Tom can accept it. Maybe it could exist in the [wiki?](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/wikis/developer/developer-documentation) and the BB Charter could link to the wiki so it'd still be readily discoverable.
  - Otherwise this should should exist in BB Charter. (needs discussion)

### 7. Big Bang Onboarding Residency: 
  - Phase 1: Move the majority of these docs to upstream documentation locations, mentioned above.
  - Phase 2: Let the residency have it's own repo, but heavily rewrite it so that it's just referencing upstream documentation/walking people through the upstream documentation. (and then have a few residency specific intro to kubernetes labs stay in residency)
    - 01-Preflight-Access-Checks
    - 02-Kubernetes-Refresher
    - 04-Big-Bang-Prep-Work-and-Deployment
