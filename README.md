# Generalized template chart for generic helm deployment

Unopinionated helper Helm chart to render resources in a concise manner for tooling that supports Helm.

## Background

Since tooling like ArgoCD and Flux needs repositories to render loose kubernetes resources, there is no easy way to simply deploy managed resources without creating a custom chart. This chart fills that gap by providing simple inline definition of resources that can be managed by helm without a custom chart.

## Installing the Chart

```bash
helm install my-release --values my-values.yaml oci://ghcr.io/weikinhuang/helm-generic
```

## Usage

This Helm chart can be used to deploy any kubernetes resource, with special accommodations for the kubernetes [`PodSpec`](https://kubernetes.io/docs/reference/kubernetes-api/workload-resources/pod-v1/#PodSpec).

In order to use this chart, you would deploy it as you would any other Helm chart. Check out the [`values.yaml`](./values.yaml) file for basic parameters, and the [`test/values.yaml`](./test/values.yaml) file for an example.

## How it works

This chart iterates through the `.resources` list and attempts to render each resource by overlaying default and common values. Each resource item can be _any_ kubernetes manifest. After each resource is compiled, it is passed through the helm template engine, so keys/values can contain helm template functions.

### Per resource iteration

For each resource, there are 2 additional helper keys.

| Name        | Description                                                                                                                                                 |
| :---------- | :---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `loop`      | If set, the template will perform an additional iteration cycle on this specific resource. Additional variables `._loopKey` and `._loopValues` are exposed. |
| `condition` | When using `.loop`, this is a helm templated string that will skip rendering the manifest if it prints anything other than true.                            |

### Metadata

The `metadata` key is fully templated before any checks for the `condition` and the rendering of the remainder of the resource manifest.

These are the fields that are rendered:

```yaml
metadata:
  annotations:
    ...: merged list of .resource.metadata.annotations and .Values.commonAnnotations
  labels:
    helm.sh/chart: '{{ include "helm-generic.chart" . }}'
    app.kubernetes.io/managed-by: "{{ .Release.Service }}"
    app.kubernetes.io/name: '{{ include "helm-generic.name" . }}'
    app.kubernetes.io/instance: "{{ .Release.Name }}"
    ...: merged list of .resource.metadata.labels and .Values.commonLabels
  name: metadata.name if set, defaults to '{{ include "helm-generic.fullname" . }}'
  namespace: if not a known cluster resource, metadata.namespace if set, defaults to '{{ .Release.Namespace }}'
  ...: remaining keys in .resource.metadata
```

> To explicitly unset the namespace key, set the value to `~` or `null`.

These a keys are available to use in the `.condition` key when using `.loop`. The full metadata is also when rendering the rest of the manifest.

### Resource Example

```bash
helm template --namespace test --generate-name --values ./values.yaml oci://ghcr.io/weikinhuang/helm-generic
```

Example `values.yaml`:

```yaml
resources:
  - apiVersion: v1
    kind: Namespace
    metadata:
      name: "{{ .Release.Namespace }}"
  - apiVersion: v1
    kind: Service
    spec:
      type: ClusterIP
  - apiVersion: v1
    kind: ConfigMap
    metadata:
      name: '{{ include "helm-generic.fullname" . }}-{{ ._loopValues.k }}'
    data:
      foo: "{{ ._loopValues.k }}"
      key2: |-
        {{- .Files.Get "test/test-file.txt" | nindent 4 }}
    _condition: "{{ eq ._loopKey 1 }}"
    _loop:
      - k: loopvar1
      - k: loopvar2
  - apiVersion: apps/v1
    kind: DaemonSet
    spec:
      template:
        spec:
          containers:
            - name: foo
            - name: bar
              image: "foo:12"
```

Will render:

```yaml
---
# Source: helm-generic/templates/resources.yaml
apiVersion: v1
kind: Namespace
metadata:
  labels:
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: release-name
    helm.sh/chart: helm-generic-1.3.0
  name: test
---
# Source: helm-generic/templates/serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: release-name
  namespace: test
  labels:
    helm.sh/chart: helm-generic-1.3.0
    app.kubernetes.io/name: release-name
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/managed-by: Helm
---
# Source: helm-generic/templates/resources.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  labels:
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: release-name
    helm.sh/chart: helm-generic-1.3.0
  name: release-name-loopvar1
  namespace: test
data:
  foo: "loopvar2"
  key2: "
    hello world
    foo
    bar
    baz
    "
---
# Source: helm-generic/templates/resources.yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: release-name
    helm.sh/chart: helm-generic-1.3.0
  name: release-name
  namespace: test
spec:
  selector:
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/name: release-name
  type: ClusterIP
---
# Source: helm-generic/templates/resources.yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  labels:
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: release-name
    helm.sh/chart: helm-generic-1.3.0
  name: release-name-foo
  namespace: test
spec:
  selector:
    matchLabels:
      app.kubernetes.io/instance: release-name
      app.kubernetes.io/name: release-name
  template:
    metadata:
      labels:
        app.kubernetes.io/instance: release-name
        app.kubernetes.io/name: release-name
    spec:
      containers:
        - image: example:123-alpine
          name: foo
          securityContext:
            runAsNonRoot: true
        - image: foo:12
          name: bar
          securityContext:
            runAsNonRoot: true
      enableServiceLinks: false
      serviceAccountName: release-name
```

### Special cases

#### Service `.spec.selector`

`Service` manifests will automatically render with the default `.spec.selector` set to:

```yaml
spec:
  selector:
    app.kubernetes.io/name: '{{ include "helm-generic.name" . }}'
    app.kubernetes.io/instance: "{{ .Release.Name }}"
```

> To skip rendering the default selector labels, set `.spec.selector['app.kubernetes.io/name']` to `~` or `null` or any other value.

#### PodSpec `containers` and `initContainers`

When defining resources that container `PodSpecs` (ex. `DaemonSet`, `Deployment`, `Job`, etc.). The `container` and `initContainer` keys can either be a _array_ or a _map_. When it is defined as a map, the container name will automatically be set to the `key` if it is not defined.

## Helpers and variables

### Variables available in resource templates

| Name                 | Description                                                                     |
| :------------------- | :------------------------------------------------------------------------------ |
| `.`                  | This is the standard Helm root object                                           |
| `._loopKey`          | When using `.resources[].loop`, the key/index is exposed in this top level key. |
| `._loopValues`       | When using `.resources[].loop`, the values are exposed in this top level key.   |
| `._resourceIndex`    | The key/index of the current kubernetes resource from `.Values.resources`       |
| `.resource`          | The currently processed kubernetes resource from `.Values.resources`            |
| `.resource.metadata` | The fully rendered metadata of the current resource                             |

### Helm template helpers

These are common helpers that are included in `helm init`.

| Name                                                | Description                                            |
| :-------------------------------------------------- | :----------------------------------------------------- |
| `{{ include "helm-generic.chart" . }}`              | The chart name and version as used by the chart label. |
| `{{ include "helm-generic.fullname" . }}`           | The default fully qualified app name.                  |
| `{{ include "helm-generic.name" . }}`               | Expand the name of the chart.                          |
| `{{ include "helm-generic.serviceAccountName" . }}` | The name of the default service account to use.        |

### Selector labels

The default `selector` labels commonly used by helm charts is generated as follows:

```yaml
app.kubernetes.io/name: '{{ include "helm-generic.name" . }}'
app.kubernetes.io/instance: "{{ .Release.Name }}"
```

## Parameters

| Name                         | Description                                                                                                         | Default value  |
| :--------------------------- | :------------------------------------------------------------------------------------------------------------------ | :------------- |
| `image.repository`           | The default image repository for container specs                                                                    | `""`           |
| `image.pullPolicy`           | The default image pull policy for container specs                                                                   | `IfNotPresent` |
| `image.tag`                  | The default image tag for container specs                                                                           | `""`           |
| `nameOverride`               | String to partially override common.names.fullname template (will maintain the release name)                        | `""`           |
| `fullnameOverride`           | String to fully override common.names.fullname template                                                             | `""`           |
| `serviceAccount.create`      | Specifies whether a ServiceAccount should be created, this is automatically attached to PodSpecs if not overridden  | `true`         |
| `serviceAccount.annotations` | Annotations for generated service account                                                                           | `{}`           |
| `serviceAccount.name`        | Name of the service account to use. If not set and create is true, a name is generated using the fullname template. | `""`           |
| `commonAnnotations`          | List of annotations for _all_ generated resources                                                                   | `{}`           |
| `commonLabels`               | List of labels for _all_ generated resources                                                                        | `{}`           |
| `podAnnotations`             | List of annotations for generated PodSpec resources                                                                 | `{}`           |
| `podLabels`                  | List of labels for generated PodSpec resources                                                                      | `{}`           |
| `defaultPodSpec`             | Default values for all PodSpec resources                                                                            | `{}`           |
| `defaultContainerSpec`       | Default values for all Container specs                                                                              | `{}`           |
| `resources`                  | List of resources that will get rendered with processing. Can be a array or a map.                                  | `[]`           |
| `rawResources`               | List of resources that will get rendered without any auto-generated overlays. Can be a array or a map.              | `[]`           |
