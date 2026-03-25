# Migrating ClickHouse from Built-in to External Replicated Cluster

This guide walks through migrating data from the single-node ClickHouse instance shipped with this chart to an external replicated ClickHouse cluster.

There are two approaches:

- **Automated migration** (recommended) -- uses a built-in Helm post-upgrade Job
- **Manual migration** -- export/import using `clickhouse-client`

---

## Automated Migration

The chart includes a migration mode that keeps the old in-cluster ClickHouse alive while switching the application to the new external instance, and runs a Job to copy all historical data automatically.

### Prerequisites

- New external ClickHouse cluster deployed (see [clickhouse-replication.md](clickhouse-replication.md))

### Step 1: Upgrade with Migration Enabled

Update your values to enable both the external connection and migration mode.

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

The old credentials secret must have `clickhouse_user` and `clickhouse_password` keys. The new credentials secret must have all standard keys (`clickhouse_host`, `clickhouse_port`, `clickhouse_native_port`, `clickhouse_user`, `clickhouse_password`, `clickhouse_db`).

If old and new ClickHouse share the same credentials, omit `oldCredentials` entirely -- it falls back to the external credentials.

Then run the upgrade:

```bash
helm upgrade portkey portkey/portkey-app \
  -f portkey-values.yaml \
  -n <namespace>
```

This will:

1. Switch the application to the new external ClickHouse immediately.
2. Keep the old in-cluster ClickHouse StatefulSet and Service alive.
3. Run a post-upgrade Job that waits for the application to create tables on the new instance, then copies all data from old to new.

The `helm upgrade` command will block until the migration Job completes. You can monitor progress in another terminal:

```bash
kubectl logs -f job/<release>-app-clickhouse-migration -n <namespace>
```

### Step 2: Verify

After the upgrade completes, verify the data was migrated:

```bash
# Port-forward the native port to the new ClickHouse
kubectl port-forward svc/<new-clickhouse-svc> 9000:9000 -n <namespace>

# Check row counts
for table in generations feedbacks generation_hooks audit_logs; do
  count=$(clickhouse-client --host localhost --port 9000 \
    --query "SELECT count() FROM default.${table}")
  echo "${table}: ${count} rows"
done
```

### Step 3: Decommission the Old Instance

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
helm upgrade portkey portkey/portkey-app \
  -f portkey-values.yaml \
  -n <namespace>
```

This deletes the old StatefulSet, Service, ConfigMap, and ServiceAccount. If persistence was enabled, clean up the PVC:

```bash
kubectl delete pvc -l app.kubernetes.io/component=<release>-app-clickhouse -n <namespace>
```

### Configuration Reference

| Value | Default | Description |
|-------|---------|-------------|
| `clickhouse.migration.enabled` | `false` | Enable migration mode |
| `clickhouse.migration.oldCredentials.existingSecretName` | `""` | Secret with old CH credentials (`clickhouse_user`, `clickhouse_password` keys) |
| `clickhouse.migration.oldCredentials.user` | `""` | Old CH username (plain value, used when no secret is set) |
| `clickhouse.migration.oldCredentials.password` | `""` | Old CH password (plain value, used when no secret is set) |
| `clickhouse.migration.maxBlockSize` | `65536` | Number of rows per block during data transfer (controls memory usage) |
| `clickhouse.migration.resources` | `{}` | Resource requests/limits for the Job pod |
| `clickhouse.migration.backoffLimit` | `3` | Number of retries on failure |
| `clickhouse.migration.activeDeadlineSeconds` | `7200` | Maximum time (seconds) before the Job is killed |



### Failure Handling

- The Job truncates each table on the new CH before copying, so retries never cause duplicate data.
- If the Job fails, `helm upgrade` reports failure. The old ClickHouse is still alive (migration mode keeps it running), so no data is lost.
- Check Job logs: `kubectl logs job/<release>-app-clickhouse-migration -n <namespace>`
- Fix the issue and re-run `helm upgrade` with the same values (the hook-delete-policy `before-hook-creation` cleans up the old Job automatically).

### Rollback

To revert to the built-in ClickHouse:

```yaml
clickhouse:
  external:
    enabled: false
  migration:
    enabled: false
