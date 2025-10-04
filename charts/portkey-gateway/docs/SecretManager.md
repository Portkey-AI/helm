### Portkey Gateway — AWS Secrets Manager Integration

Portkey Gateway supports integrating AWS Secrets Manager via the Secrets Store CSI Driver.

- Preferred: Partial Secret Override (AWS → Kubernetes Secret for selected keys; other keys from `values.yaml`)
- Supported: Full Secret Override (all keys from the Secret)
- Supported: Mount-only File Paths (no Kubernetes Secret sync; values are file paths that the app reads)

Applications accept values as either normal strings or filesystem paths. If the value looks like a path (e.g., `/mnt/secrets/PORTKEY_CLIENT_AUTH`), the app reads the file contents at that path and uses that value.

## Prerequisites
1. Amazon EKS cluster (v1.23+ recommended)
2. AWS CLI configured and `kubectl` access
3. An IRSA role with at least `secretsmanager:GetSecretValue` and `secretsmanager:DescribeSecret`
4. Namespace created (e.g., `portkeyai`)

Example IAM policy for IRSA:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PortkeySecretsRead",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:<REGION>:<ACCOUNT_ID>:secret:portkey/*"
    }
  ]
}
```

## Install CSI Driver and AWS Provider
```bash
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm repo update
helm upgrade --install csi-secrets-store secrets-store-csi-driver/secrets-store-csi-driver \
  --namespace kube-system --create-namespace --set syncSecret.enabled=true

helm repo add aws-secrets-manager https://aws.github.io/secrets-store-csi-driver-provider-aws
helm repo update
helm upgrade --install secrets-provider-aws aws-secrets-manager/secrets-store-csi-driver-provider-aws \
  --namespace kube-system
```

## IRSA on Service Accounts
Annotate the service accounts used by the gateway and (optionally) dataservice:
```yaml
# values.yaml
serviceAccount:
  create: true
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::<ACCOUNT_ID>:role/<YOUR_IRSA_ROLE>"

