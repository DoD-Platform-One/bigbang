# 1. Big Bang's Primary Readme:
## Location: 
- https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/README.md

## Purpose: 
- Acts as a Table of Contents for discovering all other docs
  - All other docs should link back here
- Gives an Overview of BigBang that:
  - Explicitly spells out the value of BigBang in terms a Non Technical User can understand
  - Contains an Architecture Diagram
  - Contains a Component Maturity Matrix that lists available apps and their maturity level
- Documents the default values of the Umbrella Helm Chart


# 2. Big Bang Quick Start, Local Dev Env Setup, and Docs: 
## Location: 
- https://repo1.dso.mil/platform-one/big-bang/deployments/quick-start

## Purpose: 
- Guides new users with zero prior knowledge on how they can spin up Big Bang from scratch within 2 hours, will cover:
  - Any Prerequesites and suggestions for meeting them
  - Explanation of how k3d and BigBang automation works, so that new new users can understand whats happening as they follow quick start guide.
  - Multiple Methods of provisioning and interfacing with a k3d node
  - 2 Methods of installing BigBang to cover the following 2 use cases:
    1. Quick Start Demo:
       - Leverages preset config values in a public git repo
    2. Local Development Environment Setup:
       - Cover how to inject values using 100% local overrides (minimal GitOps / SOPS encryption) so new developers are aware of how to achieve fast feedback loop


# 3. Developer Contribution Docs: 
## Location: 
- https://repo1.dso.mil/platform-one/big-bang/bigbang/-/wikis/home

## Purpose:
- Home of Developer / Contributor facing Documentation


# 4. Internet Connected GitOps Deployment Docs:
## Location: 
- https://repo1.dso.mil/platform-one/big-bang/deployments/internet-connected

## Purpose:
- In Depth Documentation on how to configure a production grade internet connected deployment of Big Bang Covering:
  - Overview of the deployment process that includes explanations of how the automation works and why certain design decisions were made so that new users can understand what is happening and why things are done how they're done as they work through the deployment guide.
  - Suggested Repo organization conventions, standards, and reasoning
  - Any Prerequesites and suggestions for meeting them
    - How to prepare a new repo (this repo can double as a template repo)
    - How to Configure GitOps Encryption using SOPS
      - AWS KMS and IAM
      - (Future Additions)
    - A Checklist of secret config files to prepare
    - How to prepare secret config files, store them encrypted in git, and leverage them using GitOps
    - Flux Configuration for:
      - A Public Git Repo using HTTPS signed by Public CA
      - A Private Git Repo using HTTPS signed by Public CA


# 5. Internet Disconnected GitOps Deployment Docs:
## Location: 
- https://repo1.dso.mil/platform-one/big-bang/deployments/internet-disconnected 

## Purpose:
- In Depth Documentation on how to configure a production grade internet disconnected deployment of Big Bang Covering:
  - Overview of the deployment process that includes explanations of how the automation works and why certain design decisions were made so that new users can understand what is happening and why things are done how they're done as they work through the deployment guide.
  - Suggested Repo organization conventions, standards, and reasoning
  - Any Prerequesites and suggestions for meeting them
    - How to prepare a new repo (this repo can double as a template repo)
    - How to setup a Private SSH based Git Repo
    - How to setup and maintain a Internet Disconnected Registry
    - How to Configure GitOps Encryption using SOPS
      - Generic GPG Key Pairs
    - Flux Configuration for:
      - A Private Git Repo using HTTPS signed by a Private CA
      - A Private SSH based Git Repo


# 6. Post Installation Package Configuration Docs: 
## Location:  
- Should exist in the repo of each individual package, and a documentation server hosted on BigBang as outlined [here](https://repo1.dso.mil/platform-one/big-bang/bigbang/-/blob/master/charter/PackageDocumentation.md)
- These docs should be available on a webpage hosted on the Big Bang Cluster using Hugo
  (https://docs.bigbang.dev by default)

## Purpose:
- This allows us to support a centralized location for package configuration documentation, while allowing support for dynamically added versions of distributed packages in a maintainable way. 
