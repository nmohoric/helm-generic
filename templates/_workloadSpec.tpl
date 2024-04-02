{{/*
Default workload spec values
*/}}
{{- define "helm-generic.workload-spec-overlay" -}}
selector:
  matchLabels:
    {{- include "helm-generic.selectorLabels" . | nindent 4 }}
template:
  metadata:
    {{- include "helm-generic.pod-spec-metadata" . | nindent 4 }}
{{- end -}}

{{/*
Generate the workload yaml resource
*/}}
{{- define "helm-generic.workload-resource" -}}
{{- $root := . }}
{{- $resource := deepCopy .resource }}
{{- $_ := set $resource "spec" (mustMergeOverwrite (include "helm-generic.workload-spec-overlay" $root | fromYaml) $resource.spec) }}

{{- $podPassthroughRoot := deepCopy (omit $root "resource") }}
{{- $_ := set $podPassthroughRoot "resource" $resource.spec.template }}
{{- $podSpec := (include "helm-generic.pod-resource" $podPassthroughRoot | fromYaml) }}
{{- $_ := set $resource.spec.template "spec" $podSpec.spec }}

spec:
  {{- $resource.spec | toYaml | nindent 2 }}
{{- end -}}
