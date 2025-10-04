### Portkey Gateway — HashiCorp Vault Integration

Portkey Gateway supports HashiCorp Vault for secrets. You can either sync Vault secrets into a Kubernetes Secret (preferred for partial override), or mount secrets as files using the Vault Agent Injector and point values to file paths.

- Preferred: Partial Secret Override (Vault → Kubernetes Secret for selected keys; other keys from `values.yaml`)
- Supported: Full Secret Override (all keys from the Kubernetes Secret)
- Supported: Mount-only File Paths (no Kubernetes Secret sync; values are file paths that the app reads)

Applications accept values as either normal strings or filesystem paths. If the value looks like a path (e.g., `/vault/secrets/PORTKEY_CLIENT_AUTH`), the app reads the file contents at that path and uses that value.

## Prerequisites
1. Kubernetes cluster and `kubectl` access
2. Vault server reachable from the cluster
3. Vault Kubernetes auth configured (service account JWT verification)
4. Namespace created (e.g., `portkeyai`)

Vault setup (high level):
- Enable Kubernetes auth and create a role bound to your namespace/service account.
- Create a policy allowing read of your secret path(s).

Example: Kubernetes auth and role
```bash
vault auth enable kubernetes

# Point to Kubernetes API and SA JWTs (cluster-specific)
vault write auth/kubernetes/config \
  kubernetes_host="https://$K8S_HOST" \
  kubernetes_ca_cert=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  token_reviewer_jwt="$TOKEN_REVIEWER_JWT"

# Policy to read secrets
vault policy write portkey-gateway - <<EOF
path "kv/data/portkey/gateway/config" {
  capabilities = ["read"]
}
EOF

# Role that binds to namespace and service account
vault write auth/kubernetes/role/portkey-gateway \
  bound_service_account_names="default,portkey-gateway,portkey-gateway-dataservice" \
  bound_service_account_namespaces="portkeyai" \
  policies="portkey-gateway" \
  ttl="24h"
```

---

## What can be sourced from Vault?
Use the keys defined under `environment.data` in `values.yaml`. Common keys include:
- Core: `SERVICE_NAME`, `PORT`, `PORTKEY_CLIENT_AUTH`, `ORGANISATIONS_TO_SYNC`
- Analytics: `ANALYTICS_STORE`, `ANALYTICS_STORE_ENDPOINT`, `ANALYTICS_STORE_USER`, `ANALYTICS_STORE_PASSWORD`, `ANALYTICS_LOG_TABLE`, `ANALYTICS_FEEDBACK_TABLE`
- Cache: `CACHE_STORE`, `REDIS_URL`, `REDIS_TLS_ENABLED`, `REDIS_MODE`
- Log Store: `LOG_STORE`, `LOG_STORE_REGION`, `LOG_STORE_ACCESS_KEY`, `LOG_STORE_SECRET_KEY`, `LOG_STORE_GENERATIONS_BUCKET`, `LOG_STORE_BASEPATH`, `LOG_STORE_AWS_ROLE_ARN`, `LOG_STORE_AWS_EXTERNAL_ID`
- AWS Assume Role: `AWS_ASSUME_ROLE_ACCESS_KEY_ID`, `AWS_ASSUME_ROLE_SECRET_ACCESS_KEY`, `AWS_ASSUME_ROLE_REGION`
- Azure Blob: `AZURE_AUTH_MODE`, `AZURE_MANAGED_CLIENT_ID`, `AZURE_STORAGE_ACCOUNT`, `AZURE_STORAGE_KEY`, `AZURE_STORAGE_CONTAINER`
- Dataservice (if enabled): `FINETUNES_BUCKET`, `LOG_EXPORTS_BUCKET`, `FINETUNES_AWS_ROLE_ARN`

Include only the keys you want to source from Vault; others can remain as literals in `values.yaml`.

---

## Option A (Preferred): Partial Secret Override (Vault → K8s Secret)
Sync selected keys from Vault into a Kubernetes Secret, then point the chart to that Secret. Missing keys fall back to literals in `values.yaml`.

You can use External Secrets Operator (ESO) or Vault Secrets Operator. Below is an ESO example.

### 1) SecretStore (Vault backend, Kubernetes auth)
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ClusterSecretStore
metadata:
  name: vault-store
