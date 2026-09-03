# Repository Agent Instructions

[[_TOC_]]

## Purpose

Every active Big Bang repository must contain an accurate, repository-specific `AGENTS.md` at its root. The file is a concise context guide for AI-assisted contributors. It explains what the repository owns, where a change belongs, which local sources are authoritative, and where relevant implementation, validation, and integration guidance lives.

`AGENTS.md` complements human-facing README and contribution documentation. It must not become another copy of Big Bang user guidance or upstream product documentation.

This document is the source of truth for the Big Bang `AGENTS.md` structure. It implements [work item #3409](https://repo1.dso.mil/big-bang/bigbang/-/work_items/3409) and is consumed by the package rollout tracked in [work item #3410](https://repo1.dso.mil/big-bang/bigbang/-/work_items/3410).

## Design Rules

`AGENTS.md` should help contributors build relevant context quickly. It should answer:

- What does this repository own, and where are its boundaries with the umbrella repository, package repositories, and upstream projects?
- Which local files and external settings are authoritative?
- Where can contributors find the implementation, validation, integration, and maintenance guidance relevant to a change?

Keep the file concise, repository-specific, source-grounded, and tool-neutral. Link to maintained local, central, and upstream documentation instead of copying it. Do not use `AGENTS.md` to define generic agent behavior or duplicate metadata already available in repository files or GitLab. The hidden standard revision marker is the only required machine-readable metadata.

## Required Structure

Use this heading order:

```markdown
# AGENTS.md

<!-- big-bang-agents-standard: 1 -->

## Repository Purpose

## Sources of Truth

## Repository Layout

## Working Rules

## Commands

## Validation

## Big Bang Integration
```

Conditional sections may appear where they are most useful, but the required headings must retain this relative order. Do not include empty sections, `N/A` filler, generic advice, or unresolved placeholders.

### Repository Purpose

State what the repository owns, its role in Big Bang, and when a change belongs here. Identify the boundary with the umbrella repository, package repository, or upstream project as applicable.

Do not repeat marketing copy or a general Big Bang architecture overview.

### Sources of Truth

List the local files and external project settings that authoritatively define:

- versions and dependencies
- configuration and schema
- rendered or runtime behavior
- generated content and source inputs
- tests and CI
- ownership
- contribution and maintenance guidance
- current Big Bang standards and ADRs
- version-appropriate upstream documentation

Identify generated files explicitly. If CI is configured through a GitLab project setting rather than `.gitlab-ci.yml`, name the exact external config. Give each documentation reference a short label explaining what it owns rather than providing an undifferentiated list of links.

### Repository Layout

Describe only high-signal directories and files needed to locate implementation, configuration, documentation, and tests. Do not paste an exhaustive file tree.

### Working Rules

Record local invariants and edit boundaries that are easy to miss during a cold start. Examples include values precedence, public helper APIs, dry-run behavior, generated-file ownership, compatibility code, release branches, and files that must change together.

Do not restate ordinary language or Helm conventions.

### Commands

Provide exact commands that apply to the repository. Include the working directory, prerequisites, expected file changes, and remote side effects where they are not obvious.

Order commands from narrow and read-only to broad, networked, or mutating. If a check exists only in CI or requires protected credentials, say so rather than inventing a local equivalent.

### Validation

Map common change areas to the narrow check, complete local check, integration check, and authoritative CI evidence. A small table is usually clearer than an unqualified list of every test.

Distinguish chart-only rendering from clean-install, upgrade, package, umbrella, and infrastructure tests. State when cross-repository testing is required.

### Big Bang Integration

Explain the local Big Bang entry point and only the integrations that apply. Depending on the repository, this may include:

- chart origin and upstream dependency alias
- umbrella configuration mapping
- `bb-common` values and render helpers
- Flux source and release behavior
- Istio sidecar or ambient behavior
- network and authorization policy
- monitoring, SSO, storage, or database integration
- explicit image metadata and air-gap dependencies
- package-to-umbrella release handoff

Link detailed behavior rather than copying its complete configuration.

## Conditional Sections

Add a conditional section only when it contains concrete local instructions. A conditional section is mandatory when its condition applies.

| Section | Required when |
| --- | --- |
| `Safety and Credentials` | Commands can mutate GitLab, clusters, registries, cloud resources, production data, or the repository handles sensitive values. |
| `Generated Files` | The repository contains generated docs, schemas, locks, vendored dependencies, code, or metadata. |
| `Upgrade and Release Workflow` | The repository wraps an upstream project, uses special Renovate branches or version rules, or publishes artifacts. |
| `Integration Test Environment` | Meaningful validation requires the umbrella chart, k3d, a vendor cluster, external services, or cross-repository branches. |
| `Nested Instruction Scopes` | A monorepo requires more-specific instructions for a subproject. |
| `Troubleshooting` | Stable recovery steps are specific to the repository and do not duplicate general operations guidance. |

## Linking and Authority

Use the following authority order:

1. Executable configuration, schemas, tests, and repository metadata define factual state.
2. Accepted ADRs and current contribution standards define Big Bang policy.
3. Repository-specific maintenance documentation explains local workflows.
4. Upstream documentation defines the full upstream product and chart surface.

Apply these linking rules:

- Use relative links for files in the same repository so branches and forks remain usable.
- Prefer directly readable source Markdown for cross-repository Big Bang guidance.
- Link upstream configuration to the applicable chart version, release, or commit.
- Use moving upstream documentation only for version-independent concepts.
- Give each external link a purpose such as `upstream values`, `release notes`, or `Big Bang integration standard`.
- Label retained historical guidance with its applicable version or migration path.
- Correct `AGENTS.md` when it conflicts with an authoritative source; do not preserve compatibility with stale prose.

For passthrough values, follow [ADR 10](../adrs/0010-upstream-values-readme-documentation.md): document the upstream parent entry point, link to the applicable upstream `values.yaml`, and do not copy nested upstream keys, defaults, or descriptions. Keep Big Bang-owned values documented individually.

## Repository Profiles

The required structure is shared. Use these profile prompts to decide what local content belongs in it; do not create separate full templates that can drift.

### Umbrella Repository

- Identify package metadata, values, schema, templates, bootstrap, generators, and external CI sources.
- Explain generated package artifacts and configuration migration behavior.
- Document focused and full rendering plus compatibility matrices.
- Mark cluster-mutating and networked scripts.

### Integrated Package Repository

- State whether the chart is an upstream passthrough, Big Bang-authored chart, or legacy package layout.
- Identify the upstream alias, Big Bang-owned templates and values, vendored dependencies, image metadata, and generated README inputs.
- Keep package documentation focused on Big Bang-owned modifications and integration. Link to version-appropriate upstream documentation for understanding the package and its Helm chart rather than duplicating upstream content.
- Before changing a package, understand how Big Bang implements it by reviewing its source, values mapping, dependencies, and release wiring in the [umbrella repository](https://repo1.dso.mil/big-bang/bigbang).
- Optimize package integration for maintainability and compatibility with upstream behavior and the Big Bang umbrella. A bespoke solution that changes upstream behavior requires explicit approval from a human operator before implementation.
- Document package-local tests and when an umbrella test branch is required.
- Treat any change that requires end users to modify their configuration or operational process as breaking. Document the required action in the merge request's `## Upgrade Notices` section as described by the [CI workflow](ci-workflow.md#validate-mr).

### Maintained or Community Package

- State that the package is not rendered directly as a built-in integration.
- Explain generic package deployment and compatibility testing.
- Link the current support or lifecycle source instead of hardcoding a status or supported Big Bang range.

### Shared Library

- Treat templates, values, schemas, and public helpers as a consumer API.
- Document compatibility, deprecation, consumer tests, generation, and release rules.

### Pipeline or Automation Repository

- Identify external state and external CI contracts.
- Put dry-run requirements and production side effects prominently near commands.
- Explain mocked versus live tests and downstream compatibility obligations.

## Nested Instructions

The open [AGENTS.md format](https://agents.md/) allows nested files. The nearest file in the directory tree takes precedence.

Use a nested file only when a subproject has materially different commands or rules. The root file must list nested scopes. A nested file should contain only the differences for that scope and must not contradict inherited safety rules.

Do not store the canonical template as a nested file literally named `AGENTS.md` under `docs/`, because tools may apply it as instructions for that subtree. This page contains the canonical copyable structure instead.

## Validation

Structural validation and enforcement are owned by the shared [pipeline-templates repository](https://repo1.dso.mil/big-bang/pipeline-templates/pipeline-templates). Its `validate_agent_instructions` function verifies:

- root file presence and ignore status
- revision marker
- required headings and relative order
- non-empty required sections
- known unresolved template placeholder tokens

The umbrella pipeline invokes this function in its blocking `agent instructions` job when `AGENTS.md` or this standard changes. Reuse the shared function when adding enforcement to another pipeline; do not copy the validator into consuming repositories.

Markdown link validation is deliberately separate because correct parsing requires a standards-aware Markdown tool and external links require network access. Use the repository's established documentation link check. The umbrella pipeline runs `markdown_link_check` in its `link check` job with the repository's `.markdown-link-check.json` and `.markdown-link-check.yaml`; do not add a partial Markdown parser to structural validation.

These checks do not prove that a command works or that prose is current. Repository CODEOWNERS must verify every path, command, side effect, link applicability, and ownership statement. AI-assisted documentation-accuracy review may supplement this review but must not be the compliance gate.

Group-wide enforcement should begin in warning-only mode. A repository may make structural validation required when it introduces a compliant `AGENTS.md` or after it has adopted the current standard. Make validation required for a broader repository scope only after that scope has had a migration window.

## Source and Maintenance

This page is the canonical source of truth. Repository-specific `AGENTS.md` files, the package repository template, and pipeline checks are consumers.

Ownership is split deliberately:

- The CODEOWNERS for this page own required structure, authority rules, and the standard revision.
- Repository CODEOWNERS own local paths, commands, integration facts, and safety guidance.
- Pipeline maintainers own reusable structural enforcement.
- Group automation derives compliance scope from live GitLab state rather than maintaining another static repository list.

Update a repository's `AGENTS.md` whenever its layout, command runner, CI source, generated-file workflow, chart origin, upstream source, integration contract, or safety behavior changes.

Increment `big-bang-agents-standard` only when a normative change requires repository migration. A standard revision must include migration notes and coordinated updates to validator and repository-template consumers before it is declared adopted. Normal clarifications remain part of document history without forcing group-wide churn.

Automation may scaffold headings, report drift, or open a proposed merge request. It must not overwrite tailored repository content. Local maintainers review and approve every adoption and update.

## Adoption Checklist

1. Confirm the repository is active and identify its CODEOWNERS.
2. Remove ignore rules that exclude root `AGENTS.md`.
3. Inventory existing `AGENTS.md`, `CLAUDE.md`, or other tool-specific guidance.
4. Preserve useful local instructions and make tool-specific files thin pointers when they must remain.
5. Populate every required section from the checked-out default branch and current GitLab project settings.
6. Add every applicable conditional section.
7. Run structural validation and all documented read-only checks.
8. Have repository CODEOWNERS verify commands, links, side effects, and ownership boundaries.
9. Record the standard revision and validation result in the rollout issue.
10. Reconcile the rollout list against live project state at completion.

## Related Decisions

- [ADR 5: Passthrough Chart](../adrs/0005-passthrough-chart.md)
- [ADR 10: Upstream Values README Documentation](../adrs/0010-upstream-values-readme-documentation.md)
- [ADR 11: Unified Package Configuration and Metadata](../adrs/0011-unified-package-configuration-and-metadata.md)
- [Package integration guidance](package-integration/)
- [Big Bang bot allowlist](https://repo1.dso.mil/big-bang/team/tools/bigbang-bot/-/blob/main/src/whitelist/projects.json)
