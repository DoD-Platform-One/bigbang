# Repo1 Big Bang GitLab Labels

[[_TOC_]]

## Scope and source of truth

This document refreshes the labeling guidance for the **Repo1 Big Bang workspace**. It applies to issues, merge requests, and epics in the Big Bang group and its projects.

The live GitLab group and project labels, including their descriptions, are the source of truth for labels currently available in Repo1. This document defines how labels are used; it does not reproduce the complete live label catalog.

- [Repo1 Big Bang group labels](https://repo1.dso.mil/groups/big-bang/-/labels)
- [Big Bang umbrella repository](https://repo1.dso.mil/big-bang/bigbang)


## Issues

Every issue requires exactly one label from each of these four families:

- `status`
- `priority`
- `kind`
- `team`

Package labels and workflow labels may be added when useful or required. They do not replace any of the four required families. Issues created from community contributions must also use `community-contribution`.

### Status

Use one applicable status label to show the current state of the issue. The general status values are:

- `status::awaiting-community-response`: Big Bang is waiting for a response or additional information from the community.
- `status::blocked`: work cannot proceed because of a dependency or blocker.
- `status::doing`: work is actively being performed.
- `status::grooming`: the issue is being refined before execution.
- `status::needs-testing`: work requires testing before it can advance.
- `status::ready-to-work`: work is ready to begin but has not started.
- `status::review`: work is ready for review.

### Priority

Priority is required for issues. Use exactly one of the four canonical levels:

- `priority::1`: breaking or critical work, including production-impacting failures, release-blocking failures, or delayed updates that have become urgent. This includes critical Renovate escalations.
- `priority::2`: Renovate updates and only Renovate updates.
- `priority::3`: non-breaking bugs with a viable workaround, including issues that affect runtime but can be worked around.
- `priority::4`: feature and epic work.

### Kind

Use exactly one kind label. The canonical categories are:

- `kind::bug`: Big Bang is not functioning as expected.
- `kind::chore`: administrative, onboarding, repository-management, or similar support work.
- `kind::docs`: documentation-only work.
- `kind::feature`: a new capability or an improvement to an existing capability.
- `kind::renovate`: Renovate maintenance work.

### Team

Use exactly one active team label. The intended active set is:

- `team::Big Bang Anchors`
- `team::Edge`
- `team::Package Maintenance`
- `team::Platform Engineering`
- `team::Product Improvement`

`team::Big Bang Anchors` may identify umbrella ownership and escalation/support work.

## Merge requests

When a merge request maps cleanly to one issue, use the same four label families as that issue: `status`, `priority`, `kind`, and `team`.

When a merge request addresses multiple issues, apply labels on a best-effort basis using the merge request's primary scope. Package and CI-trigger labels may be added when applicable.

## Epics

Every epic requires:

- exactly one epic-state label: `epic::grooming`, `epic::now`, `epic::backlog`, or `epic::blocked`;
- exactly one PI increment label: `PI::Q1`, `PI::Q2`, `PI::Q3`, or `PI::Q4`; and
- exactly one team label.

Epics do not require a priority label. `epic::EdgeRelease` is retained as an exception for work outside the owning Big Bang team; it is not an epic-state label.

Epic states mean:

- `epic::grooming`: the epic needs refinement and is being prepared for prioritization or execution.
- `epic::now`: the epic is actively being worked.
- `epic::backlog`: the epic is valid work but is not currently prioritized for execution.
- `epic::blocked`: work cannot proceed because of an external dependency or another blocked prerequisite.