spec:
  provider:
    vault:
      server: "https://vault.yourdomain.com"
      path: "kv"                            # KV v2 mount (alias)
      version: "v2"
      auth:
        kubernetes:
          mountPath: "auth/kubernetes"
          role: "portkey-gateway"           # Vault role bound to SA/namespace
          serviceAccountRef:
            name: "portkey-gateway"         # SA used by the deployment (or 'default')
            namespace: "portkeyai"
```

### 2) ExternalSecret (map Vault fields → K8s Secret)
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: portkey-gateway-env
  namespace: portkeyai
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: vault-store
    kind: ClusterSecretStore
  target:
    name: portkey-gateway-env
    creationPolicy: Owner
  data:
    - secretKey: PORTKEY_CLIENT_AUTH
      remoteRef:
        key: kv/data/portkey/gateway/config
        property: PORTKEY_CLIENT_AUTH
    - secretKey: ANALYTICS_STORE_USER
      remoteRef:
        key: kv/data/portkey/gateway/config
        property: ANALYTICS_STORE_USER
    - secretKey: ANALYTICS_STORE_PASSWORD
      remoteRef:
        key: kv/data/portkey/gateway/config
        property: ANALYTICS_STORE_PASSWORD
    - secretKey: REDIS_URL
      remoteRef:
        key: kv/data/portkey/gateway/config
        property: REDIS_URL
    # ...add any keys you want synced
```

### 3) Configure the chart (partial override)
```yaml
# values.yaml
environment:
  create: false
  existingSecret: "portkey-gateway-env"
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
- If a key exists in the Secret, it’s injected from the Secret.
- If a key is absent in the Secret, the literal value from `environment.data` is injected.
- Keep all variables you need listed under `environment.data`.

Note:
- Do not enable `useVaultInjection` for this option. The operator syncs the Secret; the chart consumes it via `existingSecret`.

---

## Option B: Mount-only (Vault Agent Injector; read from files)
Use the Vault Agent Injector to mount secrets as files in the pod, then set `environment.data` to file paths. The app reads file contents when a value looks like a filesystem path.

Install the Vault Agent Injector (MutatingWebhook) in your cluster, then annotate the workloads to inject the sidecar.

### 1) Add Vault injector annotations to the pod
You can use `podAnnotations` in values to add per-key templates. Example for individual files under `/vault/secrets`:

```yaml
# values.yaml
podAnnotations:
  vault.hashicorp.com/agent-inject: "true"
  vault.hashicorp.com/role: "portkey-gateway"
  # Example: write a single key to a dedicated file
  vault.hashicorp.com/agent-inject-secret-PORTKEY_CLIENT_AUTH: "kv/data/portkey/gateway/config"
  vault.hashicorp.com/agent-inject-template-PORTKEY_CLIENT_AUTH: |
    {{- with secret "kv/data/portkey/gateway/config" -}}{{ .Data.data.PORTKEY_CLIENT_AUTH }}{{- end }}

  vault.hashicorp.com/agent-inject-secret-ANALYTICS_STORE_USER: "kv/data/portkey/gateway/config"
  vault.hashicorp.com/agent-inject-template-ANALYTICS_STORE_USER: |
    {{- with secret "kv/data/portkey/gateway/config" -}}{{ .Data.data.ANALYTICS_STORE_USER }}{{- end }}

  vault.hashicorp.com/agent-inject-secret-ANALYTICS_STORE_PASSWORD: "kv/data/portkey/gateway/config"
  vault.hashicorp.com/agent-inject-template-ANALYTICS_STORE_PASSWORD: |
    {{- with secret "kv/data/portkey/gateway/config" -}}{{ .Data.data.ANALYTICS_STORE_PASSWORD }}{{- end }}

  vault.hashicorp.com/agent-inject-secret-REDIS_URL: "kv/data/portkey/gateway/config"
  vault.hashicorp.com/agent-inject-template-REDIS_URL: |
    {{- with secret "kv/data/portkey/gateway/config" -}}{{ .Data.data.REDIS_URL }}{{- end }}
