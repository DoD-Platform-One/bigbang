# Package Owners

Package owners will be responsible for the following:

* Cutting releases for the packages and getting into Big Bang.
* Implementing package requirements outlined by the [package integration guide](../README.md).
* Reviewing Merge Requests (MRs) into the package repository.
* Reviewing MR CI/CD pipeline execution results to ensure that there are no regressions in conformance tests nor package cypress tests.  
* Tracking upstream changes to packages including new features, architectures, dependencies.
* Upgrading package with new upstream versions.
* Implementing features based on customer requests/requirements.
* Adding and improving interactions with current new new Big Bang packages.
* IronBank interactions:
  * Identifying new images to harden.
  * Notify IronBank of new versions available.
  * Testing new IronBank images.
  * [Long term] Providing CI processes for hardening images.

Package Owners will be identified by the use of [CODEOWNERS](https://docs.gitlab.com/ee/user/project/code_owners.html) files in the repository.

There must be at least three package owners for each application and they shall be from different companies. Inactive package owners from different value streams or external vendors shall be removed.

## Package Shadows

There can also be defined, for each package, shadows that are tracking ownership for each package. These shadows are responsible for filling in for the primary package
owners as needed. This could be the result of a package owner being on leave, or transitioning off of the team. The shadows will maintain situational awareness on all
Merge Requests and be ready and able to participate in resolving production issues. Shadows will be listed in the CODEOWNERS file like package owners.

## New Package Owners

A majority of package owners can approve the addition of a new member to the CODEOWNERs file, as long as one company does not control more than half the owners.