dataservice:
  enabled: true   # only if you use dataservice
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::<ACCOUNT_ID>:role/<YOUR_IRSA_ROLE>"
```

## What can be sourced from Secrets?
Use the keys defined under `environment.data` in `values.yaml`. Common keys include:
- Core: `SERVICE_NAME`, `PORT`, `PORTKEY_CLIENT_AUTH`, `ORGANISATIONS_TO_SYNC`
- Analytics: `ANALYTICS_STORE`, `ANALYTICS_STORE_ENDPOINT`, `ANALYTICS_STORE_USER`, `ANALYTICS_STORE_PASSWORD`, `ANALYTICS_LOG_TABLE`, `ANALYTICS_FEEDBACK_TABLE`
- Cache: `CACHE_STORE`, `REDIS_URL`, `REDIS_TLS_ENABLED`, `REDIS_MODE`
- Log Store: `LOG_STORE`, `LOG_STORE_REGION`, `LOG_STORE_ACCESS_KEY`, `LOG_STORE_SECRET_KEY`, `LOG_STORE_GENERATIONS_BUCKET`, `LOG_STORE_BASEPATH`, `LOG_STORE_AWS_ROLE_ARN`, `LOG_STORE_AWS_EXTERNAL_ID`
- AWS Assume Role (Bedrock etc.): `AWS_ASSUME_ROLE_ACCESS_KEY_ID`, `AWS_ASSUME_ROLE_SECRET_ACCESS_KEY`, `AWS_ASSUME_ROLE_REGION`
- Azure Blob: `AZURE_AUTH_MODE`, `AZURE_MANAGED_CLIENT_ID`, `AZURE_STORAGE_ACCOUNT`, `AZURE_STORAGE_KEY`, `AZURE_STORAGE_CONTAINER`
- Dataservice-related (if enabled): `FINETUNES_BUCKET`, `LOG_EXPORTS_BUCKET`, `FINETUNES_AWS_ROLE_ARN`

Include only the keys you want to source from Secrets Manager; others can stay as literals in `values.yaml`.

---

## Option A (Preferred): Partial Secret Override
Sync selected keys from AWS → a Kubernetes Secret, then point the chart to that Secret. Missing keys fall back to literals in `values.yaml`.

### 1) AWS Secret (example JSON)
Create an AWS Secrets Manager secret like `arn:aws:secretsmanager:<REGION>:<ACCOUNT_ID>:secret:portkey/gateway/config`:
```json
{
  "SERVICE_NAME": "portkeyenterprise",
  "PORT": "8787",

  "PORTKEY_CLIENT_AUTH": "<shared by portkey>",
  "ORGANISATIONS_TO_SYNC": "",

  "ANALYTICS_STORE": "control_plane",
  "ANALYTICS_STORE_ENDPOINT": "<clickhouse host>",
  "ANALYTICS_STORE_USER": "<user>",
  "ANALYTICS_STORE_PASSWORD": "<password>",
  "ANALYTICS_LOG_TABLE": "<table>",
  "ANALYTICS_FEEDBACK_TABLE": "<table>",

  "CACHE_STORE": "redis",
  "REDIS_URL": "redis://redis:6379",
  "REDIS_TLS_ENABLED": "false",
  "REDIS_MODE": "",

  "LOG_STORE": "s3",
  "LOG_STORE_REGION": "us-east-1",
  "LOG_STORE_ACCESS_KEY": "<key>",
  "LOG_STORE_SECRET_KEY": "<secret>",
  "LOG_STORE_GENERATIONS_BUCKET": "<bucket>",
  "LOG_STORE_BASEPATH": "",
  "LOG_STORE_AWS_ROLE_ARN": "",
  "LOG_STORE_AWS_EXTERNAL_ID": "",

  "AWS_ASSUME_ROLE_ACCESS_KEY_ID": "",
  "AWS_ASSUME_ROLE_SECRET_ACCESS_KEY": "",
  "AWS_ASSUME_ROLE_REGION": "",

  "AZURE_AUTH_MODE": "",
  "AZURE_MANAGED_CLIENT_ID": "",
  "AZURE_STORAGE_ACCOUNT": "",
  "AZURE_STORAGE_KEY": "",
  "AZURE_STORAGE_CONTAINER": "",

  "FINETUNES_BUCKET": "",
  "LOG_EXPORTS_BUCKET": "",
  "FINETUNES_AWS_ROLE_ARN": ""
}
```

### 2) SecretProviderClass (sync to a Kubernetes Secret)
```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: portkey-gateway-aws-secrets
  namespace: portkeyai
