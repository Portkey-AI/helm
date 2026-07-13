# External Redis Configuration

The Portkey Gateway includes a built-in Redis instance by default. For production deployments, you can connect to an external managed Redis service. This document covers all supported authentication methods across AWS, Azure, and GCP.

---

## Built-in Redis

No additional permissions or network configuration required.

```yaml
environment:
  data:
    CACHE_STORE: redis
    REDIS_URL: "redis://redis:6379"
    REDIS_TLS_ENABLED: "false"
```

---

## AWS — Amazon ElastiCache

Ensure an inbound rule is configured in the ElastiCache Security Group to allow access from the EKS cluster on the required port.

> **Note:** If cluster mode is enabled, use the **Configuration Endpoint**; otherwise use the **Primary Endpoint**.

### No Auth

```yaml
environment:
  data:
    CACHE_STORE: aws-elastic-cache
    REDIS_URL: "redis://<ElastiCache_Endpoint>:<Port>"
    REDIS_TLS_ENABLED: "false"
    REDIS_MODE: cluster          # Add only if cluster mode is enabled
```

### Auth Token

```yaml
environment:
  data:
    CACHE_STORE: aws-elastic-cache
    REDIS_URL: "redis://<ElastiCache_Endpoint>:<Port>"
    REDIS_TLS_ENABLED: "true"
    REDIS_MODE: cluster          # Add only if cluster mode is enabled
    REDIS_PASSWORD: <Auth_Token>
```

### IRSA (IAM Roles for Service Accounts)

```yaml
serviceAccount:
  create: true
  automount: true
  name: <SERVICE_ACCOUNT_NAME>
  annotations:
    eks.amazonaws.com/role-arn: <ROLE_ARN>

environment:
  data:
    CACHE_STORE: aws-elastic-cache
    REDIS_URL: "redis://<ElastiCache_Endpoint>:<Port>"
    REDIS_TLS_ENABLED: "true"
    REDIS_MODE: cluster                               # Add only if cluster mode is enabled
    AWS_REDIS_AUTH_MODE: iam
    AWS_REDIS_CLUSTER_NAME: <ELASTICACHE_CLUSTER_NAME>
    REDIS_USERNAME: <ELASTICACHE_USER_ID>
```

