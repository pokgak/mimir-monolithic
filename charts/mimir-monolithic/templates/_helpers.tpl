{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "mimir.name" -}}
{{- default "mimir" .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mimir.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Calculate the gateway url
*/}}
{{- define "mimir.gatewayUrl" -}}
{{- if eq (include "mimir.gateway.isEnabled" . ) "true" -}}
http://{{ include "mimir.gateway.service.name" . }}.{{ .Release.Namespace }}.svc:{{ .Values.gateway.service.port | default (include "mimir.serverHttpListenPort" . ) }}
{{- else -}}
http://{{ template "mimir.fullname" . }}-nginx.{{ .Release.Namespace }}.svc:{{ .Values.nginx.service.port }}
{{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "mimir.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Calculate image name based on whether enterprise features are requested
*/}}
{{- define "mimir.imageReference" -}}
{{- if .Values.enterprise.enabled -}}{{ .Values.enterprise.image.repository }}:{{ .Values.enterprise.image.tag }}{{- else -}}{{ .Values.image.repository }}:{{ .Values.image.tag }}{{- end -}}
{{- end -}}

{{/*
For compatibility and to support upgrade from enterprise-metrics chart calculate minio bucket name
*/}}
{{- define "mimir.minioBucketPrefix" -}}
{{- if .Values.enterprise.legacyLabels -}}enterprise-metrics{{- else -}}mimir{{- end -}}
{{- end -}}

{{/*
Create the name of the general service account
*/}}
{{- define "mimir.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "mimir.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create the name of the ruler service account
*/}}
{{- define "mimir.ruler.serviceAccountName" -}}
{{- if and .Values.ruler.serviceAccount.create (eq .Values.ruler.serviceAccount.name "") -}}
{{- $sa := default (include "mimir.fullname" .) .Values.serviceAccount.name }}
{{- printf "%s-%s" $sa "ruler" }}
{{- else if and .Values.ruler.serviceAccount.create (not (eq .Values.ruler.serviceAccount.name "")) -}}
{{- .Values.ruler.serviceAccount.name -}}
{{- else -}}
{{- include "mimir.serviceAccountName" . -}}
{{- end -}}
{{- end -}}

{{/*
Create the app name for clients. Defaults to the same logic as "mimir.fullname", and default client expects "prometheus".
*/}}
{{- define "client.name" -}}
{{- if .Values.client.name -}}
{{- .Values.client.name -}}
{{- else if .Values.client.fullnameOverride -}}
{{- .Values.client.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default "prometheus" .Values.client.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Calculate the config from structured and unstructured text input
*/}}
{{- define "mimir.calculatedConfig" -}}
{{ tpl (mergeOverwrite (include "mimir.unstructuredConfig" . | fromYaml) .Values.mimir.structuredConfig | toYaml) . }}
{{- end -}}

{{/*
Calculate the config from the unstructured text input
*/}}
{{- define "mimir.unstructuredConfig" -}}
{{ include (print .Template.BasePath "/_config-render.tpl") . }}
{{- end -}}

{{/*
The volume to mount for mimir configuration
*/}}
{{- define "mimir.configVolume" -}}
configMap:
  name: {{ template "mimir.fullname" . }}
  items:
    - key: "mimir.yaml"
      path: "mimir.yaml"
{{- end -}}

{{/*
Internal servers http listen port - derived from Mimir default
*/}}
{{- define "mimir.serverHttpListenPort" -}}
{{ (((.Values.mimir).structuredConfig).server).http_listen_port | default "8080" }}
{{- end -}}

{{/*
Internal servers grpc listen port - derived from Mimir default
*/}}
{{- define "mimir.serverGrpcListenPort" -}}
{{ (((.Values.mimir).structuredConfig).server).grpc_listen_port | default "9095" }}
{{- end -}}

{{/*
Alertmanager cluster bind address
*/}}
{{- define "mimir.alertmanagerClusterBindAddress" -}}
{{- if (include "mimir.calculatedConfig" . | fromYaml).alertmanager -}}
{{ (include "mimir.calculatedConfig" . | fromYaml).alertmanager.cluster_bind_address | default "" }}
{{- end -}}
{{- end -}}

{{- define "mimir.chunksCacheAddress" -}}
dns+{{ template "mimir.fullname" . }}-chunks-cache.{{ .Release.Namespace }}.svc:{{ (index .Values "chunks-cache").port }}
{{- end -}}

{{- define "mimir.indexCacheAddress" -}}
dns+{{ template "mimir.fullname" . }}-index-cache.{{ .Release.Namespace }}.svc:{{ (index .Values "index-cache").port }}
{{- end -}}

{{- define "mimir.metadataCacheAddress" -}}
dns+{{ template "mimir.fullname" . }}-metadata-cache.{{ .Release.Namespace }}.svc:{{ (index .Values "metadata-cache").port }}
{{- end -}}