spec:
  provider: aws
  parameters:
    objects: |
      - objectName: "arn:aws:secretsmanager:<REGION>:<ACCOUNT_ID>:secret:portkey/gateway/config"
        objectType: "secretsmanager"
        jmesPath:
          - path: SERVICE_NAME
            objectAlias: SERVICE_NAME
          - path: PORT
            objectAlias: PORT
          - path: PORTKEY_CLIENT_AUTH
            objectAlias: PORTKEY_CLIENT_AUTH
          - path: ORGANISATIONS_TO_SYNC
            objectAlias: ORGANISATIONS_TO_SYNC
          - path: ANALYTICS_STORE
            objectAlias: ANALYTICS_STORE
          - path: ANALYTICS_STORE_ENDPOINT
            objectAlias: ANALYTICS_STORE_ENDPOINT
          - path: ANALYTICS_STORE_USER
            objectAlias: ANALYTICS_STORE_USER
          - path: ANALYTICS_STORE_PASSWORD
            objectAlias: ANALYTICS_STORE_PASSWORD
          - path: ANALYTICS_LOG_TABLE
            objectAlias: ANALYTICS_LOG_TABLE
          - path: ANALYTICS_FEEDBACK_TABLE
            objectAlias: ANALYTICS_FEEDBACK_TABLE
          - path: CACHE_STORE
            objectAlias: CACHE_STORE
          - path: REDIS_URL
            objectAlias: REDIS_URL
          - path: REDIS_TLS_ENABLED
            objectAlias: REDIS_TLS_ENABLED
          - path: REDIS_MODE
            objectAlias: REDIS_MODE
          - path: LOG_STORE
            objectAlias: LOG_STORE
          - path: LOG_STORE_REGION
            objectAlias: LOG_STORE_REGION
          - path: LOG_STORE_ACCESS_KEY
            objectAlias: LOG_STORE_ACCESS_KEY
          - path: LOG_STORE_SECRET_KEY
            objectAlias: LOG_STORE_SECRET_KEY
          - path: LOG_STORE_GENERATIONS_BUCKET
            objectAlias: LOG_STORE_GENERATIONS_BUCKET
          - path: LOG_STORE_BASEPATH
            objectAlias: LOG_STORE_BASEPATH
          - path: LOG_STORE_AWS_ROLE_ARN
            objectAlias: LOG_STORE_AWS_ROLE_ARN
          - path: LOG_STORE_AWS_EXTERNAL_ID
            objectAlias: LOG_STORE_AWS_EXTERNAL_ID
          - path: AWS_ASSUME_ROLE_ACCESS_KEY_ID
            objectAlias: AWS_ASSUME_ROLE_ACCESS_KEY_ID
          - path: AWS_ASSUME_ROLE_SECRET_ACCESS_KEY
            objectAlias: AWS_ASSUME_ROLE_SECRET_ACCESS_KEY
          - path: AWS_ASSUME_ROLE_REGION
            objectAlias: AWS_ASSUME_ROLE_REGION
          - path: AZURE_AUTH_MODE
            objectAlias: AZURE_AUTH_MODE
          - path: AZURE_MANAGED_CLIENT_ID
            objectAlias: AZURE_MANAGED_CLIENT_ID
          - path: AZURE_STORAGE_ACCOUNT
            objectAlias: AZURE_STORAGE_ACCOUNT
          - path: AZURE_STORAGE_KEY
            objectAlias: AZURE_STORAGE_KEY
          - path: AZURE_STORAGE_CONTAINER
            objectAlias: AZURE_STORAGE_CONTAINER
          - path: FINETUNES_BUCKET
            objectAlias: FINETUNES_BUCKET
          - path: LOG_EXPORTS_BUCKET
            objectAlias: LOG_EXPORTS_BUCKET
          - path: FINETUNES_AWS_ROLE_ARN
            objectAlias: FINETUNES_AWS_ROLE_ARN
  secretObjects:
    - secretName: portkey-gateway-env
      type: Opaque
      data:
        - objectName: SERVICE_NAME
          key: SERVICE_NAME
        - objectName: PORT
          key: PORT
        - objectName: PORTKEY_CLIENT_AUTH
          key: PORTKEY_CLIENT_AUTH
        - objectName: ORGANISATIONS_TO_SYNC
          key: ORGANISATIONS_TO_SYNC
        - objectName: ANALYTICS_STORE
          key: ANALYTICS_STORE
        - objectName: ANALYTICS_STORE_ENDPOINT
          key: ANALYTICS_STORE_ENDPOINT
        - objectName: ANALYTICS_STORE_USER
          key: ANALYTICS_STORE_USER
        - objectName: ANALYTICS_STORE_PASSWORD
          key: ANALYTICS_STORE_PASSWORD
        - objectName: ANALYTICS_LOG_TABLE
          key: ANALYTICS_LOG_TABLE
        - objectName: ANALYTICS_FEEDBACK_TABLE
          key: ANALYTICS_FEEDBACK_TABLE
        - objectName: CACHE_STORE
          key: CACHE_STORE
        - objectName: REDIS_URL
          key: REDIS_URL
        - objectName: REDIS_TLS_ENABLED
          key: REDIS_TLS_ENABLED
        - objectName: REDIS_MODE
          key: REDIS_MODE
        - objectName: LOG_STORE
          key: LOG_STORE
        - objectName: LOG_STORE_REGION
          key: LOG_STORE_REGION
        - objectName: LOG_STORE_ACCESS_KEY
          key: LOG_STORE_ACCESS_KEY
        - objectName: LOG_STORE_SECRET_KEY
          key: LOG_STORE_SECRET_KEY
        - objectName: LOG_STORE_GENERATIONS_BUCKET
          key: LOG_STORE_GENERATIONS_BUCKET
        - objectName: LOG_STORE_BASEPATH
          key: LOG_STORE_BASEPATH
        - objectName: LOG_STORE_AWS_ROLE_ARN
          key: LOG_STORE_AWS_ROLE_ARN
        - objectName: LOG_STORE_AWS_EXTERNAL_ID
          key: LOG_STORE_AWS_EXTERNAL_ID
        - objectName: AWS_ASSUME_ROLE_ACCESS_KEY_ID
          key: AWS_ASSUME_ROLE_ACCESS_KEY_ID
        - objectName: AWS_ASSUME_ROLE_SECRET_ACCESS_KEY
          key: AWS_ASSUME_ROLE_SECRET_ACCESS_KEY
        - objectName: AWS_ASSUME_ROLE_REGION
          key: AWS_ASSUME_ROLE_REGION
        - objectName: AZURE_AUTH_MODE
          key: AZURE_AUTH_MODE
        - objectName: AZURE_MANAGED_CLIENT_ID
          key: AZURE_MANAGED_CLIENT_ID
        - objectName: AZURE_STORAGE_ACCOUNT
          key: AZURE_STORAGE_ACCOUNT
        - objectName: AZURE_STORAGE_KEY
          key: AZURE_STORAGE_KEY
        - objectName: AZURE_STORAGE_CONTAINER
          key: AZURE_STORAGE_CONTAINER
        - objectName: FINETUNES_BUCKET
          key: FINETUNES_BUCKET
        - objectName: LOG_EXPORTS_BUCKET
          key: LOG_EXPORTS_BUCKET
        - objectName: FINETUNES_AWS_ROLE_ARN
          key: FINETUNES_AWS_ROLE_ARN
