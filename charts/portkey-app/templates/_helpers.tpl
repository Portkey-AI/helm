{{/*
Create the image pull credentials
*/}}
{{- define "imagePullSecret" }}
{{- with . }}
{{- printf "{\"auths\":{\"%s\":{\"username\":\"%s\",\"password\":\"%s\",\"email\":\"%s\",\"auth\":\"%s\"}}}" .registry .username .password .email (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end }}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "portkey.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "portkey.fullname" -}}
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
{{- define "portkey.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "portkey.labels" -}}
{{- if .Values.commonLabels }}
{{ toYaml .Values.commonLabels }}
{{- end }}
helm.sh/chart: {{ include "portkey.chart" . }}
{{ include "portkey.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Common annotations
*/}}
{{- define "portkey.annotations" -}}
{{- if .Values.commonAnnotations }}
{{ toYaml .Values.commonAnnotations }}
{{- end }}
helm.sh/chart: {{ include "portkey.chart" . }}
{{ include "portkey.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "portkey.selectorLabels" -}}
app.kubernetes.io/name: {{ include "portkey.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Name of the secret containing the secrets for this chart. This can be overridden by a secrets file created by
the user or some other secret provisioning mechanism
*/}}
{{- define "portkey.secretsName" -}}
{{- if .Values.config.existingSecretName }}
{{- .Values.config.existingSecretName }}
{{- else }}
{{- include "portkey.fullname" . }}-secrets
{{- end }}
{{- end }}

{{/*
Name of the secret containing the secrets for redis. This can be overridden by a secrets file created by
the user or some other secret provisioning mechanism
*/}}
{{- define "portkey.redisSecretsName" -}}
{{- if .Values.redis.external.existingSecretName }}
{{- .Values.redis.external.existingSecretName }}
{{- else }}
{{- include "portkey.fullname" . }}-{{ .Values.redis.name }}
{{- end }}
{{- end }}

{{/*
Name of the secret containing the secrets for clickhouse. This can be overridden by a secrets file created by
the user or some other secret provisioning mechanism
*/}}
{{- define "portkey.clickhouseSecretsName" -}}
{{- if .Values.clickhouse.external.existingSecretName }}
{{- .Values.clickhouse.external.existingSecretName }}
{{- else }}
{{- include "portkey.fullname" . }}-{{ .Values.clickhouse.name }}
{{- end }}
{{- end }}

{{/*
Name of the secret containing the secrets for mysql. This can be overridden by a secrets file created by
the user or some other secret provisioning mechanism
*/}}
{{- define "portkey.mysqlSecretsName" -}}
{{- if .Values.mysql.external.existingSecretName }}
{{- .Values.mysql.external.existingSecretName }}
{{- else }}
{{- include "portkey.fullname" . }}-{{ .Values.mysql.name }}
{{- end }}
{{- end }}
{{/*
Name of the secret containing the secrets for gateway. This can be overridden by a secrets file created by
the user or some other secret provisioning mechanism
*/}}
{{- define "portkey.gatewaySecretsName" -}}
{{- include "portkey.fullname" . }}-{{ .Values.gateway.name }}
{{- end }}

{{/*
Template containing common environment variables that are used by several services.
*/}}
{{- define "portkey.commonEnv" -}}
- name: REDIS_URL
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.redisSecretsName" . }}
      key: redis_connection_url
- name: REDIS_TLS_ENABLED
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.redisSecretsName" . }}
      key: redis_tls_enabled
- name: REDIS_MODE
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.redisSecretsName" . }}
      key: redis_mode
- name: CACHE_STORE
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.redisSecretsName" . }}
      key: redis_store
- name: CLICKHOUSE_DATABASE
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.clickhouseSecretsName" . }}
      key: clickhouse_db
- name: CLICKHOUSE_HOST
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.clickhouseSecretsName" . }}
      key: clickhouse_host
- name: CLICKHOUSE_PORT
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.clickhouseSecretsName" . }}
      key: clickhouse_port
- name: CLICKHOUSE_NATIVE_PORT
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.clickhouseSecretsName" . }}
      key: clickhouse_native_port
- name: CLICKHOUSE_USER
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.clickhouseSecretsName" . }}
      key: clickhouse_user
- name: CLICKHOUSE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.clickhouseSecretsName" . }}
      key: clickhouse_password
- name: CLICKHOUSE_TLS
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.clickhouseSecretsName" . }}
      key: clickhouse_tls
- name: DB_NAME
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.mysqlSecretsName" . }}
      key: mysql_db
- name: DB_HOST
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.mysqlSecretsName" . }}
      key: mysql_host
- name: DB_PORT
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.mysqlSecretsName" . }}
      key: mysql_port
- name: DB_USER
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.mysqlSecretsName" . }}
      key: mysql_user
- name: DB_PASS
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.mysqlSecretsName" . }}
      key: mysql_password
- name: MYSQL_ROOT_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.mysqlSecretsName" . }}
      key: mysql_root_password

{{- if .Values.config.oauth.enabled }}
- name: AUTH_MODE
  value: "SSO"
- name: OIDC_ISSUER
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.secretsName" . }}
      key: oauthIssuerUrl
- name: OIDC_CLIENTID
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.secretsName" . }}
      key: oauthClientId
- name: OIDC_CLIENT_SECRET
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.secretsName" . }}
      key: oauthClientSecret
- name: OIDC_REDIRECT_URI
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.secretsName" . }}
      key: oauthRedirectURI
- name: JWT_PRIVATE_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.secretsName" . }}
      key: jwtPrivateKey
{{- end }}
{{- if .Values.config.noAuth.enabled }}
- name: AUTH_MODE
  value: "NO_AUTH"
- name: JWT_PRIVATE_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.secretsName" . }}
      key: jwtPrivateKey
{{- end }}

{{- if .Values.config.smtp.enabled }}
- name: SMTP_HOST
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.secretsName" . }}
      key: smtp_host
- name: SMTP_PORT
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.secretsName" . }}
      key: smtp_port
- name: SMTP_USER
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.secretsName" . }}
      key: smtp_user
- name: SMTP_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.secretsName" . }}
      key: smtp_password
- name: SMTP_FROM
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.secretsName" . }}
      key: smtp_from
{{- end }}
{{- end }}

{{- define "logStore.commonEnv" -}}
- name: LOG_STORE
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.gatewaySecretsName" . }}
      key: logStore
{{- if .Values.logStorage.mongo.enabled}}
- name: MONGO_DB_CONNECTION_URL
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.gatewaySecretsName" . }}
      key: mongoConnectionUrl
- name: MONGO_DATABASE
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.gatewaySecretsName" . }}
      key: mongoDatabase
- name: MONGO_COLLECTION_NAME
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.gatewaySecretsName" . }}
      key: mongoGenerationsCollection
- name: MONGO_GENERATION_HOOKS_COLLECTION_NAME
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.gatewaySecretsName" . }}
      key: mongoHooksCollection
{{- end }}
{{- if or .Values.logStorage.s3Compat.enabled .Values.logStorage.s3Assume.enabled }}
- name: LOG_STORE_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.gatewaySecretsName" . }}
      key: logStoreAccessKey
- name: LOG_STORE_SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.gatewaySecretsName" . }}
      key: logStoreSecretKey
- name: LOG_STORE_REGION
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.gatewaySecretsName" . }}
      key: logStoreRegion
- name: LOG_STORE_GENERATIONS_BUCKET
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.gatewaySecretsName" . }}
      key: logStoreGenerationsBucket
- name: LOG_STORE_BASEPATH
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.gatewaySecretsName" . }}
      key: logStoreBasePath
{{- end }}
{{- if .Values.logStorage.s3Assume.enabled }}
- name: LOG_STORE_AWS_ROLE_ARN
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.gatewaySecretsName" . }}
      key: logStoreAwsRoleArn
- name: LOG_STORE_AWS_EXTERNAL_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.gatewaySecretsName" . }}
      key: logStoreExternalId
{{- end }}
{{- if .Values.logStorage.azure.enabled}}
- name: AZURE_AUTH_MODE
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.gatewaySecretsName" . }}
      key: azureAuthMode
- name: AZURE_MANAGED_CLIENT_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.gatewaySecretsName" . }}
      key: azureManagedClientId
- name: AZURE_STORAGE_ACCOUNT
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.gatewaySecretsName" . }}
      key: azureStorageAccount
- name: AZURE_STORAGE_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.gatewaySecretsName" . }}
      key: azureStorageKey
- name: AZURE_STORAGE_CONTAINER
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.gatewaySecretsName" . }}
      key: azureStorageContainer
{{- end }}
{{- end }}

{{- define "gateway.commonEnv" -}}
{{- include "logStore.commonEnv" . }}
{{- if hasKey (include "portkey.gatewaySecretsName" . | fromYaml) "bedrockAssumedAccessKey" }}
- name: AWS_ASSUME_ROLE_ACCESS_KEY_ID
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.gatewaySecretsName" . }}
      key: bedrockAssumedAccessKey
{{- end }}
{{- if hasKey (include "portkey.gatewaySecretsName" . | fromYaml) "bedrockAssumedSecretKey" }}
- name: AWS_ASSUME_ROLE_SECRET_ACCESS_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.gatewaySecretsName" . }}
      key: bedrockAssumedSecretKey
{{- end }}
{{- if hasKey (include "portkey.gatewaySecretsName" . | fromYaml) "bedrockAssumedRegion" }}
- name: AWS_ASSUME_ROLE_REGION
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.gatewaySecretsName" . }}
      key: bedrockAssumedRegion
{{- end }}
- name: ALBUS_BASEPATH
  value: http://{{ include "portkey.fullname" . }}-{{ .Values.backend.name }}:{{ .Values.backend.containerPort }}
- name: ANALYTICS_STORE
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.clickhouseSecretsName" . }}
      key: clickhouse_db
- name: ANALYTICS_STORE_DATABASE
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.clickhouseSecretsName" . }}
      key: clickhouse_db
- name: ANALYTICS_STORE_ENDPOINT
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.clickhouseSecretsName" . }}
      key: clickhouse_host
- name: ANALYTICS_STORE_PORT
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.clickhouseSecretsName" . }}
      key: clickhouse_port
- name: ANALYTICS_STORE_NATIVE_PORT
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.clickhouseSecretsName" . }}
      key: clickhouse_native_port
- name: ANALYTICS_STORE_USER
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.clickhouseSecretsName" . }}
      key: clickhouse_user
- name: ANALYTICS_STORE_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.clickhouseSecretsName" . }}
      key: clickhouse_password
- name: ANALYTICS_STORE_TLS
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.clickhouseSecretsName" . }}
      key: clickhouse_tls
- name: ANALYTICS_LOG_TABLE
  value: "default.generations"
- name: ANALYTICS_FEEDBACK_TABLE
  value: "default.feedbacks"
- name: REDIS_URL
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.redisSecretsName" . }}
      key: redis_connection_url
- name: REDIS_TLS_ENABLED
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.redisSecretsName" . }}
      key: redis_tls_enabled
- name: REDIS_MODE
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.redisSecretsName" . }}
      key: redis_mode
- name: CACHE_STORE
  valueFrom:
    secretKeyRef:
      name: {{ include "portkey.redisSecretsName" . }}
      key: redis_store
{{- end }}

{{- define "backend.serviceAccountName" -}}
{{- if .Values.backend.serviceAccount.create -}}
    {{ default (printf "%s-%s" (include "portkey.fullname" .) .Values.backend.name) .Values.backend.serviceAccount.name | trunc 63 | trimSuffix "-" }}
{{- else -}}
    {{ default "default" .Values.backend.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{- define "dataservice.serviceAccountName" -}}
{{- if .Values.dataservice.serviceAccount.create -}}
    {{ default (printf "%s-%s" (include "portkey.fullname" .) .Values.dataservice.name) .Values.dataservice.serviceAccount.name | trunc 63 | trimSuffix "-" }}
{{- else -}}
    {{ default "default" .Values.dataservice.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{- define "clickhouse.serviceAccountName" -}}
{{- if .Values.clickhouse.serviceAccount.create -}}
    {{ default (printf "%s-%s" (include "portkey.fullname" .) .Values.clickhouse.name) .Values.clickhouse.serviceAccount.name | trunc 63 | trimSuffix "-" }}
{{- else -}}
    {{ default "default" .Values.clickhouse.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{- define "mysql.serviceAccountName" -}}
{{- if .Values.mysql.serviceAccount.create -}}
    {{ default (printf "%s-%s" (include "portkey.fullname" .) .Values.mysql.name) .Values.mysql.serviceAccount.name | trunc 63 | trimSuffix "-" }}
{{- else -}}
    {{ default "default" .Values.mysql.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{- define "frontend.serviceAccountName" -}}
{{- if .Values.frontend.serviceAccount.create -}}
    {{ default (printf "%s-%s" (include "portkey.fullname" .) .Values.frontend.name) .Values.frontend.serviceAccount.name | trunc 63 | trimSuffix "-" }}
{{- else -}}
    {{ default "default" .Values.frontend.serviceAccount.name }}
{{- end -}}
{{- end -}}


{{- define "redis.serviceAccountName" -}}
{{- if .Values.redis.serviceAccount.create -}}
    {{ default (printf "%s-%s" (include "portkey.fullname" .) .Values.redis.name) .Values.redis.serviceAccount.name | trunc 63 | trimSuffix "-" }}
{{- else -}}
    {{ default "default" .Values.redis.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{- define "gateway.serviceAccountName" -}}
{{- if .Values.redis.serviceAccount.create -}}
    {{ default (printf "%s-%s" (include "portkey.fullname" .) .Values.redis.name) .Values.gateway.serviceAccount.name | trunc 63 | trimSuffix "-" }}
{{- else -}}
    {{ default "default" .Values.gateway.serviceAccount.name }}
{{- end -}}
{{- end -}}