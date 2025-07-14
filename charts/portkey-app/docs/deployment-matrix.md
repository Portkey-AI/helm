# Portkey Enterprise Deployment Guide

## Table of Contents
1. [Architecture Overview](#architecture-overview)
2. [Deployment Configurations](#deployment-configurations)
3. [Configuration Matrix](#configuration-matrix)
4. [Installation Guide](#installation-guide)
5. [Configuration Templates](#configuration-templates)
6. [AWS IRSA Configuration](#aws-irsa-configuration)
7. [Post-Deployment](#post-deployment)
8. [Troubleshooting](#troubleshooting)

## Architecture Overview

Portkey is a comprehensive AI/LLM operations platform consisting of the following components:

### Core Services
- **AI Gateway** (Port 8787): Central hub for routing AI requests to LLM services
- **Backend Service** (Port 8080): REST API server for business logic and data management
- **Frontend Service** (Port 80): React-based web UI served via nginx
- **Data Service** (Port 8081): Handles data exports, custom batches and finetuning

### Storage Components
- **MySQL** (Port 3306): Relational database for structured data
- **Redis** (Port 6379): In-memory cache and session storage
- **ClickHouse** (Port 8123/9000): Analytics datastore
- **Blob Storage**: Object storage for LLM transactional logs (S3, Azure, MongoDB)

## Deployment Configurations

### 1. Quick Start (Development)
**Use Case**: Development, testing, proof of concept
- All services deployed internally in Kubernetes
- No authentication (noAuth enabled)
- Local storage volumes
- Single replica for all services

### 2. Production (Internal Storage)
**Use Case**: Production with managed internal databases
- All services deployed in Kubernetes
- OAuth authentication enabled
- Persistent volumes for storage
- Auto-scaling enabled
- Resource limits configured

### 3. Production (External Storage)
**Use Case**: Production with external managed databases
- Application services in Kubernetes
- External RDS/CloudSQL for MySQL
- External Redis/ElastiCache
- External ClickHouse
- External blob storage (S3/Azure/GCS)

### 4. Hybrid Deployment
**Use Case**: Mixed internal/external services
- Gateway can be deployed separately
- Some storage internal, some external
- Gradual migration scenarios

### 5. AWS IRSA Deployment
**Use Case**: AWS EKS with IAM Roles for Service Accounts
- No AWS credentials in configuration
- Service accounts annotated with IAM roles
- Enhanced security through temporary credentials

## Configuration Matrix

| Component | Internal Option | External Options | Configuration Section |
|-----------|----------------|------------------|---------------------|
| **MySQL** | StatefulSet in K8s | RDS, CloudSQL, Azure DB | `mysql.external` |
| **Redis** | StatefulSet in K8s | ElastiCache, Azure Redis | `redis.external` |
| **ClickHouse** | StatefulSet in K8s | ClickHouse Cloud, Self-hosted | `clickhouse.external` |
| **Blob Storage** | - | S3, Azure Blob, GCS, MongoDB | `logStorage` |
| **Authentication** | noAuth | OAuth (Google, OIDC, SAML) | `config.oauth` |
| **Ingress** | LoadBalancer | nginx, ALB, Traefik | `ingress` |
| **AWS Access** | Access Keys | IRSA (Recommended) | Service Account annotations |

### Log Storage Options

| Storage Type | Configuration | Use Case |
|--------------|--------------|----------|
| **S3 Compatible** | `logStorage.s3Compat` | AWS S3, MinIO, R2, Wasabi |
| **S3 with AssumeRole** | `logStorage.s3Assume` | Cross-account S3 access |
| **S3 with IRSA** | Service Account + Region | AWS EKS with IAM roles |
| **Azure Blob** | `logStorage.azure` | Azure environments |
| **MongoDB** | `logStorage.mongo` | MongoDB Atlas, DocumentDB |

## Installation Guide

### Prerequisites
- Kubernetes cluster (1.19+)
- Helm 3.x
- kubectl configured
- Docker registry credentials (provided by Portkey)
- For AWS IRSA: EKS cluster with OIDC provider configured

### Step 1: Add Helm Repository
```bash
helm repo add portkey-ai https://portkey-ai.github.io/helm
helm repo update
```

### Step 2: Create Namespace
```bash
kubectl create namespace portkey
```

### Step 3: Configure values.yaml
Choose from the templates below based on your deployment type.

### Step 4: Install Chart
```bash
helm install portkey portkey-ai/app -n portkey -f values.yaml
```

## Configuration Templates

### Template 1: Quick Start (Development)
```yaml
# Basic development setup with no auth and internal storage
imageCredentials:
  - name: portkeyenterpriseregistrycredentials
    username: "YOUR_USERNAME"
    password: "YOUR_PASSWORD"

images:
  backendImage:
    tag: "latest"
  frontendImage:
    tag: "latest"
  dataserviceImage:
    tag: "latest"
  gatewayImage:
    tag: "latest"

config:
  jwtPrivateKey: "dev-secret-key-change-in-production"
  noAuth:
    enabled: true
  logStore: ""

ingress:
  enabled: true
  hostname: "portkey-dev.yourdomain.com"

# All storage services use internal defaults
mysql:
  external:
    enabled: false
redis:
  external:
    enabled: false
clickhouse:
  external:
    enabled: false
```

### Template 2: Production with S3 and Internal Databases
```yaml
imageCredentials:
  - name: portkeyenterpriseregistrycredentials
    username: "YOUR_USERNAME"
    password: "YOUR_PASSWORD"

config:
  jwtPrivateKey: "SECURE_RANDOM_STRING_HERE"
  noAuth:
    enabled: false
  oauth:
    enabled: true
    oauthType: "oidc"
    oauthClientId: "YOUR_CLIENT_ID"
    oauthClientSecret: "YOUR_CLIENT_SECRET"
    oauthRedirectURI: "https://portkey.yourdomain.com/auth/callback"

logStorage:
  logStore: "s3"
  s3Compat:
    enabled: true
    LOG_STORE_ACCESS_KEY: "YOUR_ACCESS_KEY"
    LOG_STORE_SECRET_KEY: "YOUR_SECRET_KEY"
    LOG_STORE_REGION: "us-west-2"
    LOG_STORE_GENERATIONS_BUCKET: "portkey-logs"

ingress:
  enabled: true
  hostname: "portkey.yourdomain.com"
  ingressClassName: "nginx"
  tls:
    - secretName: portkey-tls
      hosts:
        - portkey.yourdomain.com

# Production scaling
backend:
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70

gateway:
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 20
    targetCPUUtilizationPercentage: 60

# Persistent storage for databases
mysql:
  statefulSet:
    persistence:
      enabled: true
      size: 50Gi
      storageClassName: "gp3"
    resources:
      limits:
        cpu: 2000m
        memory: 4Gi

redis:
  statefulSet:
    persistence:
      enabled: true
      size: 10Gi
    resources:
      limits:
        cpu: 1000m
        memory: 2Gi

clickhouse:
  statefulSet:
    persistence:
      enabled: true
      size: 100Gi
    resources:
      limits:
        cpu: 2000m
        memory: 8Gi
```

### Template 3: Production with External Services
```yaml
imageCredentials:
  - name: portkeyenterpriseregistrycredentials
    username: "YOUR_USERNAME"
    password: "YOUR_PASSWORD"

config:
  jwtPrivateKey: "SECURE_RANDOM_STRING_HERE"
  oauth:
    enabled: true
    oauthType: "oidc"
    oauthClientId: "YOUR_CLIENT_ID"
    oauthClientSecret: "YOUR_CLIENT_SECRET"

logStorage:
  logStore: "s3"
  s3Compat:
    enabled: true
    LOG_STORE_ACCESS_KEY: "YOUR_ACCESS_KEY"
    LOG_STORE_SECRET_KEY: "YOUR_SECRET_KEY"
    LOG_STORE_REGION: "us-west-2"
    LOG_STORE_GENERATIONS_BUCKET: "portkey-logs"

# External MySQL (RDS)
mysql:
  external:
    enabled: true
    host: "portkey-db.cluster-xyz.us-west-2.rds.amazonaws.com"
    port: "3306"
    user: "portkey"
    password: "SECURE_PASSWORD"
    database: "portkey"
    ssl:
      enabled: true
      mode: "Amazon RDS"

# External Redis (ElastiCache)
redis:
  external:
    enabled: true
    connectionUrl: "redis://portkey-cache.xyz.cache.amazonaws.com:6379"
    tlsEnabled: "true"

# External ClickHouse
clickhouse:
  external:
    enabled: true
    host: "clickhouse.yourdomain.com"
    port: "8123"
    user: "portkey"
    password: "SECURE_PASSWORD"
    database: "portkey"
    tls: true
```

### Template 4: Azure Environment
```yaml
imageCredentials:
  - name: portkeyenterpriseregistrycredentials
    username: "YOUR_USERNAME"
    password: "YOUR_PASSWORD"

config:
  jwtPrivateKey: "SECURE_RANDOM_STRING_HERE"
  oauth:
    enabled: true
    oauthType: "oidc"
    oauthClientId: "YOUR_AZURE_CLIENT_ID"
    oauthClientSecret: "YOUR_AZURE_CLIENT_SECRET"
    oauthIssuerUrl: "https://login.microsoftonline.com/YOUR_TENANT_ID/v2.0"

logStorage:
  logStore: "azure"
  azure:
    enabled: true
    AZURE_AUTH_MODE: "managed"
    AZURE_STORAGE_ACCOUNT: "portkeylogstorage"
    AZURE_STORAGE_CONTAINER: "generations"

mysql:
  external:
    enabled: true
    host: "portkey-mysql.mysql.database.azure.com"
    port: "3306"
    user: "portkey@portkey-mysql"
    password: "SECURE_PASSWORD"
    database: "portkey"
    ssl:
      enabled: true

redis:
  external:
    enabled: true
    connectionUrl: "rediss://portkey-redis.redis.cache.windows.net:6380"
    tlsEnabled: "true"
```

### Template 5: Multi-Gateway Deployment
```yaml
# Main application without gateway
gateway:
  enabled: false

# External gateway configuration
config:
  defaultGatewayURL: "https://gateway.yourdomain.com"

# Rest of configuration same as other templates...
```

### Template 6: AWS EKS with IRSA (Recommended for AWS)
```yaml
imageCredentials:
  - name: portkeyenterpriseregistrycredentials
    username: "YOUR_USERNAME"
    password: "YOUR_PASSWORD"

config:
  jwtPrivateKey: "SECURE_RANDOM_STRING_HERE"
  noAuth:
    enabled: false
  oauth:
    enabled: true
    oauthType: "oidc"
    oauthClientId: "YOUR_CLIENT_ID"
    oauthClientSecret: "YOUR_CLIENT_SECRET"
    oauthRedirectURI: "https://portkey.yourdomain.com/auth/callback"

# S3 Log Storage with IRSA (No AWS credentials needed)
logStorage:
  logStore: "s3"
  s3Compat:
    enabled: true
    # No access keys needed with IRSA
    LOG_STORE_REGION: "us-west-2"
    LOG_STORE_GENERATIONS_BUCKET: "portkey-logs"
    LOG_STORE_BASEPATH: "generations/"

# Bedrock with IRSA (No AWS credentials needed)
bedrockAssumed:
  enabled: true
  # No access keys needed with IRSA
  AWS_ASSUME_ROLE_REGION: "us-west-2"

# Service Account configurations with IRSA
backend:
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT_ID:role/portkey-backend-role"

gateway:
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT_ID:role/portkey-gateway-role"

dataservice:
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT_ID:role/portkey-dataservice-role"

frontend:
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT_ID:role/portkey-frontend-role"

# External MySQL (RDS)
mysql:
  external:
    enabled: true
    host: "portkey-db.cluster-xyz.us-west-2.rds.amazonaws.com"
    port: "3306"
    user: "portkey"
    password: "SECURE_PASSWORD"
    database: "portkey"
    ssl:
      enabled: true
      mode: "Amazon RDS"

# External Redis (ElastiCache)
redis:
  external:
    enabled: true
    connectionUrl: "redis://portkey-cache.xyz.cache.amazonaws.com:6379"
    tlsEnabled: "false"

ingress:
  enabled: true
  hostname: "portkey.yourdomain.com"
  ingressClassName: "alb"
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
```

## AWS IRSA Configuration

### Prerequisites for IRSA Setup

1. **EKS Cluster with OIDC Provider**
   ```bash
   # Check if OIDC provider exists
   aws eks describe-cluster --name YOUR_CLUSTER_NAME --query "cluster.identity.oidc.issuer"
   
   # Create OIDC provider if not exists
   eksctl utils associate-iam-oidc-provider --cluster YOUR_CLUSTER_NAME --approve
   ```

2. **Create IAM Roles for Each Service**

   **S3 Access Policy** (for backend, gateway, dataservice):
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Action": [
           "s3:GetObject",
           "s3:PutObject",
           "s3:DeleteObject",
           "s3:ListBucket"
         ],
         "Resource": [
           "arn:aws:s3:::portkey-logs",
           "arn:aws:s3:::portkey-logs/*"
         ]
       }
     ]
   }
   ```

   **Bedrock Access Policy** (for gateway):
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

   **Trust Policy Template**:
   ```json
   {
     "Version": "2012-10-17",
     "Statement": [
       {
         "Effect": "Allow",
         "Principal": {
           "Federated": "arn:aws:iam::ACCOUNT_ID:oidc-provider/oidc.eks.REGION.amazonaws.com/id/OIDC_ID"
         },
         "Action": "sts:AssumeRoleWithWebIdentity",
         "Condition": {
           "StringEquals": {
             "oidc.eks.REGION.amazonaws.com/id/OIDC_ID:sub": "system:serviceaccount:portkey:SERVICE_ACCOUNT_NAME"
           }
         }
       }
     ]
   }
   ```

3. **Create IAM Roles Using eksctl**
   ```bash
   # Backend service role
   eksctl create iamserviceaccount \
     --name portkey-backend \
     --namespace portkey \
     --cluster YOUR_CLUSTER_NAME \
     --attach-policy-arn arn:aws:iam::ACCOUNT_ID:policy/portkey-s3-policy \
     --approve
   
   # Gateway service role (with Bedrock access)
   eksctl create iamserviceaccount \
     --name portkey-gateway \
     --namespace portkey \
     --cluster YOUR_CLUSTER_NAME \
     --attach-policy-arn arn:aws:iam::ACCOUNT_ID:policy/portkey-s3-policy \
     --attach-policy-arn arn:aws:iam::ACCOUNT_ID:policy/portkey-bedrock-policy \
     --approve
   
   # Dataservice role
   eksctl create iamserviceaccount \
     --name portkey-dataservice \
     --namespace portkey \
     --cluster YOUR_CLUSTER_NAME \
     --attach-policy-arn arn:aws:iam::ACCOUNT_ID:policy/portkey-s3-policy \
     --approve
   ```

### IRSA Configuration Benefits

- **Enhanced Security**: No long-lived AWS credentials stored in Kubernetes
- **Automatic Credential Rotation**: AWS handles credential lifecycle
- **Fine-grained Permissions**: Each service gets only the permissions it needs
- **Audit Trail**: All AWS API calls are logged with the specific role used

### Template 7: Complete IRSA Setup with Secrets Manager
```yaml
imageCredentials:
  - name: portkeyenterpriseregistrycredentials
    username: "YOUR_USERNAME"
    password: "YOUR_PASSWORD"

config:
  jwtPrivateKey: "SECURE_RANDOM_STRING_HERE"
  oauth:
    enabled: true
    oauthType: "oidc"
    oauthClientId: "YOUR_CLIENT_ID"
    oauthClientSecret: "YOUR_CLIENT_SECRET"
    oauthRedirectURI: "https://portkey.yourdomain.com/auth/callback"

# S3 with IRSA
logStorage:
  logStore: "s3"
  s3Compat:
    enabled: true
    LOG_STORE_REGION: "us-west-2"
    LOG_STORE_GENERATIONS_BUCKET: "portkey-logs"

# Bedrock with IRSA
bedrockAssumed:
  enabled: true
  AWS_ASSUME_ROLE_REGION: "us-west-2"

# External services using Secrets Manager (with IRSA)
mysql:
  external:
    enabled: true
    host: "portkey-db.cluster-xyz.us-west-2.rds.amazonaws.com"
    port: "3306"
    user: "portkey"
    database: "portkey"
    existingSecretName: "portkey-mysql-secret"  # Managed by External Secrets Operator
    ssl:
      enabled: true

redis:
  external:
    enabled: true
    existingSecretName: "portkey-redis-secret"  # Managed by External Secrets Operator

# Service Accounts with IRSA annotations
backend:
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT_ID:role/portkey-backend-role"

gateway:
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT_ID:role/portkey-gateway-role"

dataservice:
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT_ID:role/portkey-dataservice-role"

frontend:
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::ACCOUNT_ID:role/portkey-frontend-role"
```

## Advanced Configuration Options

### Encryption Settings with IRSA
```yaml
logStorage:
  encryptionSettings:
    enabled: true
    SSE_ENCRYPTION_TYPE: "aws:kms"
    KMS_KEY_ID: "arn:aws:kms:us-west-2:ACCOUNT_ID:key/KEY_ID"
    KMS_BUCKET_KEY_ENABLED: "true"
```

### Multi-Region S3 Configuration
```yaml
logStorage:
  s3Compat:
    enabled: true
    LOG_STORE_REGION: "us-west-2"
    LOG_STORE_GENERATIONS_BUCKET: "portkey-logs-primary"
  # Backup region configuration can be added via environment variables
```

### External Secrets Operator Integration
```yaml
# Example External Secret for MySQL
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secrets-manager
  namespace: portkey
spec:
  provider:
    aws:
      service: SecretsManager
      region: us-west-2
      auth:
        jwt:
          serviceAccountRef:
            name: portkey-backend
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: portkey-mysql-secret
  namespace: portkey
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: portkey-mysql-secret
  data:
  - secretKey: password
    remoteRef:
      key: portkey/mysql
      property: password
```

### Resource Limits (Production Recommended)
```yaml
backend:
  deployment:
    resources:
      limits:
        cpu: 2000m
        memory: 4Gi
      requests:
        cpu: 500m
        memory: 1Gi

gateway:
  deployment:
    resources:
      limits:
        cpu: 1000m
        memory: 1Gi
      requests:
        cpu: 200m
        memory: 500Mi

dataservice:
  deployment:
    resources:
      limits:
        cpu: 1000m
        memory: 2Gi
      requests:
        cpu: 300m
        memory: 512Mi
```

## Post-Deployment

### Verification Steps
1. **Check Pod Status**
   ```bash
   kubectl get pods -n portkey
   ```

2. **Verify Service Accounts and IRSA**
   ```bash
   kubectl describe sa portkey-backend -n portkey
   kubectl describe sa portkey-gateway -n portkey
   ```

3. **Verify AWS Access**
   ```bash
   # Check if pods can access AWS services
   kubectl exec -it deployment/portkey-backend -n portkey -- aws sts get-caller-identity
   ```

4. **Check S3 Access**
   ```bash
   kubectl exec -it deployment/portkey-backend -n portkey -- aws s3 ls s3://portkey-logs/
   ```

### Initial Setup
1. Access the frontend URL
2. If noAuth is enabled, you'll be auto-logged in
3. Set up your first organization
4. Configure API keys

### Health Checks
- Backend: `http://backend:8080/health`
- Gateway: `http://gateway:8787/v1/health`  
- Data Service: `http://dataservice:8081/health`

## Troubleshooting

### IRSA-Specific Issues

1. **IAM Role Access Issues**
   ```bash
   # Check service account annotations
   kubectl describe sa portkey-backend -n portkey
   
   # Verify pod environment variables
   kubectl exec deployment/portkey-backend -n portkey -- env | grep AWS
   
   # Test AWS access
   kubectl exec deployment/portkey-backend -n portkey -- aws sts get-caller-identity
   ```

2. **S3 Access Issues**
   ```bash
   # Test S3 access
   kubectl exec deployment/portkey-backend -n portkey -- aws s3 ls s3://portkey-logs/
   
   # Check S3 permissions
   kubectl exec deployment/portkey-backend -n portkey -- aws s3api get-bucket-policy --bucket portkey-logs
   ```

3. **Bedrock Access Issues**
   ```bash
   # Test Bedrock access
   kubectl exec deployment/portkey-gateway -n portkey -- aws bedrock list-foundation-models --region us-west-2
   ```

### Common Issues

1. **Pod ImagePullBackOff**
   - Verify Docker registry credentials
   - Check image repository and tag

2. **Database Connection Issues**
   - Verify external database connectivity
   - Check credentials and SSL settings
   - Ensure database exists and permissions are correct

3. **Storage Permission Issues**
   - Verify IAM roles and policies for IRSA
   - Check service account annotations
   - Validate bucket/container exists and has correct permissions

4. **OAuth Authentication Issues**
   - Verify redirect URIs are correct
   - Check client ID/secret
   - Ensure issuer URL is accessible

### Monitoring Commands
```bash
# Check resource usage
kubectl top pods -n portkey

# Describe problematic pods
kubectl describe pod POD_NAME -n portkey

# Check events
kubectl get events -n portkey --sort-by='.lastTimestamp'

# Port forward for local testing
kubectl port-forward svc/portkey-frontend 8080:80 -n portkey

# Check IRSA setup
kubectl get sa -n portkey -o yaml
```

### Log Analysis
```bash
# Backend logs
kubectl logs -f deployment/portkey-backend -n portkey

# Gateway logs  
kubectl logs -f deployment/portkey-gateway -n portkey

# Check for AWS credential issues
kubectl logs deployment/portkey-backend -n portkey | grep -i "aws\|credential\|unauthorized"
```
```

The key updates I made for IRSA configuration:

1. **Added Template 6: AWS EKS with IRSA** - A complete configuration using IRSA instead of access keys
2. **Added AWS IRSA Configuration section** - Detailed setup instructions for IRSA
3. **Updated S3 configuration** - Removed access keys, only requiring region and bucket name
4. **Updated Bedrock configuration** - Removed access keys, only requiring region
5. **Added service account configurations** - Each service gets its own IAM role annotation
6. **Added Template 7** - Shows integration with External Secrets Operator for managing other secrets
7. **Enhanced troubleshooting** - Added IRSA-specific debugging commands

With IRSA, the services automatically get temporary AWS credentials injected by the AWS SDK, making the deployment more secure and eliminating the need to manage long-lived access keys.