```

Apply:
```bash
kubectl apply -f secretproviderclass-gateway.yaml
```

### 3) Mount to trigger sync
```yaml
# values.yaml
volumes:
  - name: portkey-secrets-store
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: "portkey-gateway-aws-secrets"
volumeMounts:
  - name: portkey-secrets-store
    mountPath: "/mnt/secrets"
    readOnly: true

# For dataservice (if enabled):
dataservice:
  deployment:
    volumes:
      - name: portkey-secrets-store
        csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: "portkey-gateway-aws-secrets"
    volumeMounts:
      - name: portkey-secrets-store
        mountPath: "/mnt/secrets"
        readOnly: true
```

### 4) Point the chart to the synced Secret (partial override)
```yaml
# values.yaml
environment:
  create: false
  existingSecret: "portkey-gateway-env"
  # Keep all the keys you care about listed below; Secret values win if present,
  # otherwise the literal values here are used.
  data:
    SERVICE_NAME: "portkeyenterprise"
    PORT: "8787"
    PORTKEY_CLIENT_AUTH: ""
    ORGANISATIONS_TO_SYNC: ""
    ANALYTICS_STORE: "control_plane"
    ANALYTICS_STORE_ENDPOINT: ""
    ANALYTICS_STORE_USER: ""
    ANALYTICS_STORE_PASSWORD: ""
    ANALYTICS_LOG_TABLE: ""
    ANALYTICS_FEEDBACK_TABLE: ""
    CACHE_STORE: "redis"
    REDIS_URL: "redis://redis:6379"
    REDIS_TLS_ENABLED: "false"
    REDIS_MODE: ""
    LOG_STORE: "s3"
    LOG_STORE_REGION: "us-east-1"
    LOG_STORE_ACCESS_KEY: ""
    LOG_STORE_SECRET_KEY: ""
    LOG_STORE_GENERATIONS_BUCKET: ""
    LOG_STORE_BASEPATH: ""
    LOG_STORE_AWS_ROLE_ARN: ""
    LOG_STORE_AWS_EXTERNAL_ID: ""
    AWS_ASSUME_ROLE_ACCESS_KEY_ID: ""
    AWS_ASSUME_ROLE_SECRET_ACCESS_KEY: ""
    AWS_ASSUME_ROLE_REGION: ""
    AZURE_AUTH_MODE: ""
    AZURE_MANAGED_CLIENT_ID: ""
    AZURE_STORAGE_ACCOUNT: ""
    AZURE_STORAGE_KEY: ""
    AZURE_STORAGE_CONTAINER: ""
    FINETUNES_BUCKET: ""
    LOG_EXPORTS_BUCKET: ""
    FINETUNES_AWS_ROLE_ARN: ""
