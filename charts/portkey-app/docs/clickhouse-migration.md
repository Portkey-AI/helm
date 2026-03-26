# Migrating ClickHouse from Built-in to External Cluster

This guide walks through migrating data from the single-node ClickHouse instance shipped with this chart to an external ClickHouse cluster (e.g. Altinity).

---

## Prerequisites

- `kubectl` access to the namespace running Portkey
- New external ClickHouse cluster deployed (see [clickhouse-replication.md](clickhouse-replication.md))
- `clickhouse-client` installed locally
- Enough disk on a local machine to hold the exported data

## Tables to Migrate

| Table | Timestamp Column |
|-------|-----------------|
| `generations` | `created_at` |
| `feedbacks` | `created_at` |
| `generation_hooks` | `created_at` |
| `audit_logs` | `timestamp` |

---

## Step 1: Enable Migration Mode

Before switching to the external cluster, enable migration mode to keep the old in-cluster ClickHouse alive alongside the new external one. This ensures you can still access the old data for export.

**Without existing secrets** (credentials in values):

```yaml
clickhouse:
  external:
    enabled: true
    host: "<new-clickhouse-host>"
    port: "8123"
    nativePort: "9000"
    user: "default"
    password: "<new-ch-password>"
    database: "default"
    replicationEnabled: true
    shardingEnabled: false
    clusterName: "portkey"
  migration:
    enabled: true
    oldCredentials:
      user: "default"
      password: "<old-ch-password>"
      database: "default"
```

**With existing secrets** (credentials managed externally):

```yaml
clickhouse:
  external:
    enabled: true
    existingSecretName: "clickhouse-secret-new"
  migration:
    enabled: true
    oldCredentials:
      existingSecretName: "clickhouse-secret-old"
```

The old credentials secret must have `clickhouse_user`, `clickhouse_password`, and `clickhouse_db` keys. The new credentials secret must have all standard keys (`clickhouse_host`, `clickhouse_port`, `clickhouse_native_port`, `clickhouse_user`, `clickhouse_password`, `clickhouse_db`).

If old and new ClickHouse share the same credentials, omit `oldCredentials` entirely -- it falls back to the external credentials.

Run the upgrade:

```bash
helm upgrade <release> portkey/portkey-app \
  -f values.yaml \
  -n <namespace>
```

This will:

1. Switch the application to the new external ClickHouse immediately.
2. Keep the old in-cluster ClickHouse StatefulSet and Service alive so you can export data.

### Configuration Reference

| Value | Default | Description |
|-------|---------|-------------|
| `clickhouse.migration.enabled` | `false` | Keep old in-cluster ClickHouse alive while using external |
| `clickhouse.migration.oldCredentials.existingSecretName` | `""` | Secret with old CH credentials (`clickhouse_user`, `clickhouse_password`, `clickhouse_db` keys) |
| `clickhouse.migration.oldCredentials.user` | `""` | Old CH username (plain value, used when no secret is set) |
| `clickhouse.migration.oldCredentials.password` | `""` | Old CH password (plain value, used when no secret is set) |
| `clickhouse.migration.oldCredentials.database` | `""` | Old CH database name (falls back to `external.database` if empty) |

## Step 2: Port-Forward Both Clusters

Old (built-in) instance:

```bash
kubectl port-forward svc/<release>-portkey-app-clickhouse 9000:9000 -n <namespace>
```

New (external) cluster:

```bash
kubectl port-forward svc/<new-clickhouse-svc> 9001:9000 -n <namespace>
```

You now have the old instance on `localhost:9000` and the new cluster on `localhost:9001`.

## Step 3: Export Data from the Old Instance

```bash
for table in generations feedbacks generation_hooks audit_logs; do
  echo "Exporting ${table}..."
  clickhouse-client --host localhost --port 9000 \
    --user "<old-ch-user>" --password "<old-ch-password>" \
    --query "SELECT * FROM default.${table} FORMAT Native" \
    > "${table}.native"
  echo "Done: $(ls -lh ${table}.native | awk '{print $5}')"
done
```

For very large tables, export in chunks by time range:

```bash
clickhouse-client --host localhost --port 9000 \
  --user "<old-ch-user>" --password "<old-ch-password>" \
  --query "SELECT * FROM default.generations WHERE created_at >= '2025-01-01' AND created_at < '2025-02-01' FORMAT Native" \
  > generations_2025_01.native
```

## Step 4: Import Data into the New Cluster

Wait for the backend to create tables on the new cluster (it does this automatically on startup), then import:

```bash
for table in generations feedbacks generation_hooks audit_logs; do
  echo "Importing ${table}..."
  clickhouse-client --host localhost --port 9001 \
    --user "<new-ch-user>" --password "<new-ch-password>" \
    --query "INSERT INTO default.${table} FORMAT Native" \
    < "${table}.native"
  echo "Done."
done
```

## Step 5: Verify Data Integrity

```bash
for table in generations feedbacks generation_hooks audit_logs; do
  old=$(clickhouse-client --host localhost --port 9000 \
    --user "<old-ch-user>" --password "<old-ch-password>" \
    --query "SELECT count() FROM default.${table}")
  new=$(clickhouse-client --host localhost --port 9001 \
    --user "<new-ch-user>" --password "<new-ch-password>" \
    --query "SELECT count() FROM default.${table}")
  echo "${table}: old=${old} new=${new} $([ "$old" = "$new" ] && echo 'OK' || echo 'MISMATCH')"
done
```

## Step 6: Decommission the Old Instance

Once verified, disable migration mode to remove the old in-cluster ClickHouse:

```yaml
clickhouse:
  external:
    enabled: true
    # ... same external config as above
  migration:
    enabled: false
```

```bash
helm upgrade <release> portkey/portkey-app \
  -f values.yaml \
  -n <namespace>
```

This deletes the old StatefulSet, Service, ConfigMap, and ServiceAccount. Clean up the PVC if persistence was enabled:

```bash
kubectl delete pvc -l app.kubernetes.io/component=<release>-portkey-app-clickhouse -n <namespace>
```

Remove the exported `.native` files from your local machine.

## Rollback

To revert to the built-in ClickHouse:

```yaml
clickhouse:
  external:
    enabled: false
  migration:
    enabled: false
```

```bash
helm upgrade <release> portkey/portkey-app \
  -f values.yaml \
  -n <namespace>
```

If the PVC was not deleted, data will still be intact on the in-cluster instance. If it was deleted, the backend will create empty tables on a fresh instance -- re-import from your exported files.
