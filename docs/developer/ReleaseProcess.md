# Release Process

Big Bang Applications shall implement a following release process adhering to the following requirements

* Each Application shall maintain a long running release branch for all application version "N-2", meaning current upstream release and the previous two releases.
* The release process shall be automated by merging into this release branch
* The release process shall validate the application against all **supported** dependency releases using the automated [Testing Framework](Testing.md)
