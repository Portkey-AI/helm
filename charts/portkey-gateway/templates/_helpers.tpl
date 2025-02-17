{{/*
Expand the name of the chart.
*/}}
{{- define "portkeyenterprise.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "portkeyenterprise.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
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
{{- define "portkeyenterprise.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "portkeyenterprise.labels" -}}
helm.sh/chart: {{ include "portkeyenterprise.chart" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "portkeyenterprise.selectorLabels" -}}
app.kubernetes.io/name: {{ include "portkeyenterprise.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Gateway labels
*/}}
{{- define "gateway.labels" -}}
{{- include "portkeyenterprise.labels" . | nindent 4 }}
{{- include "portkeyenterprise.selectorLabels" . | nindent 4 }}
{{- end }}

{{/*
Data Service labels
*/}}
{{- define "dataservice.labels" -}}
{{- include "portkeyenterprise.labels" . }}
{{- include "dataservice.selectorLabels" . }}
{{- end }}

{{/*
Data Service Selector labels
*/}}
{{- define "dataservice.selectorLabels" -}}
{{- if hasKey .Values.dataservice.deployment.selectorLabels "app.kubernetes.io/name" }}
app.kubernetes.io/name: {{ get .Values.dataservice.deployment.selectorLabels "app.kubernetes.io/name" }}
{{- else }}
app.kubernetes.io/name: {{ include "portkeyenterprise.name" . }}
{{- end }}
{{- if hasKey .Values.dataservice.deployment.selectorLabels "app.kubernetes.io/instance" }}
app.kubernetes.io/instance: {{ get .Values.dataservice.deployment.selectorLabels "app.kubernetes.io/instance" }}
{{- else }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
{{- if hasKey .Values.dataservice.deployment.selectorLabels "app.kubernetes.io/component" }}
app.kubernetes.io/component: {{ get .Values.dataservice.deployment.selectorLabels "app.kubernetes.io/component" }}
{{- else }}
app.kubernetes.io/component: {{ include "portkeyenterprise.fullname" . }}-{{ .Values.dataservice.name }}
{{- end }}
{{- end }}

{{/*
Common annotations
*/}}
{{- define "portkeyenterprise.annotations" -}}
{{- with .Values.service.annotations }}
{{- toYaml .}}
{{- end }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "portkeyenterprise.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "portkeyenterprise.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "dataservice.serviceAccountName" -}}
{{- if .Values.dataservice.serviceAccount.create -}}
{{ default (printf "%s-%s" (include "portkeyenterprise.fullname" .) .Values.dataservice.name) .Values.dataservice.serviceAccount.name | trunc 63 | trimSuffix "-" }}
{{- else -}}
{{ default "default" .Values.dataservice.serviceAccount.name }}
{{- end -}}
{{- end -}}


{{/*
Create the image pull credentials
Supports both username/password and direct auth token
*/}}
{{- define "imagePullSecret" }}
{{- with . }}
{{- if .auth }}
{{- printf "{\"auths\":{\"%s\":{\"auth\":\"%s\"}}}" .registry .auth | b64enc }}
{{- else }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "redis.labels" -}}
helm.sh/chart: {{ include "portkeyenterprise.chart" . }}
{{ include "redis.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "redis.selectorLabels" -}}
app.kubernetes.io/name: redis
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Vault Annotations
*/}}
{{- define "portkeyenterprise.vaultAnnotations" -}}
{{.Values.vaultConfig.vaultHost}}/agent-inject: "true"
{{.Values.vaultConfig.vaultHost}}/agent-inject-secret-{{ .Chart.Name }}: {{ .Values.vaultConfig.secretPath | quote }}
{{.Values.vaultConfig.vaultHost}}/role: {{ .Values.vaultConfig.role | quote }}
{{- end }}

{{/*
Vault Environment Variables
*/}}
{{- define "portkeyenterprise.vaultEnv" -}}
{{- range $key, $value := .Values.environment.data }}
- name: {{ $key }}
  valueFrom:
    secretKeyRef:
      name: {{ $.Chart.Name }}
      key: {{ $key }}
{{- end }}
{{- end }}

{{/*
Common Environment Env
*/}}
{{- define "portkeyenterprise.commonEnv" -}}
{{- if .Values.useVaultInjection }}
  {{- include "portkeyenterprise.vaultEnv" .}}
{{- else }}
{{- if .Values.environment.create }}
{{- range $key, $value := .Values.environment.data }}
  - name: {{ $key }}
    valueFrom:
      {{- if $.Values.environment.secret }}
      secretKeyRef:
      {{- else }}
      configMapKeyRef:
      {{- end }}
        name: {{ include "portkeyenterprise.fullname" $ }}
        key: {{ $key }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Common Environment Env as Map
*/}}
{{- define "portkeyenterprise.commonEnvMap" -}}
{{- $envMap := dict -}}
{{- if .Values.useVaultInjection }}
  {{- include "portkeyenterprise.vaultEnv" . | fromYaml | merge $envMap -}}
{{- else if .Values.environment.create }}
  {{- range $key, $value := .Values.environment.data }}
    {{- $envValue := dict -}}
    {{- if $.Values.environment.secret }}
      {{- $_ := set $envValue "valueFrom" (dict "secretKeyRef" (dict "name" (include "portkeyenterprise.fullname" $) "key" $key)) -}}
    {{- else }}
      {{- $_ := set $envValue "valueFrom" (dict "configMapKeyRef" (dict "name" (include "portkeyenterprise.fullname" $) "key" $key)) -}}
    {{- end }}
    {{- $_ := set $envMap $key $envValue -}}
  {{- end }}
{{- end }}
{{- $envMap | toYaml -}}
{{- end }}

{{- define "portkeyenterprise.renderEnvVar" -}}
{{- $name := index . 0 -}}
{{- $value := index . 1 -}}
- name: {{ $name }}
{{- if kindIs "map" $value }}
  {{- toYaml $value | nindent 2 }}
{{- else }}
  value: {{ $value | quote }}
{{- end }}
{{- end }}

{{- define "logStore.commonEnv" -}}
{{- $commonEnv := include "portkeyenterprise.commonEnvMap" . | fromYaml -}}
{{- range $key, $value := $commonEnv }}
{{- if has $key (list "LOG_STORE" "MONGO_DB_CONNECTION_URL" "MONGO_DATABASE" "MONGO_COLLECTION_NAME" "MONGO_GENERATION_HOOKS_COLLECTION_NAME" "LOG_STORE_ACCESS_KEY" "LOG_STORE_SECRET_KEY" "LOG_STORE_REGION" "LOG_STORE_GENERATIONS_BUCKET" "LOG_STORE_BASEPATH" "LOG_STORE_AWS_ROLE_ARN" "LOG_STORE_AWS_EXTERNAL_ID" "AZURE_AUTH_MODE" "AZURE_STORAGE_ACCOUNT" "AZURE_STORAGE_KEY" "AZURE_STORAGE_CONTAINER") }}
{{- include "portkeyenterprise.renderEnvVar" (list $key $value) | nindent 0 }}
{{- end }}
{{- end }}
{{- end }}

{{- define "analyticStore.commonEnv" -}}
{{- $commonEnv := include "portkeyenterprise.commonEnvMap" . | fromYaml -}}
{{- range $key, $value := $commonEnv }}
{{- if has $key (list "ANALYTICS_STORE" "ANALYTICS_STORE_ENDPOINT" "ANALYTICS_STORE_USER" "ANALYTICS_STORE_PASSWORD" "ANALYTICS_LOG_TABLE" "ANALYTICS_FEEDBACK_TABLE") }}
{{- include "portkeyenterprise.renderEnvVar" (list $key $value) | nindent 0 }}
{{- end }}
{{- end }}
{{- end }}

{{- define "cacheStore.commonEnv" -}}
{{- $commonEnv := include "portkeyenterprise.commonEnvMap" . | fromYaml -}}
{{- range $key, $value := $commonEnv }}
{{- if has $key (list "CACHE_STORE" "REDIS_URL" "REDIS_TLS_ENABLED" "REDIS_MODE") }}
{{- include "portkeyenterprise.renderEnvVar" (list $key $value) | nindent 0 }}
{{- end }}
{{- end }}
{{- end }}

{{- define "controlPlane.commonEnv" -}}
{{- $commonEnv := include "portkeyenterprise.commonEnvMap" . | fromYaml -}}
{{- range $key, $value := $commonEnv }}
{{- if has $key (list "PORTKEY_CLIENT_AUTH" "ORGANISATIONS_TO_SYNC") }}
{{- include "portkeyenterprise.renderEnvVar" (list $key $value) | nindent 0 }}
{{- end }}
{{- end }}
{{- end }}

{{- define "dataservice.commonEnv" -}}
{{- include "portkeyenterprise.renderEnvVar" (list "PORT" .Values.dataservice.containerPort) | nindent 0 }}
{{- $commonEnv := include "portkeyenterprise.commonEnvMap" . | fromYaml -}}
{{- if hasKey $commonEnv "ALBUS_BASEPATH" -}}
{{- include "portkeyenterprise.renderEnvVar" (list "ALBUS_ENDPOINT" $commonEnv.ALBUS_BASEPATH) | nindent 0 }}
{{- else -}}
{{- include "portkeyenterprise.renderEnvVar" (list "ALBUS_ENDPOINT" "https://albus.portkey.ai") | nindent 0 }}
{{- end -}}
{{- include "portkeyenterprise.renderEnvVar" (list "NODE_ENV" "production") | nindent 0 }}
{{- include "portkeyenterprise.renderEnvVar" (list "HYBRID_DEPLOYMENT" "ON") | nindent 0 }}
{{- if .Values.dataservice.env.DEBUG_ENABLED }}
{{- include "portkeyenterprise.renderEnvVar" (list "NODE_DEBUG" "dataservice:*") | nindent 0 }}
{{- end }}
{{- include "portkeyenterprise.renderEnvVar" (list "SERVICE_NAME" .Values.dataservice.env.SERVICE_NAME) | nindent 0 }}
{{- range $key, $value := $commonEnv }}
{{- if has $key (list "ANALYTICS_STORE" "ANALYTICS_STORE_ENDPOINT" "ANALYTICS_STORE_USER" "ANALYTICS_STORE_PASSWORD" "ANALYTICS_LOG_TABLE" "FINETUNES_BUCKET" "FINETUNES_AWS_ROLE_ARN" "LOG_EXPORTS_BUCKET") }}
{{- include "portkeyenterprise.renderEnvVar" (list $key $value) | nindent 0 }}
{{- end }}
{{- end }}
{{- include "portkeyenterprise.renderEnvVar" (list "CLICKHOUSE_HOST" ($commonEnv.ANALYTICS_STORE_ENDPOINT)) | nindent 0 }}
{{- include "portkeyenterprise.renderEnvVar" (list "CLICKHOUSE_USER" ($commonEnv.ANALYTICS_STORE_USER)) | nindent 0 }}
{{- include "portkeyenterprise.renderEnvVar" (list "CLICKHOUSE_PASSWORD" ($commonEnv.ANALYTICS_STORE_PASSWORD)) | nindent 0 }}
{{- include "portkeyenterprise.renderEnvVar" (list "AWS_S3_FINETUNE_BUCKET" ($commonEnv.FINETUNES_BUCKET)) | nindent 0 }}
{{- end }}