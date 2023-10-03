# Contributing to Package OSCAL Documents within BigBang

## Why we have OSCAL documents in BigBang packages 
OSCAL (Open Security Controls Assessment Language) documents are used in BigBang packages to provide a standardized format for representing security controls and their implementation details. By using OSCAL documents, we ensure consistency, interoperability, and ease of understanding when working with security controls across different systems and tools.

## The basics of OSCAL Component schema
The OSCAL Component schema defines the structure and properties of a component in an OSCAL document. You can find detailed information about the OSCAL Component schema in the official OSCAL documentation: [OSCAL Component Schema](https://pages.nist.gov/OSCAL/reference/latest/component-definition/json-reference/#/component-definition/import-component-definitions).

### Example 
below is an example of our oscal-component.yaml file
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
Validating package OSCAL documents against the JSON Schema ensures that they adhere to the defined structure and properties. In addition to having OSCAL component validation within the BB CI pipelines, it is possible to manually validate an OSCAL document against the JSON Schema, you can use JSON Schema validation tools or libraries available for your programming language of choice.

### Here's a general process for validating package OSCAL documents:
* Obtain the latest JSON Schema for OSCAL documents.
* Use a JSON Schema validation tool/library to validate the OSCAL document against the schema.
* Verify that the document passes the validation without any errors or warnings.

### Example:
from the directory containing your oscal-component.yaml file

```shell
yq eval oscal-component.yaml -o=json > tmp-oscal-component.json
jsonschema -i tmp-oscal-component.json ${PATH_TO_OSCAL_SCHEMA}/oscal_component_schema.json -o pretty
```

By validating package OSCAL documents, we maintain the integrity and quality of the documentation within BigBang.

## Considerations when updating package OSCAL Documents
### When updating package OSCAL documents, it's essential to consider the following:
* Ensure partyID consistency: The partyID should remain consistent throughout all packages. Changing the partyID can cause confusion and potential errors. Always verify and ensure that the partyID remains unchanged during updates.
* Generate new UUID: Whenever a package OSCAL document is modified, a new UUID (Universally Unique Identifier) should be generated for the updated document. This ensures that the document retains its uniqueness and avoids potential conflicts.

## How to add a control-implementation
### To add a control-implementation to a package OSCAL document within BigBang, follow these steps:
* Identify the appropriate component or control section in the OSCAL document where the new control-implementation should be added.
* Create a new control-implementation element within the component or control section.
* Populate the necessary properties and values for the control-implementation, such as control ID, implementation status, responsible roles, and associated resources.
* Validate the updated OSCAL document against the JSON Schema to ensure its correctness.

Adding control-implementations allows for the documentation of specific control implementation details within the BigBang package.

## A brief explanation of our intentions to aggregate package OSCAL documents into a unified Big Bang OSCAL document
One of our goals is to aggregate package OSCAL documents into a unified Big Bang OSCAL document. This unified document will serve as a comprehensive representation of security controls and their implementations across various packages within the BigBang ecosystem.

By aggregating package OSCAL documents, we aim to provide a centralized reference point for understanding and managing security controls. It allows for easier comparison, analysis, and reporting of security control implementations across different systems, applications, and environments.

The unified Big Bang OSCAL document simplifies the process of ensuring consistency and standardization in security control implementations, ultimately enhancing the overall security posture and efficiency of the BigBang ecosystem.

* Remember to refer to the OSCAL documentation and guidelines provided by BigBang for specific implementation details and any updates to the contributing process.