The IAM role must have `elasticache:Connect` permission. See [ElastiCache IAM authentication](https://docs.aws.amazon.com/AmazonElastiCache/latest/dg/auth-iam.html) for details.

### EKS Pod Identity

```yaml
serviceAccount:
  create: true
  automount: true
  name: <SERVICE_ACCOUNT_NAME>

environment:
  data:
    CACHE_STORE: aws-elastic-cache
    REDIS_URL: "redis://<ElastiCache_Endpoint>:<Port>"
    REDIS_TLS_ENABLED: "true"
    REDIS_MODE: cluster                               # Add only if cluster mode is enabled
    AWS_REDIS_AUTH_MODE: iam
    AWS_REDIS_CLUSTER_NAME: <ELASTICACHE_CLUSTER_NAME>
    REDIS_USERNAME: <ELASTICACHE_USER_ID>
```

The IAM role must have `elasticache:Connect` permission and a Pod Identity association must be created. See [EKS Pod Identity](https://docs.aws.amazon.com/eks/latest/userguide/pod-id-agent-setup.html) for details.

### IAM Policy for ElastiCache

Attach the following policy to the IAM role to allow the Gateway to authenticate with ElastiCache.

```sh
elasticache_cluster_arn=<ELASTICACHE_REPLICATION_GROUP_ARN>
elasticache_user_arn=<ELASTICACHE_USER_ARN>

cat >elasticache-access-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["elasticache:Connect"],
      "Resource": [
        "${elasticache_cluster_arn}",
        "${elasticache_user_arn}"
      ]
    }
  ]
}
EOF

aws iam put-role-policy --role-name $role_name --policy-name elasticache-access-policy --policy-document file://elasticache-access-policy.json
```

---

## Azure — Azure Managed Redis

Ensure connectivity from the AKS cluster to the Azure Managed Redis instance.

**Prerequisite:** [Microsoft Entra Authentication](https://learn.microsoft.com/en-us/azure/azure-cache-for-redis/cache-azure-active-directory-for-authentication) must be enabled on the Redis instance for Workload Identity, Managed Identity, and Entra ID methods.

### Access Key

```yaml
environment:
  data:
    CACHE_STORE: azure-redis
    REDIS_URL: "rediss://<Azure_Redis_Endpoint>:<Port>"
    AZURE_REDIS_AUTH_MODE: password
    REDIS_TLS_ENABLED: "true"
    REDIS_MODE: cluster          # Add only if cluster mode is enabled
    REDIS_PASSWORD: <Access_Key>
```

### Workload Identity

```yaml
serviceAccount:
  create: true
  automount: true
  name: <SERVICE_ACCOUNT_NAME>
  annotations:
    azure.workload.identity/client-id: <MANAGED_IDENTITY_CLIENT_ID>

podLabels:
  azure.workload.identity/use: "true"

environment:
  data:
    CACHE_STORE: azure-redis
    REDIS_URL: "redis://<Azure_Redis_Endpoint>:<Port>"
    REDIS_TLS_ENABLED: "true"
    REDIS_MODE: cluster          # Add only if cluster mode is enabled
    AZURE_REDIS_AUTH_MODE: workload
```

### Managed Identity

```yaml
environment:
  data:
    CACHE_STORE: azure-redis
    REDIS_URL: "redis://<Azure_Redis_Endpoint>:<Port>"
    REDIS_TLS_ENABLED: "true"
    REDIS_MODE: cluster          # Add only if cluster mode is enabled
    AZURE_REDIS_AUTH_MODE: managed
    AZURE_REDIS_MANAGED_CLIENT_ID: <MANAGED_CLIENT_ID>
```

### Entra ID

```yaml
environment:
  data:
    CACHE_STORE: azure-redis
    REDIS_URL: "redis://<Azure_Redis_Endpoint>:<Port>"
    REDIS_TLS_ENABLED: "true"
    REDIS_MODE: cluster          # Add only if cluster mode is enabled
    AZURE_REDIS_AUTH_MODE: entra
    AZURE_REDIS_ENTRA_CLIENT_ID: <ENTRA_CLIENT_ID>
    AZURE_REDIS_ENTRA_CLIENT_SECRET: <ENTRA_CLIENT_SECRET>
    AZURE_REDIS_ENTRA_TENANT_ID: <ENTRA_TENANT_ID>
```

### Setting Up Azure Redis Permissions

Grant the required identity a data access policy on the Redis instance.

**Workload Identity / Managed Identity**

```sh
REDIS_NAME=<REDIS_NAME>
RESOURCE_GROUP=<RESOURCE_GROUP>
MANAGED_IDENTITY_NAME=<MANAGED_IDENTITY_NAME>

MANAGED_IDENTITY_OBJECT_ID=$(az identity show \
  --name ${MANAGED_IDENTITY_NAME} \
  --resource-group ${RESOURCE_GROUP} \
  --query principalId -o tsv)

az redisenterprise database access-policy-assignment create \
  --access-policy-assignment-name portkeyGatewayRedisAccess \
  --cluster-name ${REDIS_NAME} \
  --database-name default \
  --resource-group ${RESOURCE_GROUP} \
  --access-policy-name default \
  --object-id ${MANAGED_IDENTITY_OBJECT_ID}
```

**Entra ID**

```sh
REDIS_NAME=<REDIS_NAME>
RESOURCE_GROUP=<RESOURCE_GROUP>

ENTRA_OBJECT_ID=$(az ad sp show \
  --id ${AZURE_ENTRA_CLIENT_ID} \
  --query id -o tsv)

az redisenterprise database access-policy-assignment create \
  --access-policy-assignment-name portkeyGatewayRedisAccess \
  --cluster-name ${REDIS_NAME} \
  --database-name default \
  --resource-group ${RESOURCE_GROUP} \
  --access-policy-name default \
  --object-id ${ENTRA_OBJECT_ID}
```

---

## GCP — Google Memorystore

Ensure network access from the GKE cluster to the Memorystore instance on the required port.

### No Auth

```yaml
environment:
  data:
    CACHE_STORE: gcp-memory-store
    REDIS_URL: "redis://<GCP_MEMORY_STORE_IP>:<Port>"
    REDIS_TLS_ENABLED: "false"
    REDIS_MODE: cluster          # Add only if cluster mode is enabled
```

### AUTH String

```yaml
environment:
  data:
    CACHE_STORE: gcp-memory-store
    REDIS_URL: "redis://<MEMORY_STORE_IP>:<Port>"
    REDIS_TLS_ENABLED: "false"
    REDIS_MODE: cluster          # Add only if cluster mode is enabled
    REDIS_PASSWORD: <MEMORY_STORE_AUTH_STRING>
```

### Workload Identity Federation

```yaml
serviceAccount:
  create: true
  automount: true
  name: <KSA>
  annotations:
    iam.gke.io/gcp-service-account: <GSA>@<PROJECT_ID>.iam.gserviceaccount.com

environment:
  data:
    CACHE_STORE: gcp-memory-store
    GCP_REDIS_AUTH_MODE: workload
    REDIS_URL: "redis://<MEMORY_STORE_IP>:<Port>"
    REDIS_TLS_ENABLED: "false"
    REDIS_MODE: cluster          # Add only if cluster mode is enabled
```

### TLS (Optional)

If TLS is enabled on the Memorystore instance, mount the server certificate into the Gateway pod.

1. Download `server-ca.pem` from your Memorystore instance.
2. Create a Kubernetes secret:
   ```sh
   kubectl create secret generic memorystore-tls-certs \
     --from-file=server-ca.pem -n $NAMESPACE
   ```
3. Add to `values.yaml`:
   ```yaml
   environment:
     data:
       REDIS_TLS_CERTS: /etc/ssl/certs/server-ca.pem
       REDIS_TLS_ENABLED: "true"
   volumes:
     - name: memorystore-tls-certs
       secret:
         secretName: memorystore-tls-certs
   volumeMounts:
     - name: memorystore-tls-certs
       mountPath: /etc/ssl/certs/server-ca.pem
       subPath: server-ca.pem
   ```

### Setting Up GCP Memorystore Permissions

Grant `roles/redis.dbConnectionUser` to the Google Service Account.

**Same Project**

```sh
gcloud projects add-iam-policy-binding ${PROJECT_ID_A} \
  --member="serviceAccount:${GSA}@${PROJECT_ID_A}.iam.gserviceaccount.com" \
  --role="roles/redis.dbConnectionUser"
```

**Cross Project**

```sh
PROJECT_ID_B=<PROJECT_B_ACCOUNT_ID>   # Project ID where Memorystore instance exists

gcloud projects add-iam-policy-binding ${PROJECT_ID_B} \
  --member="serviceAccount:${GSA}@${PROJECT_ID_A}.iam.gserviceaccount.com" \
  --role="roles/redis.dbConnectionUser"
```

---

## Configuration Reference

| Parameter | Description |
|---|---|
| `CACHE_STORE` | Cache backend: `redis` (built-in), `aws-elastic-cache`, `azure-redis`, `gcp-memory-store` |
| `REDIS_URL` | Redis connection URL (`redis://` or `rediss://` for TLS) |
| `REDIS_TLS_ENABLED` | Enable TLS: `"true"` or `"false"` |
| `REDIS_MODE` | Set to `cluster` only when cluster mode is enabled on the Redis instance |
| `REDIS_PASSWORD` | Password / Auth Token / AUTH String (depending on provider) |
| `REDIS_USERNAME` | Username for ElastiCache IAM auth |
| `REDIS_TLS_CERTS` | Path to TLS certificate file (GCP Memorystore TLS only) |
| `AWS_REDIS_AUTH_MODE` | AWS auth mode: `iam` |
| `AWS_REDIS_CLUSTER_NAME` | ElastiCache replication group or serverless cache name (IAM auth) |
| `AZURE_REDIS_AUTH_MODE` | Azure auth mode: `password`, `workload`, `managed`, `entra` |
| `AZURE_REDIS_MANAGED_CLIENT_ID` | Client ID for Azure Managed Identity |
| `AZURE_REDIS_ENTRA_CLIENT_ID` | Client ID for Azure Entra ID |
| `AZURE_REDIS_ENTRA_CLIENT_SECRET` | Client secret for Azure Entra ID |
| `AZURE_REDIS_ENTRA_TENANT_ID` | Tenant ID for Azure Entra ID |
| `GCP_REDIS_AUTH_MODE` | GCP auth mode: `workload` |