{{- define "mimir.resultsCacheAddress" -}}
dns+{{ template "mimir.fullname" . }}-results-cache.{{ .Release.Namespace }}.svc:{{ (index .Values "results-cache").port }}
{{- end -}}

{{- define "mimir.adminCacheAddress" -}}
dns+{{ template "mimir.fullname" . }}-admin-cache.{{ .Release.Namespace }}.svc:{{ (index .Values "admin-cache").port }}
{{- end -}}

{{/*
Memberlist bind port
*/}}
{{- define "mimir.memberlistBindPort" -}}
{{ (((.Values.mimir).structuredConfig).memberlist).bind_port | default "7946" }}
{{- end -}}

{{/*
Resource name template
*/}}
{{- define "mimir.resourceName" -}}
{{- $resourceName := include "mimir.fullname" . -}}
{{- end -}}

{{/*
Resource labels
*/}}
{{- define "mimir.labels" -}}
helm.sh/chart: {{ include "mimir.chart" . }}
app.kubernetes.io/name: {{ include "mimir.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- if .memberlist }}
app.kubernetes.io/part-of: memberlist
{{- end }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
POD labels
*/}}
{{- define "mimir.podLabels" -}}
helm.sh/chart: {{ include "mimir.chart" . }}
app.kubernetes.io/name: {{ include "mimir.name" . }}
app.kubernetes.io/instance: {{.Release.Name }}
app.kubernetes.io/version: {{.Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{.Release.Service }}
{{- if .memberlist }}
app.kubernetes.io/part-of: memberlist
{{- end }}
{{- end -}}

{{/*
POD annotations
*/}}
{{- define "mimir.podAnnotations" -}}
checksum/config: {{ include (print .Template.BasePath "/mimir-config.yaml") . | sha256sum }}
{{- with.Values.global.podAnnotations }}
{{ toYaml . }}
{{- end }}
{{- end -}}

{{/*
Service selector labels
*/}}
{{- define "mimir.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mimir.name" . }}
app.kubernetes.io/instance: {{.Release.Name }}
{{- end -}}


{{/*
Alertmanager http prefix
*/}}
{{- define "mimir.alertmanagerHttpPrefix" -}}
{{- if (include "mimir.calculatedConfig" . | fromYaml).api }}
{{- (include "mimir.calculatedConfig" . | fromYaml).api.alertmanager_http_prefix | default "/alertmanager" -}}
{{- else -}}
{{- print "/alertmanager" -}}
{{- end -}}
{{- end -}}


{{/*
Prometheus http prefix
*/}}
{{- define "mimir.prometheusHttpPrefix" -}}
{{- if (include "mimir.calculatedConfig" . | fromYaml).api }}
{{- (include "mimir.calculatedConfig" . | fromYaml).api.prometheus_http_prefix | default "/prometheus" -}}
{{- else -}}
{{- print "/prometheus" -}}
{{- end -}}
{{- end -}}

{{/*
KEDA Autoscaling Prometheus address
*/}}
{{- define "mimir.kedaPrometheusAddress" -}}
{{- if not.Values.kedaAutoscaling.prometheusAddress -}}
{{ include "mimir.metaMonitoring.metrics.remoteReadUrl" . }}
{{- else -}}
{{.Values.kedaAutoscaling.prometheusAddress }}
{{- end -}}
{{- end -}}


{{/*
Cluster name that shows up in dashboard metrics
*/}}
{{- define "mimir.clusterName" -}}
{{ (include "mimir.calculatedConfig" . | fromYaml).cluster_name | default .Release.Name }}
{{- end -}}

{{/* Allow KubeVersion to be overridden. */}}
{{- define "mimir.kubeVersion" -}}
  {{- default .Capabilities.KubeVersion.Version .Values.kubeVersionOverride -}}
{{- end -}}

{{/* Get API Versions */}}
{{- define "mimir.podDisruptionBudget.apiVersion" -}}
  {{- if semverCompare ">= 1.21-0" (include "mimir.kubeVersion" .) -}}
    {{- print "policy/v1" -}}
  {{- else -}}
    {{- print "policy/v1beta1" -}}
  {{- end -}}
{{- end -}}


{{/*
Calculate annotations
*/}}
{{- define "mimir.componentAnnotations" -}}
{{- $componentSection := include "mimir.componentSectionFromName" . | fromYaml -}}
{{ toYaml $componentSection.annotations }}
{{- end -}}


{{/*
Return the Vault Agent pod annotations if enabled and required by the component
mimir.vaultAgent.annotations takes 2 arguments
  = the root context of the chart
  .component = the name of the component
*/}}
{{- define "mimir.vaultAgent.annotations" -}}
{{- $vaultEnabledComponents := dict
  "admin-api" true
  "alertmanager" true
  "compactor" true
  "distributor" true
  "gateway" true
  "ingester" true
  "overrides-exporter" true
  "querier" true
  "query-frontend" true
  "query-scheduler" true
  "ruler" true
  "store-gateway" true
-}}
{{- if hasKey $vaultEnabledComponents .component }}
vault.hashicorp.com/agent-inject: 'true'
vault.hashicorp.com/role: '{{.Values.vaultAgent.roleName }}'
vault.hashicorp.com/agent-inject-secret-client.crt: '{{.Values.vaultAgent.clientCertPath }}'
vault.hashicorp.com/agent-inject-secret-client.key: '{{.Values.vaultAgent.clientKeyPath }}'
vault.hashicorp.com/agent-inject-secret-server.crt: '{{.Values.vaultAgent.serverCertPath }}'
vault.hashicorp.com/agent-inject-secret-server.key: '{{.Values.vaultAgent.serverKeyPath }}'
vault.hashicorp.com/agent-inject-secret-root.crt: '{{.Values.vaultAgent.caCertPath }}'
{{- end}}
{{- end -}}

{{/*
Get the no_auth_tenant from the configuration
*/}}
{{- define "mimir.noAuthTenant" -}}
{{- (include "mimir.calculatedConfig" . | fromYaml).no_auth_tenant | default "anonymous" -}}
{{- end -}}

{{/*
Return if we should create a PodSecurityPolicy. Takes into account user values and supported kubernetes versions.
*/}}
{{- define "mimir.rbac.usePodSecurityPolicy" -}}
{{- and
      (
        or (semverCompare "< 1.24-0" (include "mimir.kubeVersion" .))
           (and (semverCompare "< 1.25-0" (include "mimir.kubeVersion" .)) .Values.rbac.forcePSPOnKubernetes124)
      )
      (and .Values.rbac.create (eq .Values.rbac.type "psp"))
-}}
{{- end -}}

{{/*
Return if we should create a SecurityContextConstraints. Takes into account user values and supported openshift versions.
*/}}
{{- define "mimir.rbac.useSecurityContextConstraints" -}}
{{- and .Values.rbac.create (eq .Values.rbac.type "scc") -}}
{{- end -}}

{{- define "mimir.remoteWriteUrl.inCluster" -}}
{{ include "mimir.gatewayUrl" . }}/api/v1/push
{{- end -}}

{{- define "mimir.remoteReadUrl.inCluster" -}}
{{ include "mimir.gatewayUrl" . }}{{ include "mimir.prometheusHttpPrefix" . }}

{{- end -}}


{{- define "mimir.var_dump" -}}
{{- . | mustToPrettyJson | printf "\nThe JSON output of the dumped var is: \n%s" | fail }}
{{- end -}}


{{/*
siToBytes is used to convert Kubernetes byte units to bytes.
Works for a sub set of SI suffixes: m, k, M, G, T, and their power-of-two equivalents: Ki, Mi, Gi, Ti.

mimir.siToBytes takes 1 argument
  .value = the input value with SI unit
*/}}
{{- define "mimir.siToBytes" -}}
    {{- if (hasSuffix "Ki" .value) -}}
        {{- trimSuffix "Ki" .value | float64 | mul 1024 | ceil | int64 -}}
    {{- else if (hasSuffix "Mi" .value) -}}
        {{- trimSuffix "Mi" .value | float64 | mul 1048576 | ceil | int64 -}}
    {{- else if (hasSuffix "Gi" .value) -}}
        {{- trimSuffix "Gi" .value | float64 | mul 1073741824 | ceil | int64 -}}
    {{- else if (hasSuffix "Ti" .value) -}}
        {{- trimSuffix "Ti" .value | float64 | mul 1099511627776 | ceil | int64 -}}
    {{- else if (hasSuffix "k" .value) -}}
        {{- trimSuffix "k" .value | float64 | mul 1000 | ceil | int64 -}}
    {{- else if (hasSuffix "M" .value) -}}
        {{- trimSuffix "M" .value | float64 | mul 1000000 | ceil | int64 -}}
    {{- else if (hasSuffix "G" .value) -}}
        {{- trimSuffix "G" .value | float64 | mul 1000000000 | ceil | int64 -}}
    {{- else if (hasSuffix "T" .value) -}}
        {{- trimSuffix "T" .value | float64 | mul 1000000000000 | ceil | int64 -}}
    {{- else if (hasSuffix "m" .value) -}}
        {{- trimSuffix "m" .value | float64 | mulf 0.001 | ceil | int64 -}}
    {{- else -}}
        {{- .value }}
    {{- end -}}
{{- end -}}

{{/*
parseCPU is used to convert Kubernetes CPU units to the corresponding float value of CPU cores.
The returned value is a string representation. If you need to do any math on it, please parse the string first.

mimir.parseCPU takes 1 argument
  .value = the Kubernetes CPU request value
*/}}
{{- define "mimir.parseCPU" -}}
    {{- $value_string := .value | toString -}}
    {{- if (hasSuffix "m" $value_string) -}}
        {{ trimSuffix "m" $value_string | float64 | mulf 0.001 -}}
    {{- else -}}
        {{- $value_string }}
    {{- end -}}
{{- end -}}
