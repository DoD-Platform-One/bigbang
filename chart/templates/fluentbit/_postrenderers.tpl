{{- define "fluentbit.podPostRenderers" }}
- kustomize:
    patches:
      - patch: |
          - op: replace
            path: /spec/template/spec/containers/0/name
            value: fluent-bit
        target:
          kind: DaemonSet
          name: fluentbit-fluent-bit
          namespace: fluentbit
{{- end }}