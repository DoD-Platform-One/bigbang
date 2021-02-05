# Package Owners

Package owners will be responsible for the following:

* Cutting Releases
* Implementing Package requirements outlined by [Package Requirements](PackageRequirements.md)
* Reviewing Merge Requests into the Package Repository
* Reviewing Merge Request CI/CD pipeline execution results to ensure that there are no regressions in conformance tests nor package cypress tests.  

Package Owners will be identified by the use of [CODEOWNERS](https://docs.gitlab.com/ee/user/project/code_owners.html) files in the repository.

There must be at least 2 (two) Package owners for each application and they shall be from different companies.

## Package Shadows

There can also be defined, for each package, shadows that are tracking ownership for each package.  These shadows are responsible for filling in for the primary package
owners as needed.  This could be the result of a package owner being on leave, or transitioning off of the team.  The shadows will maintain situational awareness on all
Merge Requests and be ready and able to participate in resolving production issues.  Shadows will be listed in the CODEOWNERS file like Package Owners.

## New Package Owners

A majority of Package Owners can approve the addition of a new member to the CODEOWNERs file, as long as one company does not control more than half the owners.
