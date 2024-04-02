{{/*
Default cronjob spec values
*/}}
{{- define "helm-generic.cronjob-spec-overlay" -}}
jobTemplate: {}
{{- end -}}

{{/*
Generate the cronjob yaml resource
*/}}
{{- define "helm-generic.cronjob-resource" -}}
{{- $root := . }}
{{- $resource := deepCopy .resource }}
{{- $_ := set $resource "spec" (mustMergeOverwrite (include "helm-generic.cronjob-spec-overlay" $root | fromYaml) $resource.spec) }}

{{- $jobPassthroughRoot := deepCopy (omit $root "resource") }}
{{- $_ := set $jobPassthroughRoot "resource" $resource.spec.jobTemplate }}
{{- $jobSpec := (include "helm-generic.job-resource" $jobPassthroughRoot | fromYaml) }}
{{- $_ := set $resource.spec "jobTemplate" $jobSpec }}

spec:
  {{- $resource.spec | toYaml | nindent 2 }}
{{- end -}}