```

Notes:
- Default injection path is `/vault/secrets/<NAME>`. With the above templates, files are:
  - `/vault/secrets/PORTKEY_CLIENT_AUTH`
  - `/vault/secrets/ANALYTICS_STORE_USER`
  - etc.

### 2) Set values to file paths (partial or full)
```yaml
# values.yaml
environment:
  create: true       # chart creates a Secret (secret: true) or ConfigMap (secret: false)
  secret: true       # optional; set false to use a ConfigMap
  data:
    PORTKEY_CLIENT_AUTH: "/vault/secrets/PORTKEY_CLIENT_AUTH"
    ANALYTICS_STORE_USER: "/vault/secrets/ANALYTICS_STORE_USER"
    ANALYTICS_STORE_PASSWORD: "/vault/secrets/ANALYTICS_STORE_PASSWORD"
    REDIS_URL: "/vault/secrets/REDIS_URL"
    # Others as normal strings:
    SERVICE_NAME: "portkeyenterprise"
    PORT: "8787"
    ANALYTICS_STORE: "control_plane"
    LOG_STORE: "s3"
    LOG_STORE_REGION: "us-east-1"
    # ...and so on
```

Value handling:
- Normal string → used as-is.
- Filesystem path (e.g., `/vault/secrets/PORTKEY_CLIENT_AUTH`) → the app reads the file contents at that path.

Important:
- Do not enable `useVaultInjection` for mount-only. Add annotations via `podAnnotations` as shown so envs remain plain strings pointing to file paths.

---

## Option C: Full Secret Override (sync everything)
Put all keys into Vault and sync them into a single Kubernetes Secret (via ESO or Vault Secrets Operator), then reference it in `values.yaml`.

```yaml
# values.yaml
environment:
  create: false
  existingSecret: "portkey-gateway-env"
  data:
    SERVICE_NAME: ""
    PORT: ""
    PORTKEY_CLIENT_AUTH: ""
    ANALYTICS_STORE: ""
    # ...include every key you want wired
```

---

## Dataservice (optional)
If `dataservice.enabled=true`, apply the same pattern (Option A/B/C). For mount-only, add the same Vault injector annotations under `dataservice.deployment.annotations` (or reuse chart-level `podAnnotations`), and set relevant `dataservice` values to file paths as needed (e.g., `FINETUNES_BUCKET`, `LOG_EXPORTS_BUCKET`, `FINETUNES_AWS_ROLE_ARN`, and analytics credentials if used by dataservice).

---

## Validation
- Vault injector pods (if using mount-only):
```bash
kubectl -n portkeyai get pods -l app.kubernetes.io/name=portkey-gateway
kubectl -n portkeyai describe pod <pod-name> | grep -i vault
kubectl -n portkeyai exec -it deploy/<release>-portkey-gateway -- ls -l /vault/secrets
```
- ExternalSecrets (if using ESO):
```bash
kubectl -n portkeyai get externalsecret portkey-gateway-env -o yaml
kubectl -n portkeyai get secret portkey-gateway-env -o yaml
```
- Env wiring:
```bash
kubectl -n portkeyai describe deploy/<release>-portkey-gateway | grep -A2 "Environment:"
```

## Rotation
- Vault Agent Injector: files rotate automatically; if the app caches values, restart pods to pick changes.
- ESO / Vault Secrets Operator: synced Kubernetes Secret updates automatically; restart pods or use automation (e.g., Reloader) to roll on Secret changes.

## Notes on `useVaultInjection` in this chart
The chart supports a `useVaultInjection` flag and `vaultConfig` for adding base injector annotations, but it also rewires env vars to read from a Kubernetes Secret named by `vaultConfig.kubernetesSecret`. For the approaches above:
- Option A/C (sync to K8s Secret): leave `useVaultInjection: false`, rely on the operator to create the Secret, and set `environment.existingSecret`.
- Option B (mount-only files): leave `useVaultInjection: false`; add detailed Vault annotations via `podAnnotations` and set values to file paths.

```yaml
# values.yaml (reference)
useVaultInjection: false
vaultConfig:
  vaultHost: vault.hashicorp.com
  secretPath: "kv/data/portkey/gateway/config"
  role: "portkey-gateway"
  kubernetesSecret: ""  # only used if you wire your own Secret outside of ESO paths
```

## References
- Vault Agent Injector: `https://developer.hashicorp.com/vault/docs/platform/k8s/injector`
- Vault Kubernetes Auth: `https://developer.hashicorp.com/vault/docs/auth/kubernetes`
- External Secrets Operator: `https://external-secrets.io/latest/`
- Vault Secrets Operator: `https://developer.hashicorp.com/vault/docs/platform/k8s/vso`