```

How it works:
- If a key exists in the Secret, it is injected from the Secret.
- If a key is absent in the Secret, the literal value from `environment.data` is injected.
- Ensure all variables you need are listed under `environment.data`.

---

## Option B: Mount-only (read from files; no Kubernetes Secret sync)
Use the CSI driver to mount secrets as files, then set `environment.data` values to file paths. The app reads file contents for any value that looks like a filesystem path.

### 1) SecretProviderClass (files only; no `secretObjects`)
```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: portkey-gateway-aws-secrets
  namespace: portkeyai
spec:
  provider: aws
  parameters:
    objects: |
      - objectName: "arn:aws:secretsmanager:<REGION>:<ACCOUNT_ID>:secret:portkey/gateway/config"
        objectType: "secretsmanager"
        jmesPath:
          - path: PORTKEY_CLIENT_AUTH
            objectAlias: PORTKEY_CLIENT_AUTH
          - path: ANALYTICS_STORE_USER
            objectAlias: ANALYTICS_STORE_USER
          - path: ANALYTICS_STORE_PASSWORD
            objectAlias: ANALYTICS_STORE_PASSWORD
          - path: REDIS_URL
            objectAlias: REDIS_URL
          - path: LOG_STORE_ACCESS_KEY
            objectAlias: LOG_STORE_ACCESS_KEY
          - path: LOG_STORE_SECRET_KEY
            objectAlias: LOG_STORE_SECRET_KEY
          - path: AWS_ASSUME_ROLE_ACCESS_KEY_ID
            objectAlias: AWS_ASSUME_ROLE_ACCESS_KEY_ID
          - path: AWS_ASSUME_ROLE_SECRET_ACCESS_KEY
            objectAlias: AWS_ASSUME_ROLE_SECRET_ACCESS_KEY
          - path: AZURE_STORAGE_KEY
            objectAlias: AZURE_STORAGE_KEY
          # ...add any other keys you want as files
```

### 2) Mount to gateway (and dataservice if enabled)
```yaml
# values.yaml
volumes:
  - name: portkey-secrets-store
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: "portkey-gateway-aws-secrets"
volumeMounts:
  - name: portkey-secrets-store
    mountPath: "/mnt/secrets"
    readOnly: true

dataservice:
  deployment:
    volumes:
      - name: portkey-secrets-store
        csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: "portkey-gateway-aws-secrets"
    volumeMounts:
      - name: portkey-secrets-store
        mountPath: "/mnt/secrets"
        readOnly: true
