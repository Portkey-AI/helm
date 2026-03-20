# ClickHouse Replication

The built-in ClickHouse StatefulSet shipped with this chart runs a single-node instance and does not support replication. For production workloads that require high availability and replicated tables, deploy ClickHouse separately using a dedicated chart and point Portkey at it as an external data store.

## Prerequisites

- A running Kubernetes cluster
- `helm` v3 installed
- `kubectl` configured for your cluster

## Deploy Replicated ClickHouse with Altinity Helm Chart

The [Altinity Helm Charts](https://github.com/Altinity/helm-charts) project provides a production-grade ClickHouse chart backed by the Altinity Operator. It supports multi-replica, multi-shard clusters with ClickHouse Keeper for coordination.

### Step 1: Add the Altinity Helm Repository

```bash
helm repo add altinity https://altinity.github.io/helm-charts
helm repo update
```

### Step 2: Create a Values File

Create a file called `clickhouse-replicated-values.yaml`:

```yaml
clickhouse:
  replicasCount: 2
  shardsCount: 1

  defaultUser:
    password: "<your-clickhouse-password>"
    allowExternalAccess: true

  clusterSecret:
    enabled: true
    auto: true

  persistence:
    enabled: true
    size: 50Gi
    storageClass: "" # set to your preferred StorageClass (e.g. gp3, standard)

  service:
    type: ClusterIP

  settings:
    max_table_size_to_drop: "0"

keeper:
  enabled: true
  replicaCount: 3
  localStorage:
    size: 5Gi

operator:
  enabled: true # set to false if the Altinity Operator is already installed
```

Adjust `replicasCount`, `shardsCount`, keeper `replicaCount`, and storage sizes to match your requirements.

### Step 3: Install the Chart

```bash
helm install portkey altinity/clickhouse \
  -f clickhouse-replicated-values.yaml \
  -n portkey \
  --create-namespace
```

### Step 4: Get the ClickHouse Service Endpoint

After the pods are running, get the service name:

```bash
kubectl get svc -n portkey -l app.kubernetes.io/name=clickhouse
```

The service name will typically follow the pattern `clickhouse-<release>`. Use this as the host when configuring Portkey.

## Configure Portkey to Use External Replicated ClickHouse

In your Portkey Helm values file, disable the built-in ClickHouse and point to the external cluster:

```yaml
clickhouse:
  external:
    enabled: true
    host: "<clickhouse-service-name>.<namespace>.svc.cluster.local"
    port: "8123"
    nativePort: "9000"
    user: "default"
    password: "<your-clickhouse-password>"
    database: "default"
    tls: false
    replicationEnabled: true
    shardingEnabled: false
    clusterName: "portkey"
```

When `replicationEnabled: true`, the backend runs migrations using `ReplicatedMergeTree` instead of `MergeTree` and creates the database with `ENGINE = Replicated(...)`.

When `shardingEnabled: true`, the backend additionally creates `_local` tables and `Distributed` tables on top, and all DDL is executed with `ON CLUSTER`.

`clusterName` must match the cluster name in your ClickHouse deployment. When using the Altinity Helm chart, the cluster name is the same as the Helm release name (truncated to 15 characters). For example, `helm install portkey altinity/clickhouse ...` creates a cluster named `portkey`.

> **Note:** The release name should only contain alphanumeric characters and underscores (`_`). Other special characters (e.g. `-`, `.`, `+`) are not supported in ClickHouse cluster names.

Then deploy or upgrade Portkey:

```bash
helm upgrade --install portkey portkey/portkey-app \
  -f portkey-values.yaml \
  -n portkey
```

### Using an Existing Secret

If you manage secrets externally, create a Kubernetes secret with these keys:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: portkey-clickhouse-external
  namespace: portkey
type: Opaque
stringData:
  store: "clickhouse"
  clickhouse_user: "default"
  clickhouse_password: "<password>"
  clickhouse_host: "<host>"
  clickhouse_port: "8123"
  clickhouse_native_port: "9000"
  clickhouse_db: "default"
  clickhouse_tls: "false"
  clickhouse_replication_enabled: "true"
  clickhouse_sharding_enabled: "false"
  clickhouse_cluster_name: "portkey_cluster"
```

Then reference it in your values:

```yaml
clickhouse:
  external:
    enabled: true
    existingSecretName: "portkey-clickhouse-external"
```

## Environment Variables

The following environment variables are set on Portkey services from these values:

| Helm Value | Backend / Data Service Env | Gateway Env |
|------------|---------------------------|-------------|
| `replicationEnabled` | `CLICKHOUSE_REPLICATION_ENABLED` | `ANALYTICS_STORE_REPLICATION_ENABLED` |
| `shardingEnabled` | `CLICKHOUSE_SHARDING_ENABLED` | `ANALYTICS_STORE_SHARDING_ENABLED` |
| `clusterName` | `CLICKHOUSE_CLUSTER_NAME` | `ANALYTICS_STORE_CLUSTER_NAME` |

## Migration Behavior

| Mode | `replicationEnabled` | `shardingEnabled` | What Happens |
|------|---------------------|-------------------|--------------|
| Single-node | `false` | `false` | `MergeTree` tables, no cluster DDL |
| Replicated | `true` | `false` | `ReplicatedMergeTree` tables, `ON CLUSTER` DDL, Replicated database engine |
| Sharded | `false` | `true` | `MergeTree` local tables + `Distributed` tables, `ON CLUSTER` DDL |
| Replicated + Sharded | `true` | `true` | `ReplicatedMergeTree` local tables + `Distributed` tables, `ON CLUSTER` DDL, Replicated database engine |

## Scaling Considerations

| Parameter | Guidance |
|-----------|----------|
| `replicasCount` | 2+ for HA. Each replica holds a full copy of every shard's data. |
| `shardsCount` | Increase to distribute data horizontally when a single replica can't hold the full dataset. |
| `keeper.replicaCount` | Must be an odd number (3 or 5). Do **not** change after initial deployment. |
| `persistence.size` | Size per replica. Plan for data growth + merge overhead (~2x working set). |
