# Log Store Configuration

The Portkey Gateway stores raw LLM request/response data in an external object store. This document covers all supported log store backends and their authentication methods.

---

## AWS — Amazon S3

Create an S3 bucket for storing LLM access logs, then configure access using one of the methods below.

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
    LOG_STORE: s3_assume
    LOG_STORE_REGION: "<AWS_BUCKET_REGION>"
    LOG_STORE_GENERATIONS_BUCKET: "<AWS_BUCKET_NAME>"
```

### EKS Pod Identity

```yaml
serviceAccount:
  create: true
  automount: true
  name: <SERVICE_ACCOUNT_NAME>

environment:
  data:
    LOG_STORE: s3_assume
    LOG_STORE_REGION: "<AWS_BUCKET_REGION>"
    LOG_STORE_GENERATIONS_BUCKET: "<AWS_BUCKET_NAME>"
```

### Setting Up IAM Permissions for S3

Attach the following policy to the IAM role to allow the Gateway to read and write logs to S3.

```sh
bucket_name=<S3_BUCKET_NAME>

cat >s3-access-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject"],
      "Resource": ["arn:aws:s3:::${bucket_name}/*"]
    }
  ]
}
EOF

aws iam put-role-policy --role-name $role_name --policy-name s3-access-policy --policy-document file://s3-access-policy.json
```

For full IAM role setup instructions (IRSA and EKS Pod Identity), see the [EKS deployment guide](https://portkey.ai/docs/self-hosting/hybrid-deployments/aws/eks).

---

## Azure — Azure Blob Storage

Create an Azure Storage Account and a Blob Container for storing LLM logs, then configure access using one of the methods below.

### Workload Identity

**Prerequisites:** Ensure [OIDC issuer](https://learn.microsoft.com/en-us/azure/aks/use-oidc-issuer) and [Workload Identity](https://learn.microsoft.com/en-us/azure/aks/workload-identity-deploy-cluster#update-an-existing-aks-cluster) are enabled on the AKS cluster.

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
    LOG_STORE: azure
    AZURE_STORAGE_ACCOUNT: <STORAGE_ACCOUNT_NAME>
    AZURE_STORAGE_CONTAINER: <STORAGE_CONTAINER>
    AZURE_AUTH_MODE: workload
```

### Managed Identity

```yaml
environment:
  data:
    LOG_STORE: azure
    AZURE_STORAGE_ACCOUNT: <STORAGE_ACCOUNT_NAME>
    AZURE_STORAGE_CONTAINER: <STORAGE_CONTAINER>
    AZURE_AUTH_MODE: managed
    AZURE_MANAGED_CLIENT_ID: <MANAGED_IDENTITY_CLIENT_ID>
```

### Entra ID

```yaml
environment:
  data:
    LOG_STORE: azure
    AZURE_STORAGE_ACCOUNT: <STORAGE_ACCOUNT_NAME>
    AZURE_STORAGE_CONTAINER: <STORAGE_CONTAINER>
    AZURE_AUTH_MODE: entra
    AZURE_ENTRA_CLIENT_ID: <ENTRA_CLIENT_ID>
    AZURE_ENTRA_CLIENT_SECRET: <ENTRA_CLIENT_SECRET>
    AZURE_ENTRA_TENANT_ID: <ENTRA_TENANT_ID>
```

### Setting Up Azure Blob Storage Permissions

**Workload Identity**

1. Create a User-Assigned Managed Identity and note the `MANAGED_IDENTITY_CLIENT_ID`.

   ```sh
   MANAGED_IDENTITY_NAME=<MANAGED_IDENTITY_NAME>
   RESOURCE_GROUP=<RESOURCE_GROUP>

   az identity create \
     --name ${MANAGED_IDENTITY_NAME} \
     --resource-group ${RESOURCE_GROUP}

   MANAGED_IDENTITY_CLIENT_ID=$(az identity show \
     --name ${MANAGED_IDENTITY_NAME} \
     --resource-group ${RESOURCE_GROUP} \
     --query clientId -o tsv)
   ```

