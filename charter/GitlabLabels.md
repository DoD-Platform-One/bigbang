# Gitlab Labels

## Issues

Issues are required to have `status`, `priority` and `kind` labels.

Generally, all issues derived from an epic should have a `priority` value set to the `priority` of the epic its a part of.
Issues that are not part of an epic will need to be determined by a package owner or maintainer.

### `kind`

The kind label shows the type of work that needs to be accomplished

#### `kind::bug`

Issues related to Big Bang not functioning as expected

#### `kind::chore`

Catch all kind that captures administrative tasking for the Big Bang project

#### `kind:ci`

Issues related to the CI/CD, developer workflows and/or the release process

#### `kind::docs`

Issues related to documentation

#### `kind::feature`

Creation of a new capability for Big Bang and/or one of its packages

#### `kind::enhancement`

Improvement of an existing capability to work more efficiently in specific environments

#### `kind::test`

Improvements on testing for individual packages or Big Bang.  Does not change the actual CI/CD pipelines, just enhances the test suite.

### priority

#### `priority::1`

`priority::1` issues are causing runtime issues in production environments. These issues justify a patch of a release.

#### `priority::2`

`priority::2` TBD

#### `priority::3`

`priority:: 3` issues are defined by bugs that degrade system performance, but workarounds are available.

#### `priority::4`

`priority:: 4` TBD

#### `priority::5`

`priority::5` issues are superficial and do not have any impact on the functioning of production systems

### Status

Status captures the state of the issue

#### `status::blocked`

Blocked issues have an external dependency that needs to be solved before work can be completed.  This may be other Big Bang issues or hardening of IronBank images.  If blocked by an IronBank issue, the `ironbank` label should also be applied

#### `status::doing`

Work is actively being done on this issue.  At this point it should have an assignee

#### `status::review`

The issue is ready to be reviewed by a Maintainer

#### `status::to-do`

This Issue has not been started.

### Packages

Package labels are identified by their package name and serve two purposes.

1. Packages owners subscribe to the package labels for their packages and will be notified when a new issue or merge request is created with the label

## Merge Requests

Merge Requests are required to have `status` and `kind` labels.

### Status

Status captures the state of the Merge Request

#### `status::blocked`

Blocked merge requests and issues have an external dependency that needs to be solved before work can be completed.  This may be other Big Bang issues or hardening of IronBank images.

#### `status::doing`

Work is actively being done on this Merge Request

#### `status::review`

The Merge Request is ready to be reviewed by a Maintainer

#### `status::to-do`

This Merge Request has been assigned, but work as not been started.

### Packages

The package label controls which addons are deployed as part of CI. If a label is present for an addon, the Gitlab testing framework will enable this addon and ensure its tested as part

### `ci::test-infra`

The CI label for a Merge Request causes the full e2e CI job to run, which includes provisioning Kubernetes clusters in AWS.

### `charter`

This Merge Request has a proposed change to the Charter

## Epics

Epics are required to have `priority`, `size` and `status` labels.

### Status

Status captures the state of the Merge Request

#### `status::to-do`

This Epic is being identified and worked on by the Maintainers.

#### `status::review`

The Epic is ready for review by the engineering team.  Team can re-assign to `status::to-do` when more detail is needed.

#### `status::ready`

The epic is accepted by the team and ready for breakdown of work as priority dictates.

#### `status::doing`

Work has been broken out from this epic and is assigned to milestones for completion

#### `status::blocked`

Epic is blocked by an external dependency that needs to be solved before work can be completed.  This may be other Big Bang Epic or an Epic from another ValueStream.

### Priority

#### `priority::1`

Top of the backlog and should be broken down and worked on when cycles become available.

#### `priority::2`

TBD

#### `priority::3`

Medium term delivery providing long term value.

#### `priority::4`

TBD

#### `priority::5`

A nice to have, but not needed to advance the product.

### Size

The `size` label helps identify the scope of work needed as part of the epic

#### `size::small`

Sufficiently small enough to be completed by an engineer in a two week period

#### `size::medium`

A small number of engineers could complete this in a two week period

#### `size::large`

This epic should be broken down further into consumable sub-epics

#### `size::xl`

This epic needs to be broken down further to be able to be tackled in a sprint
