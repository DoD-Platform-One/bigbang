def local_definition_name:
  if type == "string" and startswith("#/$defs/") and (split("/") | length) == 3
  then split("/")[2]
  else null
  end;

def merge_properties($left; $right):
  reduce ($right | to_entries[]) as $entry ($left;
    .[$entry.key] = if .[$entry.key] == null or .[$entry.key] == true
                    then $entry.value
                    elif $entry.value == true
                    then .[$entry.key]
                    else $entry.value
                    end
  );

def collect_properties($schema; $node; $seen):
  if ($node | type) != "object" then
    {}
  else
    ($node["$ref"]? // null) as $ref
    | ($ref | local_definition_name) as $definition_name
    | (if $definition_name != null and (($seen[$ref] // false) | not)
       then [collect_properties($schema; $schema["$defs"][$definition_name]; $seen + {($ref): true})]
       else []
       end) as $referenced_properties
    | ([$node.allOf[]?, $node.anyOf[]?, $node.oneOf[]?, $node.then?, $node.else?]
       | map(collect_properties($schema; .; $seen))) as $composed_properties
    | reduce (($referenced_properties + $composed_properties + [($node.properties // {})])[]) as $properties
        ({}; merge_properties(.; $properties))
  end;

# Canonical package values are recursively merged over legacy defaults. Remove
# requirements that may be satisfied by those defaults while retaining types,
# enums, patterns, known properties, and complete validation for array elements.
def partialize($partial_object):
  if type == "array" then
    map(partialize($partial_object))
  elif type != "object" then
    .
  else
    with_entries(
      select(($partial_object and (.key == "required" or .key == "dependentRequired" or .key == "minProperties")) | not)
      | if .key == "$ref" and $partial_object and ((.value | local_definition_name) != null) then
          .value = "#/$defs/packageAliasPartials/\(.value | local_definition_name)"
        elif .key == "items" or .key == "contains" or .key == "if" or .key == "not" then
          .value |= partialize(false)
        elif (.key == "properties" or .key == "patternProperties" or .key == "additionalProperties")
             and (.value | type) == "object" then
          .value |= with_entries(.value |= partialize(true))
        else
          .value |= partialize($partial_object)
        end
    )
  end;

def schema_at_legacy_path($schema; $legacy_path):
  reduce ($legacy_path | split("."))[] as $segment ($schema; .properties[$segment]);

def value_at_legacy_path($values; $legacy_path):
  reduce ($legacy_path | split("."))[] as $segment ($values; .[$segment]);

def package_alias($schema; $values; $package):
  schema_at_legacy_path($schema; $package.value.legacyPath) as $legacy_schema
  | value_at_legacy_path($values; $package.value.legacyPath) as $legacy_defaults
  | collect_properties($schema; $legacy_schema; {}) as $schema_properties
  | (reduce ($legacy_defaults | keys[]) as $name ($schema_properties;
      if has($name) then . else .[$name] = true end
    )) as $properties
  | ($legacy_schema | partialize(true))
  | del(.required)
  | .type = "object"
  | .properties = ($properties | with_entries(.value |= partialize(true)))
  | .additionalProperties = false
  | .description = "Partial override merged over the built-in package's legacy defaults.";

def validate_metadata($metadata):
  if $metadata.apiVersion != "bigbang.dev/v1alpha1" then
    error("package metadata apiVersion must be bigbang.dev/v1alpha1")
  elif ($metadata.packages | type) != "object" or ($metadata.packages | length) == 0 then
    error("package metadata packages must be a non-empty mapping")
  elif any($metadata.packages | to_entries[]; . as $package
           | ($package.key | type) != "string" or ($package.key | length) == 0
           or ($package.value | type) != "object"
           or any(["displayName", "category", "legacyPath", "templateDirectory", "documentation"][]; . as $field
                  | ($package.value[$field]? // "") as $value
                  | ($value | type) != "string" or ($value | length) == 0)) then
    error("package metadata contains a missing or invalid required field")
  elif any($metadata.packages | keys[]; test("^[a-z][A-Za-z0-9]*$") | not) then
    error("package metadata package keys must use camelCase identifiers")
  elif any($metadata.packages[].templateDirectory;
           test("^[a-z0-9]+(-[a-z0-9]+)*$") | not) then
    error("package metadata templateDirectory values must use kebab-case directory names")
  elif any($metadata.packages[]; .category != "core" and .category != "addon") then
    error("package metadata category must be core or addon")
  elif any($metadata.packages[];
           .documentation != "docs/packages/\(if .category == "addon" then "addons" else .category end)/\(.documentation | split("/") | last)") then
    error("package metadata documentation paths must match the package category")
  elif any($metadata.packages[].documentation;
           test("^docs/packages/(core|addons)/[a-z0-9]+(-[a-z0-9]+)*\\.md$") | not) then
    error("package metadata documentation paths must name a package Markdown page")
  elif any($metadata.packages | to_entries[];
           .value.legacyPath != (if .value.category == "addon" then "addons.\(.key)" else .key end)) then
    error("package metadata legacyPath does not match its package name and category")
  elif (($metadata.packages | map(.legacyPath) | length) != ($metadata.packages | map(.legacyPath) | unique | length)) then
    error("package metadata legacyPath values must be unique")
  elif (($metadata.packages | map(.templateDirectory) | length) != ($metadata.packages | map(.templateDirectory) | unique | length)) then
    error("package metadata templateDirectory values must be unique")
  else
    $metadata
  end;

validate_metadata($metadata[0]) as $validated_metadata
| . as $schema
| $values[0] as $chart_values
| ($schema["$defs"].customPackages // {
    "type": "object",
    "additionalProperties": $schema.properties.packages.additionalProperties
  }) as $custom_packages
| (reduce ($validated_metadata.packages | to_entries[]) as $package
    ({}; .[$package.key] = package_alias($schema; $chart_values; $package))) as $aliases
| (reduce ($validated_metadata.packages | keys_unsorted[]) as $name
    ({}; .[$name] = {"$ref": "#/$defs/packageAliasPartials/aliases/\($name)"})) as $package_properties
| ($schema["$defs"] | del(.packageAlias, .packageAliasPartials, .customPackages, .canonicalPackages)
   | with_entries(.value |= partialize(true))) as $partial_definitions
| ($custom_packages + {"properties": $package_properties}) as $canonical_packages
| .properties.packages = {}
| del(.["$defs"].packageAlias)
| .["$defs"].customPackages = $custom_packages
| .["$defs"].canonicalPackages = $canonical_packages
| .["$defs"].packageAliasPartials = ($partial_definitions + {aliases: $aliases})
| .allOf = (((.allOf // [])
    | map(select(."$comment" != "Generated canonical package configuration gate."))) + [{
      "$comment": "Generated canonical package configuration gate.",
      "if": {
        "properties": {
          "packageConfiguration": {
            "properties": {"version": {"const": "v1"}},
            "required": ["version"]
          }
        },
        "required": ["packageConfiguration"]
      },
      "then": {
        "properties": {
          "packages": {"$ref": "#/$defs/canonicalPackages"}
        }
      },
      "else": {
        "properties": {
          "packages": {"$ref": "#/$defs/customPackages"}
        }
      }
    }])
