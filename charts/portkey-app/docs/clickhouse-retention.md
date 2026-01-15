# ClickHouse Data Retention

This guide explains how to configure data retention policies for ClickHouse in your Portkey deployment.

## Overview

ClickHouse supports TTL (Time-To-Live) based retention policies that automatically delete old data. Retention works at two levels:

| Level | Description | Configuration |
|-------|-------------|---------------|
| **Server-level** | Controls how TTL merges are processed | Helm values (`customConfig` + `retention`) |
| **Table-level** | Defines what data to delete and when | SQL `ALTER TABLE` commands |

Both levels must be configured for retention to work.

## Configuration

### Step 1: Enable Custom Config

Enable the custom config mount in your values file:

```yaml
clickhouse:
  customConfig:
    enabled: true
```

> **Note**: Enabling this will cause a one-time pod restart on upgrade.

### Step 2: Enable Retention Settings

Configure server-level retention parameters:

```yaml
clickhouse:
  customConfig:
    enabled: true
  retention:
    enabled: true
    mergeWithTtlTimeout: 14400   # seconds between TTL merge checks (default: 4 hours)
    ttlOnlyDropParts: 0          # 0 = rewrite parts, 1 = only drop entire parts
```

#### Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `mergeWithTtlTimeout` | `14400` | Minimum delay (seconds) between TTL merge operations. Lower values = more frequent cleanup but higher CPU usage. |
| `ttlOnlyDropParts` | `0` | When `0`, ClickHouse rewrites data parts to remove expired rows. When `1`, only drops parts where ALL rows have expired (more efficient but less granular). |

### Step 3: Apply Table-Level TTL

After deploying with the above configuration, connect to ClickHouse and apply TTL rules to your tables:

```sql
-- Delete rows older than 90 days based on created_at column
ALTER TABLE <TABLE_NAME> MODIFY TTL created_at + INTERVAL 90 DAY DELETE;

-- Delete rows older than 6 months
ALTER TABLE <TABLE_NAME> MODIFY TTL created_at + INTERVAL 6 MONTH DELETE;

-- Delete rows older than 1 year
ALTER TABLE <TABLE_NAME> MODIFY TTL created_at + INTERVAL 1 YEAR DELETE;
```

To check existing TTL rules:

```sql
SELECT name, engine, create_table_query 
FROM system.tables 
WHERE database = 'default';
```

Following tables are present in Portkey Clickhouse:
- `generations`
- `feedbacks`
- `generation_hooks`
- `audit_logs`(*)

Note(*): for `audit_logs`, please use `timestamp` instead of `created_at` in the query


## Example Configuration

Full example for 90-day retention with hourly cleanup checks:

```yaml
clickhouse:
  customConfig:
    enabled: true
  retention:
    enabled: true
    mergeWithTtlTimeout: 3600    # Check every hour
    ttlOnlyDropParts: 0
```

Then apply to tables:

```sql
ALTER TABLE logs MODIFY TTL timestamp + INTERVAL 90 DAY DELETE;
```

## Verifying Retention

Check if TTL merges are running:

```sql
SELECT * FROM system.merges WHERE is_mutation = 0;
```

Check table TTL settings:

```sql
SELECT 
    database,
    table,
    name as column,
    type,
    default_expression
FROM system.columns 
WHERE database = 'default';
```

Monitor deleted rows:

```sql
SELECT 
    table,
    sum(rows) as total_rows,
    formatReadableSize(sum(bytes_on_disk)) as size
FROM system.parts
WHERE active AND database = 'default'
GROUP BY table;
```

