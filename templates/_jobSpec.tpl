{{/*
Default job spec values
*/}}
{{- define "helm-generic.job-spec-overlay" -}}
template:
  metadata:
    {{- include "helm-generic.pod-spec-metadata" . | nindent 4 }}
{{- end -}}

{{/*
Generate the job yaml resource
*/}}
{{- define "helm-generic.job-resource" -}}
{{- $root := . }}
{{- $resource := deepCopy .resource }}
{{- $_ := set $resource "spec" (mustMergeOverwrite (include "helm-generic.job-spec-overlay" $root | fromYaml) $resource.spec) }}

{{- $podPassthroughRoot := deepCopy (omit $root "resource") }}
{{- $_ := set $podPassthroughRoot "resource" $resource.spec.template }}
{{- $podSpec := (include "helm-generic.pod-resource" $podPassthroughRoot | fromYaml) }}
{{- $_ := set $resource.spec.template "spec" $podSpec.spec }}

spec:
  {{- $resource.spec | toYaml | nindent 2 }}
{{- end -}}