```

If the PVC was not deleted, data will still be intact on the in-cluster instance.

---

## Manual Migration

If you prefer manual control or the automated migration doesn't fit your use case, follow this step-by-step process.

### Prerequisites

- `kubectl` access to the namespace running Portkey
- New replicated ClickHouse cluster deployed (see [clickhouse-replication.md](clickhouse-replication.md))
- `clickhouse-client` installed locally
- Enough disk on a local machine to hold the exported data

### Tables to Migrate

| Table | Timestamp Column |
|-------|-----------------|
| `generations` | `created_at` |
| `feedbacks` | `created_at` |
| `generation_hooks` | `created_at` |
| `audit_logs` | `timestamp` |

### Step 1: Deploy the New Replicated Cluster

Follow the [ClickHouse Replication](clickhouse-replication.md) guide to deploy a replicated cluster. **Do not** update the Portkey values yet -- the old instance stays active during migration.

### Step 2: Port-Forward Both Clusters

Old (built-in) instance:

```bash
kubectl port-forward svc/<release>-app-clickhouse 9000:9000 -n <namespace>
```

New (replicated) cluster:

```bash
kubectl port-forward svc/<new-clickhouse-svc> 9001:9000 -n <namespace>
```

You now have the old instance on `localhost:9000` and the new cluster on `localhost:9001`.

### Step 3: Export Data from the Old Instance

```bash
for table in generations feedbacks generation_hooks audit_logs; do
  echo "Exporting ${table}..."
  clickhouse-client --host localhost --port 9000 \
    --query "SELECT * FROM default.${table} FORMAT Native" \
    > "${table}.native"
  echo "Done: $(ls -lh ${table}.native | awk '{print $5}')"
done
```

For very large tables, export in chunks by time range:

```bash
clickhouse-client --host localhost --port 9000 \
  --query "SELECT * FROM default.generations WHERE created_at >= '2025-01-01' AND created_at < '2025-02-01' FORMAT Native" \
  > generations_2025_01.native
```

### Step 4: Switch Portkey to the New Cluster

Update your Portkey values to point at the new cluster, then upgrade:

```yaml
clickhouse:
  external:
    enabled: true
    host: "<new-clickhouse-svc>.<namespace>.svc.cluster.local"
    port: "8123"
    nativePort: "9000"
    user: "default"
    password: "<password>"
    database: "default"
    replicationEnabled: true
    shardingEnabled: false
    clusterName: "portkey"
```

```bash
helm upgrade portkey portkey/portkey-app \
  -f portkey-values.yaml \
  -n <namespace>
```

The backend will create all tables with `ReplicatedMergeTree` engines automatically.

### Step 5: Import Data into the New Cluster

```bash
for table in generations feedbacks generation_hooks audit_logs; do
  echo "Importing ${table}..."
  clickhouse-client --host localhost --port 9001 \
    --query "INSERT INTO default.${table} FORMAT Native" \
    < "${table}.native"
  echo "Done."
done
```

### Step 6: Verify Data Integrity

```bash
for table in generations feedbacks generation_hooks audit_logs; do
  old=$(clickhouse-client --host localhost --port 9000 \
    --query "SELECT count() FROM default.${table}")
  new=$(clickhouse-client --host localhost --port 9001 \
    --query "SELECT count() FROM default.${table}")
  echo "${table}: old=${old} new=${new} $([ "$old" = "$new" ] && echo 'OK' || echo 'MISMATCH')"
done
```

### Step 7: Clean Up

1. Delete the PVC if persistence was enabled:

```bash
kubectl delete pvc -l app.kubernetes.io/component=<release>-app-clickhouse -n <namespace>
```

2. Remove the exported data files from your local machine.

### Rollback

Revert to the built-in instance:

```yaml
clickhouse:
  external:
    enabled: false
```

```bash
helm upgrade portkey portkey/portkey-app \
  -f portkey-values.yaml \
  -n <namespace>
```

If the PVC was not deleted, data will still be intact. If it was deleted, the backend will create empty tables on a fresh instance -- re-import from your exported files.
