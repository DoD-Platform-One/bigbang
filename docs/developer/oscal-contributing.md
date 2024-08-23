# Contributing to Package OSCAL Documents within Big Bang

## Why we have OSCAL documents in Big Bang Packages 

Open Security Controls Assessment Language (OSCAL) artifacts are used in Big Bang packages to provide a standardized format for representing security controls and their implementation details. By using OSCAL artifacts, we ensure consistency, interoperability, and ease of understanding when working with security controls across different systems and tools.

## The Basics of OSCAL Component Schema

The OSCAL Component definition schema defines the structure and properties of a component in an OSCAL document. You can find detailed information about the OSCAL Component schema in the official OSCAL documentation: [OSCAL Component Schema](https://pages.nist.gov/OSCAL-Reference/models/latest/component-definition/json-reference/).

### Example 

The following is an example of our `oscal-component.yaml` file:

```yaml
component-definition:
  uuid: <<unique uuid>>
  metadata: 
    title: << Component Name>>
    last-modified: '2021-10-19T12:00:00Z'
    version: 20211019
    oscal-version: 1.0.0
    parties:
      # Should be consistent across all of the packages, but where is ground truth?
    - uuid: 72134592-08C2-4A77-ABAD-C880F109367A 
      type: organization
      name: Platform One
      links:
      - href: <https://p1.dso.mil>
        rel: website
  components:
  - uuid: <<unique uuid>>
    type: software
    title: << Component Name >>
    description: |
      << Fill me out >>
    purpose: << Fill me out >>
    responsible-roles:
    - role-id: provider
      party-uuid: 72134592-08C2-4A77-ABAD-C880F109367A # matches parties entry for p1
    control-implementations:
    - uuid: <<unique uuid>>
      source: https://raw.githubusercontent.com/usnistgov/oscal-content/master/nist.gov/SP800-53/rev5/json/NIST_SP-800-53_rev5_catalog.json
      description:
        Controls implemented by <component> for inheritance by applications
      implemented-requirements:
      // for each row
      - uuid: 6EC9C476-9C9D-4EF6-854B-A5B799D8AED1
        control-id: <control-id> // The control in the row that has a non-empty cell in the column for this package
        description: >-
          < insert the contents of the cell in the the table

```
## How to validate package OSCAL documents against JSON Schema

Validating package OSCAL documents against the JSON Schema ensures that they adhere to the defined structure and properties. In addition to having OSCAL component validation within the Big Bang CI pipelines, it is possible to manually validate an OSCAL document against the JSON Schema, you can use JSON Schema validation tools or libraries available for your programming language of choice.

### OSCAL Schema Compliance

When creating or updating OSCAL artifacts to reflect changes in the underlying components, it is imperative to ensure the artifacts remain compliant with the schema - allowing for interoperability between tools that will consume the OSCAL.

[Lula](https://docs.lula.dev) provides awareness of all OSCAL schemas `>=1.0.4` and will both auto-detect the artifact `oscal-version` as well as validate the artifact for validity against said schema. 

Validating any OSCAL model/artifact can be done with the following command:
```bash
lula tools lint -f oscal-component.yaml
```

This process is ran in [pipelines](https://repo1.dso.mil/big-bang/pipeline-templates/pipeline-templates/-/blob/master/library/templates.sh?ref_type=heads#L127) to ensure that any modifications to the OSCAL is caught during Configuration Checks. 

## OSCAL Upgrades

Keeping OSCAL artifacts up-to-date is important in ensuring the long-term success of Big Bang re-usable control information. 

Lula provides an upgrade command to help reduce the cognitive burden when performing this action:

```bash
lula tools upgrade -f oscal-component.yaml
```

This command validates the integrity of the data against the target version schema - determines if there are any required updates to perform - and in the event there are no breaking changes will auto-upgrade the OSCAL artifact. Otherwise Lula will provide information for where information may be lost for remediation purposes.

## Considerations when Updating Package OSCAL Documents

When updating package OSCAL documents, it's essential to consider the following:

* **Ensure PartyID Consistency:** The partyID should remain consistent throughout all packages. Changing the partyID can cause confusion and potential errors. Always verify and ensure that the partyID remains unchanged during updates.
* **Generate New UUID:** Whenever a package OSCAL document is modified, a new Universally Unique Identifier (UUID) should be generated for the updated document. This ensures that the document retains its uniqueness and avoids potential conflicts.

## How to add a control-implementation - Manual

To add a control-implementation to a package OSCAL document within Big Bang, follow these steps:

* Identify the appropriate component or control section in the OSCAL document where the new control-implementation should be added.
* Create a new control-implementation element within the component or control section.
* Populate the necessary properties and values for the control-implementation, such as control ID, implementation status, responsible roles, and associated resources.
* Validate the updated OSCAL document against the JSON Schema to ensure its correctness.

Adding control-implementations allows for the documentation of specific control implementation details within the Big Bang package.

## How to add a control-implementation - Automated & Reproducible

Lula provides the ability to generate component definitions given required context for performing the operation. 

Given the following:
- Source of an OSCAL catalog to pull control information
  - This must be the raw source url 
  - IE https://raw.githubusercontent.com/usnistgov/oscal-content/main/nist.gov/SP800-53/rev5/json/NIST_SP-800-53_rev5_catalog.json
- Controls to include
- Title of the component
- Remark target

Lula can generate a component definition with the following command:
```bash
lula generate component -c <catalogsource> -r ac-1,ac-2,au-4 --component "Service Mesh" --remarks assessment-objective -o oscal-component.yaml
```

Lula will generate a component with a control-implementation containing the controls from the catalog translated to implemented-requirements. 

This operation will both produce an annotation for how to imperatively reproduce the artifact generation as well as allows for merging content into existing objects. If a component already exists in a component-definition and the `-o` flag directs the output of the command into this existing file, Lula will perform a merge operation to add or update existing information as required.

Example Annotation for Istio and an Impact-Level 4 framework
```yaml
props:
  - name: generation
    ns: https://docs.lula.dev/oscal/ns
    value: lula generate component --catalog-source https://raw.githubusercontent.com/GSA/fedramp-automation/93ca0e20ff5e54fc04140613476fba80f08e3c7d/dist/content/rev5/baselines/json/FedRAMP_rev5_HIGH-baseline-resolved-profile_catalog.json --component 'Istio Controlplane' --requirements ac-14,ac-4,ac-4.21,ac-4.4,ac-6.3,ac-6.9,au-12,au-2,au-3,au-3.1,cm-5,sc-10,sc-13,sc-23,sc-3,sc-39,sc-4,sc-7.20,sc-7.21,sc-7.4,sc-7.8,sc-8,sc-8.1,sc-8.2 --remarks assessment-objective --framework il4
```

## Assessment Automation

OSCAL generically provides data for security controls of components that can be applied against systems that consume Big Bang. We can further augment that value of OSCAL by implementing [Lula Validations](https://docs.lula.dev/reference/) for which to automatically assess security controls in the context of a single package in isolation or that of a full Big Bang deployment. 

Lula does this by insertion of one-to-many `lula` links per `implemented-requirement` which map the control to a list of `Validations` that perform the collection of holistic context (all pods in a cluster, namespace metadata, etc) and then evaluate that data against a policy which allows for measuring adherence. 

These links can be in the form of an item in the associated `back-matter` of the `component-definition` or a separate local or remote file containing the validations. 

Examples:
```yaml
links:
  - href: 'file://./istio/healthcheck/validation.yaml'
    rel: lula
    text: Check that Istio is healthy with a local validation file
  - href: '#7df8abad-d2e3-4944-a500-68bfe4f8c591'
    rel: lula
    text: Check that Istio is healthy with a validation in the back matter
```

Once a link as established as a Lula validation, Lula will collect and perform the execution of a validation and map the result as evidence to support whether the security control (with context of locality) enables a security control to be met in a given environment.

## Compliance Evaluation

Given the process above automating the assessment of packages and OSCAL, we can instrument an Automated Governance workflow that ensures all development of a package ensures equal or greater compliance has been met prior to allowing the merge of proposed changes. 

This is accomplished with in a [pipeline](https://repo1.dso.mil/big-bang/pipeline-templates/pipeline-templates/-/blob/master/library/package-functions.sh?ref_type=heads#L483) by using a previous assessment (in the form of the assessment-results OSCAL model artifact) and ensuring that the new assessment meets or exceeds the threshold result, otherwise failing. 

The core of this workflow is as follows:
```bash
# perform validation and create or merge with the existing oscal-assessment-results.yaml artifact
lula validate -f oscal-component.yaml -o oscal-assessment-results.yaml

# perform evaluation of compliance adherence
lula evaluate -f oscal-assessment-results.yaml

# If there was no pre-existing oscal-assessment-results.yaml artifact the command will exit successfully stating there is no previous state to evaluate against.

# If there is a previous threshold result established, it will compare the state of findings, requiring all previously `satisfied` controls to still be `satisfied` otherwise failing.
```

**NOTE:** Remember to refer to the OSCAL documentation and guidelines provided by BigBang for specific implementation details and any updates to the contributing process.
