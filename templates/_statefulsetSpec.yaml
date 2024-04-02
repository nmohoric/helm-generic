{{/*
Default statefulset spec values
*/}}
{{- define "helm-generic.statefulset-spec-overlay" -}}
replicas: 1
serviceName: {{ include "helm-generic.fullname" . }}
{{- end -}}

{{/*
Generate the statefulset yaml resource
*/}}
{{- define "helm-generic.statefulset-resource" -}}
{{- $root := . }}
{{- $resource := deepCopy .resource }}
{{- $_ := set $resource "spec" (mustMergeOverwrite (include "helm-generic.statefulset-spec-overlay" $root | fromYaml) $resource.spec) }}

{{- $workloadPassthroughRoot := deepCopy (omit $root "resource") }}
{{- $_ := set $workloadPassthroughRoot "resource" $resource }}
{{- $resource := (include "helm-generic.workload-resource" $workloadPassthroughRoot | fromYaml) }}

spec:
  {{- $resource.spec | toYaml | nindent 2 }}
{{- end -}}