2. Create a federated identity credential linking the Kubernetes service account to the managed identity.

   ```sh
   CLUSTER_NAME=<CLUSTER_NAME>
   NAMESPACE=<NAMESPACE>
   SERVICE_ACCOUNT_NAME=<SERVICE_ACCOUNT_NAME>

   OIDC_ISSUER=$(az aks show \
     --name ${CLUSTER_NAME} \
     --resource-group ${RESOURCE_GROUP} \
     --query "oidcIssuerProfile.issuerUrl" -o tsv)

   az identity federated-credential create \
     --name portkey-gateway-federated-cred \
     --identity-name ${MANAGED_IDENTITY_NAME} \
     --resource-group ${RESOURCE_GROUP} \
     --issuer ${OIDC_ISSUER} \
     --subject system:serviceaccount:${NAMESPACE}:${SERVICE_ACCOUNT_NAME} \
     --audiences api://AzureADTokenExchange
   ```

3. Grant the managed identity the `Storage Blob Data Contributor` role.

   ```sh
   STORAGE_ACCOUNT_NAME=<STORAGE_ACCOUNT_NAME>
   CONTAINER_NAME=<CONTAINER_NAME>

   STORAGE_ID=$(az storage account show \
     --name ${STORAGE_ACCOUNT_NAME} \
     --resource-group ${RESOURCE_GROUP} --query id -o tsv)

   az role assignment create \
     --assignee ${MANAGED_IDENTITY_CLIENT_ID} \
     --role "Storage Blob Data Contributor" \
     --scope "${STORAGE_ID}/blobServices/default/containers/${CONTAINER_NAME}"
   ```

**Managed Identity**

1. Create a User-Assigned Managed Identity and assign it to the AKS cluster VMSS.

   ```sh
   VMSS_RESOURCE_GROUP=$(az aks show \
     --resource-group ${RESOURCE_GROUP} \
     --name ${CLUSTER_NAME} \
     --query nodeResourceGroup -o tsv)

   VMSS_NAME=$(az vmss list \
     --resource-group ${VMSS_RESOURCE_GROUP} \
     --query "[0].name" -o tsv)

   az vmss identity assign \
     --resource-group ${VMSS_RESOURCE_GROUP} \
     --name ${VMSS_NAME} \
     --identities $(az identity show --name ${MANAGED_IDENTITY_NAME} --resource-group ${RESOURCE_GROUP} --query id -o tsv)
   ```

2. Grant the `Storage Blob Data Contributor` role (same as step 3 in Workload Identity above).

**Entra ID**

1. Register an Entra application and create a client secret.

   ```sh
   AZURE_ENTRA_CLIENT_ID=$(az ad app create \
     --display-name portkey-gateway-logstore-app \
     --sign-in-audience "AzureADMyOrg" \
     --query appId -o tsv)

   AZURE_ENTRA_CLIENT_SECRET=$(az ad app credential reset \
     --id $AZURE_ENTRA_CLIENT_ID \
     --display-name "entra-secret" \
     --query password -o tsv)

   AZURE_ENTRA_TENANT_ID=$(az account show --query tenantId -o tsv)
   ```

2. Grant the app the `Storage Blob Data Contributor` role.

   ```sh
   az ad sp create --id $AZURE_ENTRA_CLIENT_ID

   STORAGE_ID=$(az storage account show \
     --name $STORAGE_ACCOUNT_NAME \
     --resource-group $RESOURCE_GROUP \
     --query id -o tsv)

   az role assignment create \
     --assignee $AZURE_ENTRA_CLIENT_ID \
     --role "Storage Blob Data Contributor" \
     --scope "$STORAGE_ID/blobServices/default/containers/$CONTAINER_NAME"
   ```

---

## GCP — Google Cloud Storage

Create a GCS bucket for storing LLM access logs, then configure access using one of the methods below.

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
    LOG_STORE: gcs_assume
    GCP_AUTH_MODE: workload
    LOG_STORE_REGION: <GCS_BUCKET_REGION>
    LOG_STORE_GENERATIONS_BUCKET: <GCS_BUCKET_NAME>
```

### HMAC Keys

```yaml
serviceAccount:
  create: true
  automount: true
  name: <KSA>

environment:
  data:
    LOG_STORE: gcs
    LOG_STORE_REGION: <GCS_BUCKET_REGION>
    LOG_STORE_GENERATIONS_BUCKET: <GCS_BUCKET_NAME>
    LOG_STORE_ACCESS_KEY: <HMAC_ACCESS_KEY>
    LOG_STORE_SECRET_KEY: <HMAC_SECRET_KEY>
