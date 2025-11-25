# Big Bang Template Self-testing Guide

The Big Bang chart includes a self-testing functionality that allows you to
easily verify the functionality of individual templates.

## How it works

The self-testing feature is implemented using a special section in the
`values.yaml` file called `_selfTest`. This section allows you to define tests
for specific templates by specifying the template name and the arguments to be
passed to the template.

When the self-test is executed, the specified template is rendered with the
provided arguments, and the result is placed at the `result` key in a special
`TestResult` resource named after the template.

The self-test results can then be used in unit tests to verify the correctness
of the template.

### Example

Let's say we have a simple template that multiplies two numbers together. The
template is defined as follows:

```gotmpl
{{- define "bigbang.example-template.multiply" }}
  {{- mul (index . 0) (index . 1) }}
{{- end }}
```

A test for this template can be defined in the `_selfTest` section of the
`values.yaml` file:

```yaml
_selfTest:
  bigbang.example-template.multiply:
    args:
      - 2
      - 3
```

The test specifies the arguments to be passed to the template. In this case, we
are passing a list of two numbers: `2` and `3`.

When the self-test is executed, the template is rendered with the provided
arguments, and the result is placed at the result key:

```sh
helm template chart --show-only templates/_self-test/render.yaml
```

```yaml
---
# Source: bigbang/templates/_self-test/render.yaml
apiVersion: testing.bigbang.dev/v1
args:
  - 2
  - 3
kind: TestResult
metadata:
  name: bigbang.example-template.multiply
result: "6"
```

> **Note:** The result is a string because Helm templates always render strings.

## Using self-test results in unit tests

The self-test results can be used in unit tests to verify the correctness of the
template. For example, you can create a unit test that checks if the result of
the multiplication is as expected:

```yaml
suite: bigbang.example-template.multiply
tests:
  - it: multiplies two numbers correctly
    set:
      _selfTest:
        bigbang.example-template.multiply:
          args:
            - 2
            - 3
    asserts:
      - equal:
          path: result
          value: "6"
```

## Asserting yaml structures

In cases where the output of a template is a complex YAML structure, you can set
the `resultIsYaml` flag to `true` in the `_selfTest` section. This will instruct
the testing framework to parse the `result` as YAML, allowing you to perform
assertions on individual fields within the structure.

### Example

For example, consider a template that receives a map of key-value pairs and
generates a Kubernetes `ConfigMap`:

```gotmpl
{{- define "bigbang.example-template.configmap" }}
apiVersion: v1
kind: ConfigMap
metadata:
  name: example-config
data:
  {{- range $key, $value := . }}
  {{ $key }}: {{ $value | quote }}
  {{- end }}
{{- end }}
```

A test for this template can be defined in the `_selfTest` section of the
`values.yaml` file:

```yaml
_selfTest:
  bigbang.example-template.configmap:
    args:
      key1: value1
      key2: value2
```

When the self-test is executed, the template is rendered with the provided
arguments, and the result is placed at the `result` key:

```sh
helm template chart --show-only templates/_self-test/render.yaml
```

```yaml
---
# Source: bigbang/templates/_self-test/render.yaml
apiVersion: testing.bigbang.dev/v1
args:
  key1: value1
  key2: value2
kind: TestResult
metadata:
  name: bigbang.example-template.configmap
result: |
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: example-config
  data:
    key1: "value1"
    key2: "value2"
```

In this case, the `result` is a multi-line string representing the YAML
structure of the `ConfigMap`.

By setting the `resultIsYaml` flag to `true`, you can have the testing framework
parse the `result` as YAML, allowing you to perform assertions on individual
fields within the structure:

```diff
 _selfTest:
   bigbang.example-template.configmap:
     args:
       key1: value1
       key2: value2
+    resultIsYaml: true
```

```diff
 ---
 # Source: bigbang/templates/_self-test/render.yaml
 apiVersion: testing.bigbang.dev/v1
 args:
   key1: value1
   key2: value2
 kind: TestResult
 metadata:
   name: bigbang.example-template.configmap
-result: |
+result:
   apiVersion: v1
   kind: ConfigMap
   metadata:
     name: example-config
   data:
     key1: "value1"
     key2: "value2"
```

```yaml
suite: bigbang.example-template.configmap
tests:
  - it: creates a ConfigMap with the correct data
    set:
      _selfTest:
        bigbang.example-template.configmap:
          args:
            key1: value1
            key2: value2
          resultIsYaml: true
    asserts:
      - equal:
          path: result.data.key1
          value: "value1"
      - equal:
          path: result.data.key2
          value: "value2"
```

## Passing the helm root context to templates

In some cases, you may want to pass the entire Helm root context to a template
for testing purposes. This can be achieved by using the special argument
`helm:context`.

### Example

For example, consider a template that generates a `Service` resource based on
values from the Helm root context:

```yaml
app:
  name: my-app
service:
  name: my-service
  type: ClusterIP
  port: 80
  targetPort: 8080
```

```gotmpl
{{- define "bigbang.example-template.service" }}
apiVersion: v1
kind: Service
metadata:
  name: {{ .Values.service.name }}
spec:
  type: {{ .Values.service.type }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.targetPort }}
  selector:
    app: {{ .Values.app.name }}
{{- end }}
```

A test for this template can be defined in the `_selfTest` section of the
`values.yaml` file, using the `helm:context` argument to pass the entire Helm
root context:

```yaml
_selfTest:
  bigbang.example-template.service:
    args: helm:context
```

When the self-test is executed, the template is rendered with the Helm root
context, and the result is placed at the `result` key:

```sh
helm template chart --show-only templates/_self-test/render.yaml
```

```yaml
---
# Source: bigbang/templates/_self-test/render.yaml
apiVersion: testing.bigbang.dev/v1
args:
  # The helm:context expands to the full Helm root context, including
  # all values, capabilities, release info, and chart metadata.
  Values: { ... }
  Capabilities: { ... }
  Release: { ... }
  Chart: { ... }
kind: TestResult
metadata:
  name: bigbang.example-template.service
result: |
  apiVersion: v1
  kind: Service
  metadata:
    name: my-service
  spec:
    type: ClusterIP
    ports:
      - port: 80
        targetPort: 8080
    selector:
      app: my-app
```

For flexible argument support, the `helm:context` magic string is also supported
as part of a list or as a value in a top-level map key:

```yaml
_selfTest:
  bigbang.example-template.i-take-a-list:
    args:
      - helm:context
      - someOtherValue
```

```yaml
_selfTest:
  bigbang.example-template.i-take-a-map:
    args:
      config: helm:context
      otherConfig: someOtherValue
```

```yaml
_selfTest:
  bigbang.example-template.i-take-a-deeply-nested-map:
    args:
      config:
        nestedConfig: helm:context # This does NOT work; only top-level keys support helm:context
      otherConfig: someOtherValue
```

This allows you to test templates that require the full Helm context while still
being able to pass additional arguments as needed.