```

### 3) Set values to file paths (partial or full)
```yaml
# values.yaml
environment:
  create: true         # chart will create a Secret (secret: true) or ConfigMap (secret: false)
  secret: true         # optional; set false to use a ConfigMap
  data:
    PORTKEY_CLIENT_AUTH: "/mnt/secrets/PORTKEY_CLIENT_AUTH"
    ANALYTICS_STORE_USER: "/mnt/secrets/ANALYTICS_STORE_USER"
    ANALYTICS_STORE_PASSWORD: "/mnt/secrets/ANALYTICS_STORE_PASSWORD"
    REDIS_URL: "/mnt/secrets/REDIS_URL"
    LOG_STORE_ACCESS_KEY: "/mnt/secrets/LOG_STORE_ACCESS_KEY"
    LOG_STORE_SECRET_KEY: "/mnt/secrets/LOG_STORE_SECRET_KEY"
    AWS_ASSUME_ROLE_ACCESS_KEY_ID: "/mnt/secrets/AWS_ASSUME_ROLE_ACCESS_KEY_ID"
    AWS_ASSUME_ROLE_SECRET_ACCESS_KEY: "/mnt/secrets/AWS_ASSUME_ROLE_SECRET_ACCESS_KEY"
    AZURE_STORAGE_KEY: "/mnt/secrets/AZURE_STORAGE_KEY"
    # Other values can remain as plain strings:
    SERVICE_NAME: "portkeyenterprise"
    PORT: "8787"
    ANALYTICS_STORE: "clickhouse"
    LOG_STORE: "s3"
    LOG_STORE_REGION: "us-east-1"
    # ...and so on
```

Value handling:
- Normal string → used as-is.
- Filesystem path (e.g., `/mnt/secrets/PORTKEY_CLIENT_AUTH`) → the app reads the file contents at that path and uses it.

---

## Option C: Full Secret Override (sync everything)
Put all keys into the AWS secret and use the sync approach from Option A. The chart will source all env vars from `environment.existingSecret`, with `environment.data` acting purely as the list of variables to wire.

```yaml
# values.yaml
environment:
  create: false
  existingSecret: "portkey-gateway-env"
  data:
    SERVICE_NAME: ""
    PORT: ""
    PORTKEY_CLIENT_AUTH: ""
    # ...include every key you want wired
```

---

## Validate
- Driver/provider:
```bash
kubectl -n kube-system get pods -l app=secrets-store-csi-driver
kubectl -n kube-system get pods -l app.kubernetes.io/name=secrets-store-csi-driver-provider-aws
```
- SecretProviderClass:
```bash
kubectl -n portkeyai get secretproviderclass portkey-gateway-aws-secrets -o yaml
```
- Secret exists after pod starts (Option A/C):
```bash
kubectl -n portkeyai get secret portkey-gateway-env -o yaml
```
- Mount present on pods:
```bash
kubectl -n portkeyai get pods -l app.kubernetes.io/name=portkey-gateway
kubectl -n portkeyai exec -it deploy/<release>-portkey-gateway -- ls -l /mnt/secrets
```

## Rotation
- AWS Secrets Manager rotations update mounted files automatically.
- The synced Kubernetes Secret is also refreshed by the CSI driver (for Options A/C).
- Restart pods to ensure the application picks up updated env values, or use automation (e.g., Reloader) to roll on Secret changes.

## Troubleshooting
- Ensure IRSA role is attached to the service accounts and has required permissions.
- `SecretProviderClass` must be in the same namespace as gateway/dataservice.
- If the Kubernetes Secret is not created (Option A/C), ensure the CSI volume is mounted so sync is triggered.
- For mount-only, confirm keys appear as files under `/mnt/secrets` inside the pods.
- Any key not found in `existingSecret` (Option A) falls back to its literal in `environment.data`.

## References
- Secrets Store CSI Driver: `https://secrets-store-csi-driver.sigs.k8s.io/`
- AWS Provider for CSI Driver: `https://aws.github.io/secrets-store-csi-driver-provider-aws/`
- Sync secrets to Kubernetes Secrets: `https://secrets-store-csi-driver.sigs.k8s.io/topics/sync-as-kubernetes-secret.html`
- Secret rotation with CSI Driver: `https://secrets-store-csi-driver.sigs.k8s.io/topics/secret-auto-rotation`
