# Portkey Gateway Helm Chart

## Prerequisites

[Helm](https://helm.sh) must be installed to use the charts. Please refer to Helm's [documentation](https://helm.sh/docs) to get started.

## Quick Start

### 1. Docker Registry Access
Update your `values.yaml` with the provided Docker credentials:

```yaml
imageCredentials:
- name: portkeyenterpriseregistrycredentials
  create: true
  registry: https://index.docker.io/v1/
  username: <shared by portkey>
  password: <shared by portkey>
```

### 2. Core Configuration
Configure these mandatory fields in your `values.yaml`:

```yaml
environment:
  data:
    SERVICE_NAME: "<shared by portkey>"
    PORTKEY_CLIENT_AUTH: "<shared by portkey>"
    ORGANISATIONS_TO_SYNC: "<shared by portkey>"
```

## Storage Configuration

Choose your storage backends from the options below. You'll need to configure: 

**Analytics Store**
- For storing the LLM requests analytics data

**Log Store** 
- For storing the raw LLM request/response data (including analytics)

**Cache Store**
- Cache configuration

---

## Analytics Store

### Option 1: Control Plane (Recommended)
Simplest setup - no additional configuration needed:
```yaml
ANALYTICS_STORE: control_plane
```

### Option 2: ClickHouse
<details>
<summary>Detailed ClickHouse Analytics Setup</summary>

```yaml
ANALYTICS_STORE: clickhouse
ANALYTICS_STORE_ENDPOINT: "<shared by portkey>"
ANALYTICS_STORE_USER: "<shared by portkey>"
ANALYTICS_STORE_PASSWORD: "<shared by portkey>"
ANALYTICS_LOG_TABLE: "<shared by portkey>"
ANALYTICS_FEEDBACK_TABLE: "<shared by portkey>"
ANALYTICS_GENERATION_HOOKS_TABLE: "<shared by portkey>"
```
</details>

### Additional: OTEL (OpenTelemetry) - Optional
Can be used alongside either option above to push analytics data to OTEL-compatible endpoints:
<details>
<summary>Detailed OTEL Metrics Setup</summary>

```yaml
OTEL_PUSH_ENABLED: true
OTEL_ENDPOINT: "http://localhost:4318"
OTEL_RESOURCE_ATTRIBUTES: "ApplicationShortName=gateway,AssetId=12323"
OTEL_EXPORTER_OTLP_HEADERS: "DD-API_KEY=Bearer asd,x-api-key=test"
OTEL_EXPORTER_OTLP_PROTOCOL: "http/protobuf" # supported values: "http/json"(default if not supplied) and "http/protobuf"
```
</details>

<details>
<summary>`Experimental`: OpenTelemetry Semantic Conventions compatible OTEL Logs setup</summary>
The [Semantic conventions for GenAI Traces](https://opentelemetry.io/docs/specs/semconv/gen-ai/gen-ai-spans/) are still under development hence this feature is experimental

```yaml
EXPERIMENTAL_GEN_AI_OTEL_PUSH_ENABLED: true
EXPERIMENTAL_GEN_AI_OTEL_OTLP_ENDPOINT: https://api.smith.langchain.com/otel
EXPERIMENTAL_GEN_AI_OTEL_OTLP_HEADERS: x-api-key=langsmith-api-key
```
</details>

---

## Log Store

### AWS S3
<details>
<summary> Detailed AWS S3(Long Term Credentials) Setup</summary>

```yaml
LOG_STORE: s3
LOG_STORE_REGION: "us-east-1"
LOG_STORE_ACCESS_KEY: "<AWS Access Key>"
LOG_STORE_SECRET_KEY: "<AWS Secret Key>"
LOG_STORE_GENERATIONS_BUCKET: "<AWS Bucket Name>"
```
</details>

### AWS S3 with Assumed Role
<details>
<summary>Detailed AWS S3 (Assumed Role) Setup</summary>

**Method 1: Long-term Credentials**
```yaml
LOG_STORE: s3_assume
LOG_STORE_REGION: "<AWS Bucket Region>"
LOG_STORE_ACCESS_KEY: "<shared by portkey>"
LOG_STORE_SECRET_KEY: "<shared by portkey>"
LOG_STORE_GENERATIONS_BUCKET: "<AWS Bucket Name>"
LOG_STORE_AWS_ROLE_ARN: "<role arn with bucket access>"
LOG_STORE_AWS_EXTERNAL_ID: "<external id from trust relationship>"
```

**Setup Steps:**
1. Create IAM role with S3 permissions (LOG_STORE_AWS_ROLE_ARN)
2. Set trust relationship with Portkey account
3. Use external ID for security

**AWS Role Setup**

IAM Policy for S3 Access:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": ["arn:aws:s3:::<LOG_STORE_GENERATIONS_BUCKET>", "arn:aws:s3:::<LOG_STORE_GENERATIONS_BUCKET>/*"]
    }
  ]
}
```

Trust Relationship:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "<arn_shared_by_portkey>"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "<LOG_STORE_AWS_EXTERNAL_ID>"
        }
      }
    }
  ]
}
```

**Method 2: EKS IRSA**
```yaml
LOG_STORE: s3_assume
LOG_STORE_REGION: "<AWS Bucket Region>"
LOG_STORE_GENERATIONS_BUCKET: "<AWS Bucket Name>"
```

**Method 3: EC2 Instance Metadata (IMDS)**
```yaml
LOG_STORE: s3_assume
LOG_STORE_REGION: "us-east-1"
LOG_STORE_GENERATIONS_BUCKET: "<AWS Bucket Name>"
AWS_IMDS_V1: true  # Only if using IMDS v1
```
</details>

### Google Cloud Storage
<details>
<summary>Detailed GCS Setup</summary>

- Only the s3 interoperable way of gcs is supported currently.
- Access Key can be generated as mentioned here -
  1. https://cloud.google.com/storage/docs/interoperability
  2. https://cloud.google.com/storage/docs/authentication/hmackeys
- Cloud Storage -> Settings -> Interopability -> Access keys for service accounts -> Create Key for Service Accounts

```yaml
LOG_STORE: gcs
LOG_STORE_REGION: "<GCP Region>"
LOG_STORE_ACCESS_KEY: "<GCP hmac key>"
LOG_STORE_SECRET_KEY: "<GCP hmac secret>"
LOG_STORE_GENERATIONS_BUCKET: "<GCP Bucket Name>"
```
</details>

### Wasabi
<details>
<summary>Detailed Wasabi Setup</summary>

```yaml
LOG_STORE: wasabi
LOG_STORE_REGION: "<Wasabi Region>"
LOG_STORE_ACCESS_KEY: "<Wasabi Access Key>"
LOG_STORE_SECRET_KEY: "<Wasabi Secret Key>"
LOG_STORE_GENERATIONS_BUCKET: "<Wasabi Bucket Name>"
```
</details>

### NetApp
<details>
<summary>Detailed Netapp Setup</summary>

```yaml
LOG_STORE: netapp
LOG_STORE_REGION: "<Netapp Region>"
LOG_STORE_ACCESS_KEY: "<Netapp Access Key>"
LOG_STORE_SECRET_KEY: "<Netapp Secret Key>"
LOG_STORE_BASEPATH: "<Netapp Base Path Including Bucket Name>"
```
</details>

### Custom S3
For Self hosted S3 compliant storage solutions
<details>
<summary>Detailed Custom S3 Setup</summary>

```yaml
LOG_STORE: s3_custom
LOG_STORE_REGION: "<Custom S3 Region>"
LOG_STORE_ACCESS_KEY: "<Custom S3 Access Key>"
LOG_STORE_SECRET_KEY: "<Custom S3 Secret Key>"
LOG_STORE_BASEPATH: "<Custom S3 Base Path Including Bucket Name>"
```
</details>

### Azure Blob Storage
<details>
<summary>Detailed Azure Blob Storage Setup</summary>

**With Storage Key:**
```yaml
LOG_STORE: azure
AZURE_STORAGE_ACCOUNT: "<Azure Storage Account>"
AZURE_STORAGE_KEY: "<Azure Storage Key>" # not required for managed or entra
AZURE_STORAGE_CONTAINER: "<Azure Storage Container>"
```

**With Managed Identity:**
```yaml
LOG_STORE: azure
AZURE_AUTH_MODE: managed
AZURE_STORAGE_ACCOUNT: "<Azure Storage Account>"
AZURE_STORAGE_CONTAINER: "<Azure Storage Container>"
AZURE_MANAGED_CLIENT_ID: "<Azure Managed Client Id>"  # Only for multiple identities
```

**With Entra Identity:**
```yaml
LOG_STORE: azure
AZURE_AUTH_MODE: entra
AZURE_STORAGE_ACCOUNT: "<Azure Storage Account>"
AZURE_STORAGE_CONTAINER: "<Azure Storage Container>"
AZURE_ENTRA_CLIENT_ID: "<Azure Entra Client Id>"
AZURE_ENTRA_CLIENT_SECRET: "<Azure Entra Client Secret>"
AZURE_ENTRA_TENANT_ID: "<Azure Entra Tenant Id>"
```
</details>

### MongoDB
<details>
<summary>Detailed MongoDB setup</summary>

**Simple Setup**
```yaml
LOG_STORE: mongo
MONGO_DB_CONNECTION_URL: "mongodb://user:pass@host:port/db"
MONGO_DATABASE: "<Mongo DB>"
MONGO_COLLECTION_NAME: "<Mongo Collection>"
MONGO_GENERATION_HOOKS_COLLECTION_NAME: "<Mongo Collection for Hooks>"
```

**For PEM file authentication:**
1. Add your PEM file to `resources-config.yaml`
2. Configure volume mounting in `values.yaml`:
```yaml
volumes:
- name: shared-folder
  configMap:
    name: resource-config
volumeMounts:
- name: shared-folder
  mountPath: /etc/shared/document_db.pem
  subPath: document_db.pem
```
</details>

---

## Cache Store

### Redis (In-Cluster)
Simple deployments, development

```yaml
CACHE_STORE: redis
REDIS_URL: "redis://redis:6379"
REDIS_TLS_ENABLED: false
```

### AWS ElastiCache
<details>
<summary>Detailed AWS ElastiCache Setup</summary>

```yaml
CACHE_STORE: aws-elastic-cache
REDIS_URL: "your-elasticache-endpoint"
REDIS_TLS_ENABLED: true
REDIS_MODE: cluster  # Only if using cluster mode
```
</details>

### Custom Redis
<details>
<summary>Detailed Custom Redis Setup</summary>

```yaml
CACHE_STORE: custom
REDIS_URL: "redis://<redis host>:<port>"
REDIS_TLS_ENABLED: false
```
</details>

---

## AWS Bedrock Configuration

For AWS Bedrock integration, configure Assumed Role Access. 

> 📖 **For detailed Bedrock setup instructions, see [Bedrock.md](./docs/Bedrock.md)**

<details>
<summary>Bedrock Assumed Role Setup</summary>

### Quick Setup

**Required IAM Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": "*"
    }
  ]
}
```

### Configuration Options

**With Long-term Credentials:**
```yaml
AWS_ASSUME_ROLE_ACCESS_KEY_ID: "<AWS Access Key>"
AWS_ASSUME_ROLE_SECRET_ACCESS_KEY: "<AWS Secret Key>"
AWS_ASSUME_ROLE_REGION: "<AWS Region>"
```

**With IRSA/IMDS:**
Use the same role configured for log storage.

### Virtual Key Setup
When creating Virtual Keys in Portkey, provide:
- **Bedrock AWS Role ARN**: Your Bedrock-enabled role ARN
- **Bedrock AWS External ID**: (optional) Your external ID
- **Bedrock AWS Region**: Your AWS region

![Bedrock Configuration](resources/bedrock.png)

</details>

---

## Installation

### 1. Add Helm Repository
```bash
helm repo add portkey-ai https://portkey-ai.github.io/helm
helm repo update
```

### 2. Install Chart
```bash
helm upgrade --install portkey-ai portkey-ai/gateway \
  -f ./chart/values.yaml \
  -n portkeyai \
  --create-namespace
```

### 3. Verify Installation
```bash
kubectl get pods -n portkeyai
```

### 4. Local Testing (Optional)
```bash
kubectl port-forward <pod-name> -n portkeyai 8787:8787
```

---

## Data Service (Optional)

Enable data service for 
- Custom fine-tuning 
- Custom batches
- Data exports

```yaml
dataservice:
  enabled: true
```

**Note**: Currently only S3 is supported for fine-tuning data storage.

For detailed fine-tuning information, see [DataService.md](./docs/DataService.md).

---

## Uninstallation

```bash
helm uninstall portkey-gateway --namespace portkeyai
```

---

## Support

For additional help:
- Check the [full configuration reference](values.yaml)
- Review logs: `kubectl logs -n portkeyai deployment/portkey-gateway`
- Contact support(suport@portkey.ai) with your configuration details

---

## Configuration Reference

### Global Parameters

| Parameter | Description | Default | Required | Type |
|-----------|-------------|---------|----------|------|
| `replicaCount` | Number of gateway pod replicas | `1` | Optional | int |
| `nameOverride` | Override the chart name | `""` | Optional | string |
| `fullnameOverride` | Override the full release name | `""` | Optional | string |
| `autoRestart` | Enable automatic pod restarts | `false` | Optional | bool |

### Image Configuration

| Parameter | Description | Default | Required | Type |
|-----------|-------------|---------|----------|------|
| `images.gatewayImage.repository` | Gateway container image repository | `docker.io/portkeyai/gateway_enterprise` | Optional | string |
| `images.gatewayImage.pullPolicy` | Gateway image pull policy | `IfNotPresent` | Optional | string |
| `images.gatewayImage.tag` | Gateway image tag | `1.17.1` | Optional | string |
| `images.dataserviceImage.repository` | Data service container image repository | `docker.io/portkeyai/data-service` | Optional | string |
| `images.dataserviceImage.pullPolicy` | Data service image pull policy | `IfNotPresent` | Optional | string |
| `images.dataserviceImage.tag` | Data service image tag | `1.4.1` | Optional | string |
| `images.redisImage.repository` | Redis container image repository | `docker.io/redis` | Optional | string |
| `images.redisImage.pullPolicy` | Redis image pull policy | `IfNotPresent` | Optional | string |
| `images.redisImage.tag` | Redis image tag | `7.2-alpine` | Optional | string |

### Image Pull Secrets

| Parameter | Description | Default | Required | Type |
|-----------|-------------|---------|----------|------|
| `imagePullSecrets` | List of image pull secret names | `[portkeyenterpriseregistrycredentials]` | Optional | list |
| `imageCredentials[].name` | Name of the image pull secret | `portkeyenterpriseregistrycredentials` | Required | string |
| `imageCredentials[].create` | Create the image pull secret | `true` | Optional | bool |
| `imageCredentials[].registry` | Docker registry URL | `https://index.docker.io/v1/` | Required | string |
| `imageCredentials[].username` | Docker registry username | `<docker-user>` | Required | string |
| `imageCredentials[].password` | Docker registry password | `<docker-pwd>` | Required | string |
| `imageCredentials[].email` | Docker registry email | `""` | Optional | string |
| `imageCredentials[].auth` | Base64 encoded auth token (alternative to username/password) | `""` | Optional | string |

### Vault Integration

| Parameter | Description | Default | Required | Type |
|-----------|-------------|---------|----------|------|
| `useVaultInjection` | Enable HashiCorp Vault injection for secrets | `false` | Optional | bool |
| `vaultConfig.vaultHost` | Vault server hostname | `vault.hashicorp.com` | Optional | string |
| `vaultConfig.secretPath` | Path to secrets in Vault | `path/to/your/secret` | Optional | string |
| `vaultConfig.role` | Vault role for authentication | `your-vault-role` | Optional | string |
| `vaultConfig.kubernetesSecret` | Kubernetes secret for Vault auth | `""` | Optional | string |

### Environment Configuration

| Parameter | Description | Default | Required | Type |
|-----------|-------------|---------|----------|------|
| `environment.create` | Create environment ConfigMap/Secret | `true` | Optional | bool |
| `environment.secret` | Deploy environment as Secret (true) or ConfigMap (false) | `true` | Optional | bool |
| `environment.existingSecret` | Name of existing secret for sensitive values | `""` | Optional | string |
| `environment.secretKeys` | List of keys to pull from external secret | `[]` | Optional | list |

### Environment Data Variables

| Parameter | Description | Default | Required | Type |
|-----------|-------------|---------|----------|------|
| `environment.data.SERVICE_NAME` | Service identifier name | `portkeyenterprise` | Required | string |
| `environment.data.PORT` | Gateway service port | `8787` | Optional | string |
| `environment.data.LOG_STORE` | Log storage backend type (s3, gcs, azure, mongo, etc.) | `""` | Optional | string |
| `environment.data.LOG_STORE_REGION` | Region for log storage | `""` | Optional | string |
| `environment.data.LOG_STORE_ACCESS_KEY` | Access key for log storage | `""` | Optional | string |
| `environment.data.LOG_STORE_SECRET_KEY` | Secret key for log storage | `""` | Optional | string |
| `environment.data.LOG_STORE_GENERATIONS_BUCKET` | Bucket name for generations logs | `""` | Optional | string |
| `environment.data.LOG_STORE_BASEPATH` | Base path for log storage | `""` | Optional | string |
| `environment.data.LOG_STORE_AWS_ROLE_ARN` | AWS IAM role ARN for S3 assumed role | `""` | Optional | string |
| `environment.data.LOG_STORE_AWS_EXTERNAL_ID` | External ID for AWS STS assume role | `""` | Optional | string |
| `environment.data.AWS_ASSUME_ROLE_ACCESS_KEY_ID` | AWS access key for assume role | `""` | Optional | string |
| `environment.data.AWS_ASSUME_ROLE_SECRET_ACCESS_KEY` | AWS secret key for assume role | `""` | Optional | string |
| `environment.data.AWS_ASSUME_ROLE_REGION` | AWS region for assume role | `""` | Optional | string |
| `environment.data.AZURE_AUTH_MODE` | Azure authentication mode (managed, entra) | `""` | Optional | string |
| `environment.data.AZURE_MANAGED_CLIENT_ID` | Azure managed identity client ID | `""` | Optional | string |
| `environment.data.AZURE_STORAGE_ACCOUNT` | Azure storage account name | `""` | Optional | string |
| `environment.data.AZURE_STORAGE_KEY` | Azure storage account key | `""` | Optional | string |
| `environment.data.AZURE_STORAGE_CONTAINER` | Azure storage container name | `""` | Optional | string |
| `environment.data.MONGO_DB_CONNECTION_URL` | MongoDB connection string | `""` | Optional | string |
| `environment.data.MONGO_DATABASE` | MongoDB database name | `""` | Optional | string |
| `environment.data.MONGO_COLLECTION_NAME` | MongoDB collection name | `""` | Optional | string |
| `environment.data.MONGO_GENERATIONS_HOOKS_COLLECTION_NAME` | MongoDB collection for generation hooks | `""` | Optional | string |
| `environment.data.ANALYTICS_STORE` | Analytics storage backend type | `clickhouse` | Optional | string |
| `environment.data.ANALYTICS_STORE_ENDPOINT` | Analytics store endpoint URL | `""` | Optional | string |
| `environment.data.ANALYTICS_STORE_USER` | Analytics store username | `""` | Optional | string |
| `environment.data.ANALYTICS_STORE_PASSWORD` | Analytics store password | `""` | Optional | string |
| `environment.data.ANALYTICS_LOG_TABLE` | Analytics log table name | `""` | Optional | string |
| `environment.data.ANALYTICS_FEEDBACK_TABLE` | Analytics feedback table name | `""` | Optional | string |
| `environment.data.CACHE_STORE` | Cache storage backend type | `redis` | Optional | string |
| `environment.data.REDIS_URL` | Redis connection URL | `redis://redis:6379` | Optional | string |
| `environment.data.REDIS_TLS_ENABLED` | Enable TLS for Redis connections | `false` | Optional | string |
| `environment.data.REDIS_MODE` | Redis mode (cluster, standalone) | `""` | Optional | string |
| `environment.data.PORTKEY_CLIENT_AUTH` | Portkey client authentication token | `""` | Required | string |
| `environment.data.ORGANISATIONS_TO_SYNC` | Organization IDs to sync | `""` | Required | string |
| `environment.data.FINETUNES_BUCKET` | S3 bucket for fine-tuning data | `""` | Optional | string |
| `environment.data.LOG_EXPORTS_BUCKET` | S3 bucket for log exports | `""` | Optional | string |
| `environment.data.FINETUNES_AWS_ROLE_ARN` | AWS role ARN for fine-tuning bucket access | `""` | Optional | string |
| `environment.data.SERVER_MODE` | Server mode configuration | `""` | Optional | string |
| `environment.data.MCP_PORT` | MCP (Model Context Protocol) service port | `8788` | Optional | string |
| `environment.data.MCP_GATEWAY_BASE_URL` | MCP gateway base URL | `""` | Optional | string |

### Service Account

| Parameter | Description | Default | Required | Type |
|-----------|-------------|---------|----------|------|
| `serviceAccount.create` | Create a service account | `true` | Optional | bool |
| `serviceAccount.automount` | Automount service account API credentials | `true` | Optional | bool |
| `serviceAccount.annotations` | Annotations for the service account | `{}` | Optional | object |
| `serviceAccount.name` | Service account name (auto-generated if empty) | `""` | Optional | string |

### Pod Configuration

| Parameter | Description | Default | Required | Type |
|-----------|-------------|---------|----------|------|
| `podAnnotations` | Annotations for gateway pods | `{}` | Optional | object |
| `podLabels` | Labels for gateway pods | `{}` | Optional | object |
| `podSecurityContext` | Security context for pods | `{}` | Optional | object |
| `securityContext` | Security context for containers | `{}` | Optional | object |
| `nodeSelector` | Node selector for pod scheduling | `{}` | Optional | object |
| `tolerations` | Tolerations for pod scheduling | `[]` | Optional | list |
| `affinity` | Affinity rules for pod scheduling | `{}` | Optional | object |
| `topologySpreadConstraints` | Topology spread constraints for pods | `[]` | Optional | list |
| `hostAlias` | Host aliases for pod DNS resolution | `[]` | Optional | list |
| `extraContainerConfig` | Additional container configuration | `{}` | Optional | object |

### Service Configuration

| Parameter | Description | Default | Required | Type |
|-----------|-------------|---------|----------|------|
| `service.type` | Kubernetes service type | `NodePort` | Optional | string |
| `service.port` | Service port | `8787` | Optional | int |
| `service.additionalLabels` | Additional labels for the service | `{}` | Optional | object |
| `service.annotations` | Annotations for the service | `{}` | Optional | object |

### Ingress Configuration

| Parameter | Description | Default | Required | Type |
|-----------|-------------|---------|----------|------|
| `ingress.enabled` | Enable ingress resource | `false` | Optional | bool |
| `ingress.hostname` | Ingress hostname | `""` | Required (if enabled) | string |
| `ingress.ingressClassName` | Ingress class name | `nginx` | Optional | string |
| `ingress.annotations` | Ingress annotations | `{}` | Optional | object |
| `ingress.labels` | Ingress labels | `{}` | Optional | object |
| `ingress.tls` | TLS configuration for ingress | `[]` | Optional | list |
| `ingress.hostBased` | Use host-based routing (true) or path-based routing (false) | `false` | Optional | bool |
| `ingress.mcpHostname` | MCP hostname for host-based routing | `""` | Optional | string |
| `ingress.mcpPath` | MCP path for path-based routing | `/mcp` | Optional | string |
| `ingress.gatewayPath` | Gateway path for path-based routing | `/` | Optional | string |

### Resource Management

| Parameter | Description | Default | Required | Type |
|-----------|-------------|---------|----------|------|
| `resources` | CPU/Memory resource requests and limits | `{}` | Optional | object |
| `resources.limits.cpu` | CPU limit | `undefined` | Optional | string |
| `resources.limits.memory` | Memory limit | `undefined` | Optional | string |
| `resources.requests.cpu` | CPU request | `undefined` | Optional | string |
| `resources.requests.memory` | Memory request | `undefined` | Optional | string |

### Health Probes

| Parameter | Description | Default | Required | Type |
|-----------|-------------|---------|----------|------|
| `livenessProbe.httpGet.path` | Liveness probe HTTP path | `/v1/health` | Optional | string |
| `livenessProbe.httpGet.port` | Liveness probe HTTP port | `8787` | Optional | int |
| `livenessProbe.initialDelaySeconds` | Initial delay before liveness probe | `5` | Optional | int |
| `livenessProbe.periodSeconds` | Period between liveness probes | `60` | Optional | int |
| `livenessProbe.timeoutSeconds` | Timeout for liveness probe | `3` | Optional | int |
| `livenessProbe.failureThreshold` | Failure threshold for liveness probe | `3` | Optional | int |
| `readinessProbe.httpGet.path` | Readiness probe HTTP path | `/v1/health` | Optional | string |
| `readinessProbe.httpGet.port` | Readiness probe HTTP port | `8787` | Optional | int |
| `readinessProbe.initialDelaySeconds` | Initial delay before readiness probe | `5` | Optional | int |
| `readinessProbe.periodSeconds` | Period between readiness probes | `60` | Optional | int |
| `readinessProbe.timeoutSeconds` | Timeout for readiness probe | `3` | Optional | int |
| `readinessProbe.successThreshold` | Success threshold for readiness probe | `1` | Optional | int |
| `readinessProbe.failureThreshold` | Failure threshold for readiness probe | `3` | Optional | int |

### Autoscaling (HPA)

| Parameter | Description | Default | Required | Type |
|-----------|-------------|---------|----------|------|
| `autoscaling.enabled` | Enable Horizontal Pod Autoscaler | `false` | Optional | bool |
| `autoscaling.minReplicas` | Minimum number of replicas | `2` | Optional | int |
| `autoscaling.maxReplicas` | Maximum number of replicas | `20` | Optional | int |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU utilization for scaling | `60` | Optional | int |
| `autoscaling.targetMemoryUtilizationPercentage` | Target memory utilization for scaling | `60` | Optional | int |
| `autoscaling.behavior.scaleUp.stabilizationWindowSeconds` | Stabilization window for scale up | `0` | Optional | int |
| `autoscaling.behavior.scaleUp.podScaleUpValue` | Pods to add per scale up | `2` | Optional | int |
| `autoscaling.behavior.scaleUp.percentScaleUpValue` | Percentage to scale up | `100` | Optional | int |
| `autoscaling.behavior.scaleUp.periodSeconds` | Period for scale up evaluation | `2` | Optional | int |
| `autoscaling.behavior.scaleDown.stabilizationWindowSeconds` | Stabilization window for scale down | `300` | Optional | int |
| `autoscaling.behavior.scaleDown.podScaleDownValue` | Pods to remove per scale down | `1` | Optional | int |
| `autoscaling.behavior.scaleDown.periodSeconds` | Period for scale down evaluation | `60` | Optional | int |

### Volume Configuration

| Parameter | Description | Default | Required | Type |
|-----------|-------------|---------|----------|------|
| `volumes` | Additional volumes to mount on the deployment | `[]` | Optional | list |
| `volumeMounts` | Additional volume mounts for the container | `[]` | Optional | list |

### Data Service Configuration

| Parameter | Description | Default | Required | Type |
|-----------|-------------|---------|----------|------|
| `dataservice.name` | Data service name | `dataservice` | Optional | string |
| `dataservice.enabled` | Enable data service deployment | `false` | Optional | bool |
| `dataservice.containerPort` | Data service container port | `8081` | Optional | int |
| `dataservice.finetuneBucket` | S3 bucket for fine-tuning | `""` | Optional | string |
| `dataservice.logexportsBucket` | S3 bucket for log exports | `""` | Optional | string |
| `dataservice.env.DEBUG_ENABLED` | Enable debug mode | `false` | Optional | bool |
| `dataservice.env.SERVICE_NAME` | Data service name | `portkeyenterprise-dataservice` | Optional | string |
| `dataservice.deployment.autoRestart` | Enable auto restart for data service | `true` | Optional | bool |
| `dataservice.deployment.replicas` | Number of data service replicas | `1` | Optional | int |
| `dataservice.deployment.labels` | Labels for data service deployment | `{}` | Optional | object |
| `dataservice.deployment.selectorLabels` | Selector labels for data service | `{}` | Optional | object |
| `dataservice.deployment.annotations` | Annotations for data service deployment | `{}` | Optional | object |
| `dataservice.deployment.podSecurityContext` | Pod security context for data service | `{}` | Optional | object |
| `dataservice.deployment.securityContext` | Container security context for data service | `{}` | Optional | object |
| `dataservice.deployment.resources` | Resource requests/limits for data service | `{}` | Optional | object |
| `dataservice.deployment.extraEnv` | Additional environment variables | `[]` | Optional | list |
| `dataservice.deployment.extraContainerConfig` | Additional container configuration | `{}` | Optional | object |
| `dataservice.deployment.topologySpreadConstraints` | Topology spread constraints | `[]` | Optional | list |
| `dataservice.deployment.nodeSelector` | Node selector for scheduling | `{}` | Optional | object |
| `dataservice.deployment.tolerations` | Tolerations for scheduling | `[]` | Optional | list |
| `dataservice.deployment.affinity` | Affinity rules for scheduling | `{}` | Optional | object |
| `dataservice.deployment.volumes` | Additional volumes | `[]` | Optional | list |
| `dataservice.deployment.volumeMounts` | Additional volume mounts | `[]` | Optional | list |
| `dataservice.deployment.hostAlias` | Host aliases for DNS resolution | `[]` | Optional | list |
| `dataservice.service.type` | Data service Kubernetes service type | `ClusterIP` | Optional | string |
| `dataservice.service.port` | Data service port | `8081` | Optional | int |
| `dataservice.service.labels` | Service labels | `{}` | Optional | object |
| `dataservice.service.annotations` | Service annotations | `{}` | Optional | object |
| `dataservice.service.loadBalancerSourceRanges` | Load balancer source ranges | `[]` | Optional | list |
| `dataservice.service.loadBalancerIP` | Static IP for load balancer | `""` | Optional | string |
| `dataservice.serviceAccount.create` | Create service account for data service | `true` | Optional | bool |
| `dataservice.serviceAccount.name` | Service account name | `""` | Optional | string |
| `dataservice.serviceAccount.labels` | Service account labels | `{}` | Optional | object |
| `dataservice.serviceAccount.annotations` | Service account annotations | `{}` | Optional | object |
| `dataservice.autoscaling.enabled` | Enable HPA for data service | `false` | Optional | bool |
| `dataservice.autoscaling.createHpa` | Create HPA resource | `false` | Optional | bool |
| `dataservice.autoscaling.minReplicas` | Minimum replicas | `1` | Optional | int |
| `dataservice.autoscaling.maxReplicas` | Maximum replicas | `5` | Optional | int |
| `dataservice.autoscaling.targetCPUUtilizationPercentage` | Target CPU utilization | `80` | Optional | int |
| `dataservice.autoscaling.targetMemoryUtilizationPercentage` | Target memory utilization | `80` | Optional | int |

### Data Service Health Probes

| Parameter | Description | Default | Required | Type |
|-----------|-------------|---------|----------|------|
| `dataservice.deployment.startupProbe.httpGet.path` | Startup probe path | `/health` | Optional | string |
| `dataservice.deployment.startupProbe.httpGet.port` | Startup probe port | `8081` | Optional | int |
| `dataservice.deployment.startupProbe.initialDelaySeconds` | Startup probe initial delay | `60` | Optional | int |
| `dataservice.deployment.startupProbe.failureThreshold` | Startup probe failure threshold | `3` | Optional | int |
| `dataservice.deployment.startupProbe.periodSeconds` | Startup probe period | `10` | Optional | int |
| `dataservice.deployment.startupProbe.timeoutSeconds` | Startup probe timeout | `1` | Optional | int |
| `dataservice.deployment.livenessProbe.httpGet.path` | Liveness probe path | `/health` | Optional | string |
| `dataservice.deployment.livenessProbe.httpGet.port` | Liveness probe port | `8081` | Optional | int |
| `dataservice.deployment.livenessProbe.failureThreshold` | Liveness probe failure threshold | `3` | Optional | int |
| `dataservice.deployment.livenessProbe.periodSeconds` | Liveness probe period | `10` | Optional | int |
| `dataservice.deployment.livenessProbe.timeoutSeconds` | Liveness probe timeout | `1` | Optional | int |
| `dataservice.deployment.readinessProbe.httpGet.path` | Readiness probe path | `/health` | Optional | string |
| `dataservice.deployment.readinessProbe.httpGet.port` | Readiness probe port | `8081` | Optional | int |
| `dataservice.deployment.readinessProbe.failureThreshold` | Readiness probe failure threshold | `3` | Optional | int |
| `dataservice.deployment.readinessProbe.periodSeconds` | Readiness probe period | `10` | Optional | int |
| `dataservice.deployment.readinessProbe.timeoutSeconds` | Readiness probe timeout | `1` | Optional | int |

### Redis Configuration

| Parameter | Description | Default | Required | Type |
|-----------|-------------|---------|----------|------|
| `redis.name` | Redis service name | `redis` | Optional | string |
| `redis.containerPort` | Redis container port | `6379` | Optional | int |
| `redis.resources` | Resource requests/limits for Redis | `{}` | Optional | object |