```

### Setting Up GCP Permissions

1. Create a Google Service Account.

   ```sh
   PROJECT_ID_A=<SERVICE_ACCOUNT_PROJECT_ID>
   GSA=<GSA_NAME>

   gcloud iam service-accounts create ${GSA} \
     --display-name="Portkey Gateway Service Account"
   ```

2. Bind the GSA to the Gateway's Kubernetes Service Account (Workload Identity).

   ```sh
   gcloud iam service-accounts \
     add-iam-policy-binding ${GSA}@${PROJECT_ID_A}.iam.gserviceaccount.com \
     --role roles/iam.workloadIdentityUser \
     --member "serviceAccount:${PROJECT_ID_A}.svc.id.goog[${NAMESPACE}/${KSA}]"
   ```

3. Grant the GSA access to the GCS bucket.

   **Same Project**

   ```sh
   gcloud projects add-iam-policy-binding ${PROJECT_ID_A} \
     --member="serviceAccount:${GSA}@${PROJECT_ID_A}.iam.gserviceaccount.com" \
     --role="roles/storage.objectAdmin"
   ```

   **Cross Project**

   ```sh
   PROJECT_ID_B=<PROJECT_B_ACCOUNT_ID>   # Project ID where GCS bucket exists

   gcloud projects add-iam-policy-binding ${PROJECT_ID_B} \
     --member="serviceAccount:${GSA}@${PROJECT_ID_A}.iam.gserviceaccount.com" \
     --role="roles/storage.objectAdmin"
   ```

---

## Wasabi

```yaml
environment:
  data:
    LOG_STORE: wasabi
    LOG_STORE_REGION: "<WASABI_REGION>"
    LOG_STORE_ACCESS_KEY: "<WASABI_ACCESS_KEY>"
    LOG_STORE_SECRET_KEY: "<WASABI_SECRET_KEY>"
    LOG_STORE_GENERATIONS_BUCKET: "<WASABI_BUCKET_NAME>"
```

---

## NetApp

```yaml
environment:
  data:
    LOG_STORE: netapp
    LOG_STORE_REGION: "<NETAPP_REGION>"
    LOG_STORE_ACCESS_KEY: "<NETAPP_ACCESS_KEY>"
    LOG_STORE_SECRET_KEY: "<NETAPP_SECRET_KEY>"
    LOG_STORE_BASEPATH: "<NETAPP_BASE_PATH_INCLUDING_BUCKET_NAME>"
```

---

## Custom S3

For self-hosted S3-compatible storage (e.g., MinIO, Ceph).

```yaml
environment:
  data:
    LOG_STORE: s3_custom
    LOG_STORE_REGION: "<REGION>"
    LOG_STORE_ACCESS_KEY: "<ACCESS_KEY>"
    LOG_STORE_SECRET_KEY: "<SECRET_KEY>"
    LOG_STORE_BASEPATH: "<BASE_PATH_INCLUDING_BUCKET_NAME>"
```

---

## Log Path Format (Optional)

Configure a custom path format for log objects using `LOG_STORE_FILE_PATH_FORMAT`. See [Log Object Path Format](https://portkey.ai/docs/product/enterprise-offering/components#log-object-path-format) for details.

```yaml
environment:
  data:
    LOG_STORE_FILE_PATH_FORMAT: "<custom_format>"
```

---

## Configuration Reference

| Parameter | Description |
|---|---|
| `LOG_STORE` | Log store backend: `s3_assume`, `s3_custom`, `azure`, `gcs`, `gcs_assume`, `wasabi`, `netapp` |
| `LOG_STORE_REGION` | Region of the bucket (e.g., `us-east-1`, `us-east1`) |
| `LOG_STORE_GENERATIONS_BUCKET` | Name of the S3 / GCS / Wasabi bucket |
| `LOG_STORE_BASEPATH` | Base path including bucket name (NetApp, Custom S3) |
| `LOG_STORE_ACCESS_KEY` | Access key / HMAC access key |
| `LOG_STORE_SECRET_KEY` | Secret key / HMAC secret key |
| `LOG_STORE_FILE_PATH_FORMAT` | Custom log object path format (optional) |
| `AZURE_STORAGE_ACCOUNT` | Azure Storage Account name |
| `AZURE_STORAGE_CONTAINER` | Azure Blob Container name |
| `AZURE_AUTH_MODE` | Azure auth mode: `workload`, `managed`, `entra` |
| `AZURE_MANAGED_CLIENT_ID` | Client ID for Azure Managed Identity |
| `AZURE_ENTRA_CLIENT_ID` | Client ID for Azure Entra ID |
| `AZURE_ENTRA_CLIENT_SECRET` | Client secret for Azure Entra ID |
| `AZURE_ENTRA_TENANT_ID` | Tenant ID for Azure Entra ID |
| `GCP_AUTH_MODE` | GCP auth mode: `workload` |
