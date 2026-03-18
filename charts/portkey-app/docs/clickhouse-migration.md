# Migrating ClickHouse from Built-in to Replicated Cluster

This guide walks through migrating data from the single-node ClickHouse instance shipped with this chart to an external replicated ClickHouse cluster.

## Overview

| Step | Action | Downtime |
|------|--------|----------|
| 1 | Deploy new replicated cluster | None |
| 2 | Export data from old instance | None |
| 3 | Create tables on new cluster | None |
| 4 | Import data into new cluster | None |
| 5 | Point Portkey to new cluster | Brief restart |
| 6 | Verify and decommission old instance | None |

## Prerequisites

- `kubectl` access to the namespace running Portkey
- New replicated ClickHouse cluster deployed (see [clickhouse-replication.md](clickhouse-replication.md))
- Enough disk on a local machine or a PV to hold the exported data

## Tables to Migrate

| Table | Timestamp Column |
|-------|-----------------|
| `generations` | `created_at` |
| `feedbacks` | `created_at` |
| `generation_hooks` | `created_at` |
| `audit_logs` | `timestamp` |

## Step 1: Deploy the New Replicated Cluster

Follow the [ClickHouse Replication](clickhouse-replication.md) guide to deploy a replicated cluster. **Do not** update the Portkey values yet — the old instance stays active during migration.

## Step 2: Get Connection Details for Both Clusters

Old (built-in) instance:

```bash
# Port-forward the built-in ClickHouse
kubectl port-forward svc/<release>-app-clickhouse 8123:8123 -n <namespace>
```

New (replicated) cluster:

```bash
# Port-forward the new ClickHouse (adjust service name to your deployment)
kubectl port-forward svc/<new-clickhouse-svc> 8124:8123 -n <namespace>
```

You now have the old instance on `localhost:8123` and the new cluster on `localhost:8124`.

## Step 3: Export Schema from the Old Instance

Dump the `CREATE TABLE` statements:

```bash
clickhouse-client --host localhost --port 9000 \
  --query "SELECT name FROM system.tables WHERE database = 'default' AND engine != 'View'" \
  | while read -r table; do
    echo "-- Table: $table"
    clickhouse-client --host localhost --port 9000 \
      --query "SHOW CREATE TABLE default.${table}" 
    echo ";"
    echo ""
  done > old_schema.sql
```

Review `old_schema.sql` — the tables will use `MergeTree` engines. You do **not** need to manually convert these. The Portkey backend migration will create the correct `ReplicatedMergeTree` tables on the new cluster automatically when `replicationEnabled: true`.

## Step 4: Export Data from the Old Instance

Export each table in a portable format. Native format is fastest for ClickHouse-to-ClickHouse transfers:

```bash
for table in generations feedbacks generation_hooks audit_logs; do
  echo "Exporting ${table}..."
  clickhouse-client --host localhost --port 9000 \
    --query "SELECT * FROM default.${table} FORMAT Native" \
    > "${table}.native"
  echo "Done: $(ls -lh ${table}.native | awk '{print $5}')"
done
```

For very large tables, you can export in chunks by time range:

```bash
# Example: export generations in monthly chunks
clickhouse-client --host localhost --port 9000 \
  --query "SELECT * FROM default.generations WHERE created_at >= '2025-01-01' AND created_at < '2025-02-01' FORMAT Native" \
  > generations_2025_01.native
```

## Step 5: Let Portkey Create Tables on the New Cluster

Update your Portkey values to point at the new cluster with replication enabled, then upgrade:

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
    tls: false
    replicationEnabled: true
    shardingEnabled: false      # set true if using sharding
    clusterName: "portkey_cluster"
```

```bash
helm upgrade portkey portkey/portkey-app \
  -f portkey-values.yaml \
  -n <namespace>
```

The backend pod will start and run migrations automatically, creating all tables with `ReplicatedMergeTree` engines. Wait for the backend pod to become ready:

```bash
kubectl rollout status deployment/<release>-app-backend -n <namespace>
```

## Step 6: Import Data into the New Cluster

With port-forward to the new cluster still active on `localhost:8124`:

```bash
for table in generations feedbacks generation_hooks audit_logs; do
  echo "Importing ${table}..."
  clickhouse-client --host localhost --port 8124 \
    --query "INSERT INTO default.${table} FORMAT Native" \
    < "${table}.native"
  echo "Done."
done
```

If you exported in chunks, import each chunk file the same way.

## Step 7: Verify Data Integrity

Compare row counts between old and new:

```bash
for table in generations feedbacks generation_hooks audit_logs; do
  old=$(clickhouse-client --host localhost --port 9000 \
    --query "SELECT count() FROM default.${table}")
  new=$(clickhouse-client --host localhost --port 8124 \
    --query "SELECT count() FROM default.${table}")
  echo "${table}: old=${old} new=${new} $([ "$old" = "$new" ] && echo '✓' || echo 'MISMATCH')"
done
```

Optionally verify checksums on critical columns:

```sql
-- Run on both old and new, compare output
SELECT
  count(),
  sum(cityHash64(*))
FROM default.generations;
```

## Step 8: Verify Replication is Working

On the new cluster, confirm tables are replicated:

```sql
SELECT
  database,
  table,
  engine
FROM system.tables
WHERE database = 'default'
  AND engine LIKE '%Replicated%';
```

Check replication queue is clean:

```sql
SELECT
  database,
  table,
  type,
  is_currently_executing
FROM system.replication_queue;
```

## Step 9: Decommission the Old Instance

Once everything is verified and Portkey is running against the new cluster:

1. Confirm no traffic is going to the old ClickHouse by checking its query log:

```sql
-- On old instance
SELECT count() FROM system.query_log
WHERE event_time > now() - INTERVAL 1 HOUR
  AND type = 'QueryFinish'
  AND query NOT LIKE '%system%';
```

2. Scale down or delete the old StatefulSet (this happens automatically when `clickhouse.external.enabled: true`).

3. Clean up the PVC if persistence was enabled:

```bash
kubectl delete pvc -l app.kubernetes.io/component=<release>-app-clickhouse -n <namespace>
```

4. Remove the exported data files from your local machine.

## Rollback

If issues arise after switching, revert to the built-in instance:

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

This re-creates the built-in StatefulSet. If the PVC was not deleted, data will still be intact. If it was deleted, the backend will run migrations to create empty tables on a fresh instance — you would need to re-import from your exported files.
