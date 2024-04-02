{{/*
Expand the name of the chart.
*/}}
{{- define "helm-generic.name" -}}
{{- default .Release.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "helm-generic.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Release.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "helm-generic.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "helm-generic.labels" -}}
helm.sh/chart: {{ include "helm-generic.chart" . }}
{{ include "helm-generic.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "helm-generic.commonLabels" -}}
{{- with .Values.commonLabels }}
{{- toYaml . }}
{{- end }}
{{- end }}

{{/*
{{- end }}

{{/*
Selector labels
*/}}
{{- define "helm-generic.selectorLabels" -}}
app.kubernetes.io/name: {{ include "helm-generic.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "helm-generic.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "helm-generic.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Scope for namespaced resources
@see kubectl api-resources | grep ' false '
*/}}
{{- define "helm-generic.resource-metadata-has-namespace" -}}
{{- $root := . }}
{{- $apiVersion := .resource.apiVersion }}
{{- $kind := .resource.kind }}
{{- $metadata := deepCopy (default dict .resource.metadata) }}
{{- if
  or
    (and (eq $apiVersion "v1") (eq $kind "ComponentStatus"))
    (and (eq $apiVersion "v1") (eq $kind "Namespace"))
    (and (eq $apiVersion "v1") (eq $kind "Node"))
    (and (eq $apiVersion "v1") (eq $kind "PersistentVolume"))
    (and (eq $apiVersion "admissionregistration.k8s.io/v1") (eq $kind "MutatingWebhookConfiguration"))
    (and (eq $apiVersion "admissionregistration.k8s.io/v1") (eq $kind "ValidatingWebhookConfiguration"))
    (and (eq $apiVersion "apiextensions.k8s.io/v1") (eq $kind "CustomResourceDefinition"))
    (and (eq $apiVersion "apiregistration.k8s.io/v1") (eq $kind "APIService"))
    (and (eq $apiVersion "argoproj.io/v1alpha1") (eq $kind "ClusterWorkflowTemplate"))
    (and (eq $apiVersion "authentication.k8s.io/v1") (eq $kind "SelfSubjectReview"))
    (and (eq $apiVersion "authentication.k8s.io/v1") (eq $kind "TokenReview"))
    (and (eq $apiVersion "authorization.k8s.io/v1") (eq $kind "SelfSubjectAccessReview"))
    (and (eq $apiVersion "authorization.k8s.io/v1") (eq $kind "SelfSubjectRulesReview"))
    (and (eq $apiVersion "authorization.k8s.io/v1") (eq $kind "SubjectAccessReview"))
    (and (eq $apiVersion "cert-manager.io/v1") (eq $kind "ClusterIssuer"))
    (and (eq $apiVersion "certificates.k8s.io/v1") (eq $kind "CertificateSigningRequest"))
    (and (eq $apiVersion "cilium.io/v2alpha1") (eq $kind "CiliumBGPPeeringPolicy"))
    (and (eq $apiVersion "cilium.io/v2alpha1") (eq $kind "CiliumCIDRGroup"))
    (and (eq $apiVersion "cilium.io/v2") (eq $kind "CiliumClusterwideNetworkPolicy"))
    (and (eq $apiVersion "cilium.io/v2") (eq $kind "CiliumExternalWorkload"))
    (and (eq $apiVersion "cilium.io/v2") (eq $kind "CiliumIdentity"))
    (and (eq $apiVersion "cilium.io/v2alpha1") (eq $kind "CiliumL2AnnouncementPolicy"))
    (and (eq $apiVersion "cilium.io/v2alpha1") (eq $kind "CiliumLoadBalancerIPPool"))
    (and (eq $apiVersion "cilium.io/v2") (eq $kind "CiliumNode"))
    (and (eq $apiVersion "cilium.io/v2alpha1") (eq $kind "CiliumPodIPPool"))
    (and (eq $apiVersion "external-secrets.io/v1beta1") (eq $kind "ClusterExternalSecret"))
    (and (eq $apiVersion "external-secrets.io/v1beta1") (eq $kind "ClusterSecretStore"))
    (and (eq $apiVersion "flowcontrol.apiserver.k8s.io/v1") (eq $kind "FlowSchema"))
    (and (eq $apiVersion "flowcontrol.apiserver.k8s.io/v1") (eq $kind "PriorityLevelConfiguration"))
    (and (eq $apiVersion "metrics.k8s.io/v1beta1") (eq $kind "NodeMetrics"))
    (and (eq $apiVersion "networking.k8s.io/v1") (eq $kind "IngressClass"))
    (and (eq $apiVersion "nfd.k8s-sigs.io/v1alpha1") (eq $kind "NodeFeatureRule"))
    (and (eq $apiVersion "node.k8s.io/v1") (eq $kind "RuntimeClass"))
    (and (eq $apiVersion "rbac.authorization.k8s.io/v1") (eq $kind "ClusterRoleBinding"))
    (and (eq $apiVersion "rbac.authorization.k8s.io/v1") (eq $kind "ClusterRole"))
    (and (eq $apiVersion "scheduling.k8s.io/v1") (eq $kind "PriorityClass"))
    (and (eq $apiVersion "storage.k8s.io/v1") (eq $kind "CSIDriver"))
    (and (eq $apiVersion "storage.k8s.io/v1") (eq $kind "CSINode"))
    (and (eq $apiVersion "storage.k8s.io/v1") (eq $kind "StorageClass"))
    (and (eq $apiVersion "storage.k8s.io/v1") (eq $kind "VolumeAttachment"))
-}}
false
{{- else -}}
true
{{- end -}}
{{- end }}

{{/*
Spec metadata
*/}}
{{- define "helm-generic.resource-metadata" -}}
{{- $root := . }}
{{- $metadata := deepCopy (default dict .resource.metadata) }}

{{- with (mustMerge dict (default dict $metadata.annotations) (default dict $root.Values.commonAnnotations)) }}
annotations:
  {{- . | toYaml | nindent 2 }}
{{- end }}
labels:
  {{- include "helm-generic.labels" $root | nindent 2 }}
  {{- include "helm-generic.commonLabels" $root | nindent 2 }}
  {{- with $metadata.labels }}
  {{- . | toYaml | nindent 2 }}
  {{- end }}

name: {{ tpl (default (include "helm-generic.fullname" $root) (default dict $metadata).name) $root }}

{{- $namespace := (tpl (default $root.Release.Namespace (default dict $metadata).namespace) $root) }}
{{- if and (hasKey $metadata "namespace") (eq (get $metadata "namespace" | toString) "<nil>") }}
{{- $namespace = "" }}
{{- end }}
{{- if and $namespace (eq (include "helm-generic.resource-metadata-has-namespace" $root) "true") }}
namespace: {{ $namespace }}
{{- end }}

{{- with (omit $metadata "annotations" "labels" "name" "namespace") }}
{{ . | toYaml }}
{{- end }}
{{- end }}
