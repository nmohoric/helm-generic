{{/*
Default pod metadata
*/}}
{{- define "helm-generic.pod-spec-metadata" -}}
{{- with (mustMerge dict (default dict .Values.podAnnotations) (default dict .Values.commonAnnotations)) }}
annotations:
  {{- toYaml . | nindent 2 }}
{{- end }}
labels:
  {{- include "helm-generic.selectorLabels" . | nindent 2 }}
  {{- include "helm-generic.commonLabels" . | nindent 2 }}
  {{- with .Values.podLabels }}
  {{- toYaml . | nindent 2 }}
  {{- end }}
{{- end -}}

{{/*
Default pod spec values
*/}}
{{- define "helm-generic.pod-spec-overlay" -}}
{{- with .Values.imagePullSecrets }}
imagePullSecrets:
  {{- . | toYaml | nindent 2 }}
{{- end }}
serviceAccountName: {{ include "helm-generic.serviceAccountName" . }}
{{- end -}}

{{/*
Default image name
*/}}
{{- define "helm-generic.pod-container-image-name" -}}
{{ .Values.image.repository }}:{{ .Values.image.tag | default "latest" }}
{{- end -}}

{{/*
Pod container template
*/}}
{{- define "helm-generic.pod-container" -}}
{{- $root := omit . "_container" "_key" }}
{{- $container := deepCopy ._container }}
{{- $key := ._key }}

{{- $container := mustMergeOverwrite dict $root.Values.defaultContainerSpec $container }}

{{- $_ := set $container "name" (default $key $container.name) }}
{{- $_ := set $container "image" (default (include "helm-generic.pod-container-image-name" $root) $container.image) }}

{{- toYaml $container }}
{{- end -}}

{{/*
Overlay container spec
*/}}
{{- define "helm-generic.pod-containers" -}}
{{- $root := omit . "_containers" }}
{{- $containers := ._containers }}

containers:
{{- range $key, $container := $containers }}
  {{- $passthroughRoot := deepCopy $root }}
  {{- $_ := set $passthroughRoot "_container" $container }}
  {{- $_ := set $passthroughRoot "_key" $key }}

  - # placeholder for container {{ $key }}
    {{- include "helm-generic.pod-container" $passthroughRoot | nindent 4 }}
{{- end }}
{{- end -}}

{{/*
Generate the pod yaml resource
*/}}
{{- define "helm-generic.pod-resource" -}}
{{- $root := . }}
{{- $resource := deepCopy .resource }}
{{- $_ := set $resource "spec" (mustMergeOverwrite (include "helm-generic.pod-spec-overlay" $root | fromYaml) $root.Values.defaultPodSpec $resource.spec) }}

{{- range $key := tuple "initContainers" "containers" }}
{{- if hasKey $resource.spec $key }}
{{- $containers := get $resource.spec $key }}
{{- $_ := unset $resource.spec $key }}
{{- $passthroughRoot := deepCopy $root }}
{{- $_ := set $passthroughRoot "_containers" $containers }}

{{- $renderedContainers := (include "helm-generic.pod-containers" $passthroughRoot | fromYaml).containers }}
{{- $_ := set $resource.spec $key $renderedContainers }}
{{- end }}
{{- end }}

spec:
  {{- $resource.spec | toYaml | nindent 2 }}
{{- end -}}
