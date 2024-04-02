{{/*
Generate the service yaml resource
*/}}
{{- define "helm-generic.service-resource" -}}
{{- $root := . }}
{{- $resource := deepCopy .resource }}
{{- $spec := omit $resource.spec "selector" }}
spec:
  {{- toYaml $spec| nindent 2 }}
  selector:
    {{- if not (hasKey (default $resource.spec.selector dict) "app.kubernetes.io/name") }}
    {{- include "helm-generic.selectorLabels" $root | nindent 4 }}
    {{- else if eq (get (default $resource.spec.selector dict) "app.kubernetes.io/name" | toString) "<nil>" }}
    {{- $_ := unset $resource.spec.selector "app.kubernetes.io/name" }}
    {{- end }}
    {{- with $resource.spec.selector }}
    {{- . | toYaml | nindent 4 }}
    {{- end }}
{{- end -}}
