Portkey supports comprehensive AWS Secrets Manager integration.

This guide covers two supported patterns:
- Syncing AWS secrets into Kubernetes Secrets (recommended)
- Mount-only: read secrets directly from files on a CSI volume

Applications accept values either as direct strings or as filesystem paths. For example:
- Direct value: `config.oauth.oauthIssuerUrl: "https://test.com/callback"`
- Path value: `config.oauth.oauthIssuerUrl: "/mnt/secrets/oauthIssuerUrl"` (the app reads file contents at this path)

## Prerequisites
1. Amazon EKS cluster (v1.23+ recommended)
2. AWS CLI configured and `kubectl` access
3. An IRSA role with `secretsmanager:GetSecretValue` and `secretsmanager:DescribeSecret`.
4. Portkey release namespace created (e.g., `portkey`)

[Example IAM policy](https://docs.aws.amazon.com/secretsmanager/latest/userguide/auth-and-access_iam-policies.html#auth-and-access_examples-read-and-describe) for IRSA:
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
      "Resource": "arn:aws:secretsmanager:<REGION>:<ACCOUNT_ID>:secret:myapp/*"
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
Annotate the service accounts used by `backend`, `gateway`, and `dataservice`:
```yaml
backend:
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::<ACCOUNT_ID>:role/<YOUR_IRSA_ROLE>"

gateway:
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::<ACCOUNT_ID>:role/<YOUR_IRSA_ROLE>"

dataservice:
  serviceAccount:
    create: true
    annotations:
      eks.amazonaws.com/role-arn: "arn:aws:iam::<ACCOUNT_ID>:role/<YOUR_IRSA_ROLE>"
```

## Option A (recommended): Sync AWS Secrets → Kubernetes Secrets
Create a `SecretProviderClass` that both fetches from AWS and syncs Kubernetes Secrets with keys this chart expects.

Save as `secretproviderclass.yaml`:
```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: portkey-app-aws-secrets
  namespace: portkey
spec:
  provider: aws
  parameters:
    objects: |
      - objectName: "arn:aws:secretsmanager:<REGION>:<ACCOUNT_ID>:secret:myapp/mysql"
        objectType: "secretsmanager"
        jmesPath:
          - path: host
            objectAlias: mysql_host
          - path: port
            objectAlias: mysql_port
          - path: username
            objectAlias: mysql_user
          - path: password
            objectAlias: mysql_password
          - path: database
            objectAlias: mysql_db
          - path: sslMode
            objectAlias: mysql_ssl_mode
      - objectName: "arn:aws:secretsmanager:<REGION>:<ACCOUNT_ID>:secret:myapp/redis"
        objectType: "secretsmanager"
        jmesPath:
          - path: connectionUrl
            objectAlias: redis_connection_url
          - path: tlsEnabled
            objectAlias: redis_tls_enabled
          - path: mode
            objectAlias: redis_mode
          - path: store
            objectAlias: redis_store
      - objectName: "arn:aws:secretsmanager:<REGION>:<ACCOUNT_ID>:secret:myapp/clickhouse"
        objectType: "secretsmanager"
        jmesPath:
          - path: store
            objectAlias: store
          - path: user
            objectAlias: clickhouse_user
          - path: password
            objectAlias: clickhouse_password
          - path: host
            objectAlias: clickhouse_host
          - path: port
            objectAlias: clickhouse_port
          - path: nativePort
            objectAlias: clickhouse_native_port
          - path: database
            objectAlias: clickhouse_db
          - path: tls
            objectAlias: clickhouse_tls
      - objectName: "arn:aws:secretsmanager:<REGION>:<ACCOUNT_ID>:secret:myapp/portkey-config"
        objectType: "secretsmanager"
        jmesPath:
          - path: jwtPrivateKey
            objectAlias: jwtPrivateKey
          - path: oauthType
            objectAlias: oauthType
          - path: oauthIssuerUrl
            objectAlias: oauthIssuerUrl
          - path: oauthClientId
            objectAlias: oauthClientId
          - path: oauthClientSecret
            objectAlias: oauthClientSecret
          - path: oauthRedirectURI
            objectAlias: oauthRedirectURI
          - path: oauthMetadataXml
            objectAlias: oauthMetadataXml
          - path: smtpHost
            objectAlias: smtpHost
          - path: smtpPort
            objectAlias: smtpPort
          - path: smtpUser
            objectAlias: smtpUser
          - path: smtpPassword
            objectAlias: smtpPassword
          - path: smtpFrom
            objectAlias: smtpFrom
  secretObjects:
    - secretName: portkey-mysql
      type: Opaque
      data:
        - objectName: mysql_user
          key: mysql_user
        - objectName: mysql_password
          key: mysql_password
        - objectName: mysql_host
          key: mysql_host
        - objectName: mysql_port
          key: mysql_port
        - objectName: mysql_db
          key: mysql_db
        - objectName: mysql_ssl_mode
          key: mysql_ssl_mode
    - secretName: portkey-redis
      type: Opaque
      data:
        - objectName: redis_connection_url
          key: redis_connection_url
        - objectName: redis_tls_enabled
          key: redis_tls_enabled
        - objectName: redis_mode
          key: redis_mode
        - objectName: redis_store
          key: redis_store
    - secretName: portkey-clickhouse
      type: Opaque
      data:
        - objectName: store
          key: store
        - objectName: clickhouse_user
          key: clickhouse_user
        - objectName: clickhouse_password
          key: clickhouse_password
        - objectName: clickhouse_host
          key: clickhouse_host
        - objectName: clickhouse_port
          key: clickhouse_port
        - objectName: clickhouse_native_port
          key: clickhouse_native_port
        - objectName: clickhouse_db
          key: clickhouse_db
        - objectName: clickhouse_tls
          key: clickhouse_tls
    - secretName: portkey-config
      type: Opaque
      data:
        - objectName: jwtPrivateKey
          key: jwtPrivateKey
        - objectName: oauthType
          key: oauthType
        - objectName: oauthIssuerUrl
          key: oauthIssuerUrl
        - objectName: oauthClientId
          key: oauthClientId
        - objectName: oauthClientSecret
          key: oauthClientSecret
        - objectName: oauthRedirectURI
          key: oauthRedirectURI
        - objectName: oauthMetadataXml
          key: oauthMetadataXml
        - objectName: smtpHost
          key: smtpHost
        - objectName: smtpPort
          key: smtpPort
        - objectName: smtpUser
          key: smtpUser
        - objectName: smtpPassword
          key: smtpPassword
        - objectName: smtpFrom
          key: smtpFrom
```

Apply:
```bash
kubectl apply -f secretproviderclass.yaml
```

Mount to trigger sync on each workload:
```yaml
backend:
  deployment:
    volumes:
      - name: portkey-secrets-store
        csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: "portkey-app-aws-secrets"
    volumeMounts:
      - name: portkey-secrets-store
        mountPath: "/mnt/secrets"
        readOnly: true

gateway:
  deployment:
    volumes:
      - name: portkey-secrets-store
        csi:
          driver: secrets-store.csi.k8s.io
          readOnly: true
          volumeAttributes:
            secretProviderClass: "portkey-app-aws-secrets"
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
            secretProviderClass: "portkey-app-aws-secrets"
    volumeMounts:
      - name: portkey-secrets-store
        mountPath: "/mnt/secrets"
        readOnly: true
```

Point the chart at the synced Secrets:
```yaml
mysql:
  external:
    enabled: true
    existingSecretName: "portkey-mysql"

redis:
  external:
    enabled: true
    existingSecretName: "portkey-redis"

clickhouse:
  external:
    enabled: true
    existingSecretName: "portkey-clickhouse"

config:
  existingSecretName: "portkey-config"
  oauth:
    enabled: true
  smtp:
    enabled: true
```

## Option B: Mount-only (read from files; no Kubernetes Secrets sync)
Create a `SecretProviderClass` without `secretObjects` (files only):
```yaml
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: portkey-app-aws-secrets
  namespace: portkey
spec:
  provider: aws
  parameters:
    objects: |
      - objectName: "arn:aws:secretsmanager:<REGION>:<ACCOUNT_ID>:secret:myapp/mysql"
        objectType: "secretsmanager"
        jmesPath:
          - path: host
            objectAlias: mysql_host
          - path: port
            objectAlias: mysql_port
          - path: username
            objectAlias: mysql_user
          - path: password
            objectAlias: mysql_password
          - path: database
            objectAlias: mysql_db
          - path: sslMode
            objectAlias: mysql_ssl_mode
      - objectName: "arn:aws:secretsmanager:<REGION>:<ACCOUNT_ID>:secret:myapp/redis"
        objectType: "secretsmanager"
        jmesPath:
          - path: connectionUrl
            objectAlias: redis_connection_url
          - path: tlsEnabled
            objectAlias: redis_tls_enabled
          - path: mode
            objectAlias: redis_mode
          - path: store
            objectAlias: redis_store
      - objectName: "arn:aws:secretsmanager:<REGION>:<ACCOUNT_ID>:secret:myapp/portkey-config"
        objectType: "secretsmanager"
        jmesPath:
          - path: jwtPrivateKey
            objectAlias: jwtPrivateKey
          - path: oauthType
            objectAlias: oauthType
          - path: oauthIssuerUrl
            objectAlias: oauthIssuerUrl
          - path: oauthClientId
            objectAlias: oauthClientId
          - path: oauthClientSecret
            objectAlias: oauthClientSecret
          - path: oauthRedirectURI
            objectAlias: oauthRedirectURI
          - path: smtpHost
            objectAlias: smtpHost
          - path: smtpPort
            objectAlias: smtpPort
          - path: smtpUser
            objectAlias: smtpUser
          - path: smtpPassword
            objectAlias: smtpPassword
          - path: smtpFrom
            objectAlias: smtpFrom
```

Mount on workloads (same as above). Then set values to file paths under `/mnt/secrets`:
```yaml
mysql:
  external:
    enabled: true
    host: "/mnt/secrets/mysql_host"
    port: "/mnt/secrets/mysql_port"
    user: "/mnt/secrets/mysql_user"
    password: "/mnt/secrets/mysql_password"
    database: "/mnt/secrets/mysql_db"
    # optional if present:
    # ssl:
    #   enabled: true
    #   mode: "/mnt/secrets/mysql_ssl_mode"

redis:
  external:
    enabled: true
    connectionUrl: "/mnt/secrets/redis_connection_url"
    # optional if present:
    # tlsEnabled: "/mnt/secrets/redis_tls_enabled"
    # mode: "/mnt/secrets/redis_mode"
    # store: "/mnt/secrets/redis_store"

config:
  existingSecretName: ""   # let the chart create the Secret with your literal/path values
  oauth:
    enabled: true
    oauthType: "/mnt/secrets/oauthType"
    oauthIssuerUrl: "/mnt/secrets/oauthIssuerUrl"
    oauthClientId: "/mnt/secrets/oauthClientId"
    oauthClientSecret: "/mnt/secrets/oauthClientSecret"
    oauthRedirectURI: "/mnt/secrets/oauthRedirectURI"
  smtp:
    enabled: true
    smtpHost: "/mnt/secrets/smtpHost"
    smtpPort: "/mnt/secrets/smtpPort"
    smtpUser: "/mnt/secrets/smtpUser"
    smtpPassword: "/mnt/secrets/smtpPassword"
    smtpFrom: "/mnt/secrets/smtpFrom"
```

Value handling:
- If a value is a normal string (e.g., `https://...`), apps use it as-is.
- If a value is a filesystem path (e.g., `/mnt/secrets/oauthIssuerUrl`), apps read the file contents at that path and use that value.

## Validate
- Driver/provider:
```bash
kubectl -n kube-system get pods -l app=secrets-store-csi-driver
kubectl -n kube-system get pods -l app.kubernetes.io/name=secrets-store-csi-driver-provider-aws
```
- SecretProviderClass:
```bash
kubectl -n portkey get secretproviderclass portkey-app-aws-secrets -o yaml
```
- Mount present on pods:
```bash
kubectl -n portkey get pods -l app.kubernetes.io/name=portkey-app
kubectl -n portkey exec -it deploy/<release>-portkey-backend -- ls -l /mnt/secrets
```

## Rotation
- AWS Secrets Manager rotations update mounted files automatically.
- When consuming via env vars (Option A), restart pods to pick up new values if needed.
- When using file paths (Option B), many apps read on startup; restart pods if your configuration is loaded once at boot.

## Troubleshooting
- Ensure IRSA role is attached to the service accounts and has required permissions.
- `SecretProviderClass` must be in the same namespace as workloads.
- For mount-only, confirm keys exist as files under `/mnt/secrets` inside pods.


## References
- [Secrets Store CSI Driver docs](https://secrets-store-csi-driver.sigs.k8s.io/)
- [AWS Provider for CSI Driver](https://aws.github.io/secrets-store-csi-driver-provider-aws/)
- [Sync secrets to Kubernetes Secrets](https://secrets-store-csi-driver.sigs.k8s.io/topics/sync-as-kubernetes-secret.html)
- [Secret rotation with CSI Driver](https://secrets-store-csi-driver.sigs.k8s.io/topics/secret-auto-rotation)
- [AWS EKS IRSA With Secret Manager](https://docs.aws.amazon.com/secretsmanager/latest/userguide/integrating_ascp_irsa.html)