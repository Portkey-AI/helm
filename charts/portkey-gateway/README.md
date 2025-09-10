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
