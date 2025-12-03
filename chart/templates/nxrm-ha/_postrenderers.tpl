{{- define "nxrm-ha.prometheusPostRenderers" }}
{{- $nexusOldValues := default dict .Values.addons.nexus -}}
{{- $nexusValues := mergeOverwrite $nexusOldValues (index .Values.addons "nxrm-ha") -}}
{{- $serviceName := dig "values" "upstream" "fullnameOverride" "nxrm-ha" $nexusValues -}}
- kustomize:
    patches:
      - patch: |
          - op: add
            path: /metadata/labels/app
            value: {{ $serviceName }}
          - op: replace
            path: /spec/ports/0/name
            value: http-nexus-ui
        target:
          kind: Service
          name: {{ $serviceName }}
      - patch: |
          - op: replace
            path: /spec/ports/0/name
            value: http-nexus-ui
        target:
          kind: Service
          name: {{ $serviceName }}-hl
{{- end }}