# Upgrading the Built-in ClickHouse

This guide explains how to upgrade the ClickHouse instance shipped with this chart to a newer version while keeping the query behaviour of an older release.

> **Note**: This applies only to the in-cluster ClickHouse. If you use an external ClickHouse (`clickhouse.external.enabled: true`), upgrade it and set `compatibility` on that server directly.

## Overview

The chart defaults to `images.clickhouseImage.tag: "24.10-alpine"` and does not set `compatibility`. Upgrading takes two values:

| Value | Description |
|-------|-------------|
| `images.clickhouseImage.tag` | ClickHouse server image to run |
| `clickhouse.compatibility` | ClickHouse [`compatibility`](https://clickhouse.com/docs/operations/settings/settings#compatibility) setting. Set on the `default` profile, so every session gets the setting defaults of that older version. Leave empty to use the server's own defaults. |

`compatibility` covers only setting defaults (query and session behaviour). It does not stop the server from upgrading on-disk data formats.

## Before You Upgrade

1. **Turn on persistence.** With the default `emptyDir` volume, any pod restart, including an image change, **deletes all ClickHouse data**. Check that persistence is enabled:

   ```yaml
   clickhouse:
     statefulSet:
       persistence:
         enabled: true
   ```

2. **Take a backup.** Snapshot the ClickHouse PVC, or export the tables (`generations`, `feedbacks`, `generation_hooks`, `audit_logs`) as shown in [clickhouse-migration.md](clickhouse-migration.md). Once the new version has written data, going back to the old image may not work.

3. **Test the upgrade on a non-production environment first.**

## Upgrade

Set the new image and the compatibility version in your values file:

```yaml
images:
  clickhouseImage:
    tag: "26.11-alpine"

clickhouse:
  compatibility: "26.6"
```

Apply it:

```bash
helm upgrade <release> portkey/portkey-app -n <namespace> -f values.yaml
```

The ClickHouse pod restarts on the new image.

> **Note**: If you use `helm upgrade --reuse-values`, pass both values explicitly with `--set` or `-f`. Otherwise the new `clickhouse.compatibility` key is missing from the reused values and is not applied.

## Verifying the Upgrade

Connect to ClickHouse:

```bash
kubectl exec -it <clickhouse-pod-name> -n <namespace> -- clickhouse-client --user <user> --password <password>
```

Check the server version and the compatibility setting:

```sql
SELECT version();
SELECT getSetting('compatibility');
```

`version()` should report the new release (e.g. `26.11.x`), and `getSetting('compatibility')` should return the configured value (e.g. `26.6`).

## Changing or Removing Compatibility Later

Update `clickhouse.compatibility` (or set it to `""` to remove it) and run `helm upgrade` again. ClickHouse reloads user profiles automatically, so new sessions pick up the change. A pod restart happens only if the image also changes or `clickhouse.external.existingSecretName` is set.
