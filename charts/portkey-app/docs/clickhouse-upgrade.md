# Upgrading the Built-in ClickHouse

This guide explains how to move the ClickHouse instance shipped with this chart from the default version to the one supported upgrade target.

The upgrade is **optional**. The chart does not change your ClickHouse version for you. You decide when to upgrade, and you plan for the short downtime it causes.

> **Note**: This applies only to the in-cluster ClickHouse. If you use an external ClickHouse (`clickhouse.external.enabled: true`), upgrade it yourself and set `compatibility` on that server directly, using the same version pair below.

## Supported Versions

Only the two combinations below are supported. Do not use any other image tag or `compatibility` value.

| | `images.clickhouseImage.tag` | `clickhouse.compatibility` |
|---|---|---|
| **Default** (no action needed) | `"24.10-alpine"` | `""` (not set) |
| **Upgrade target** | `"26.11-alpine"` | `"26.6"` |

- **`26.11-alpine`** is the ClickHouse server image to run.
- **`26.6`** is the newest ClickHouse behaviour that works with Portkey's data formats. Setting `compatibility` to `26.6` makes the 26.11 server use the setting defaults of 26.6.
- **Set both values together.** Running `26.11-alpine` without `compatibility: "26.6"` is not supported. Do not set `compatibility` to `"26.11"` or to any other version, even a newer one.
- **Write both values as quoted strings.** In a values file, an unquoted version is read as a number, so `26.10` becomes `26.1`.

`compatibility` covers only setting defaults (query and session behaviour). It does not stop the server from upgrading on-disk data formats, so it does not make a rollback to 24.10 safe (see below).

## Before You Upgrade

1. **Turn on persistence.** With the default `emptyDir` volume, any pod restart, including the image change, **deletes all ClickHouse data**. Check that persistence is enabled:

   ```yaml
   clickhouse:
     statefulSet:
       persistence:
         enabled: true
   ```

2. **Take a backup.** Snapshot the ClickHouse PVC, or export the tables (`generations`, `feedbacks`, `generation_hooks`, `audit_logs`) as shown in [clickhouse-migration.md](clickhouse-migration.md). Once 26.11 has written data, going back to the 24.10 image may not work. Restoring the backup is the only supported rollback.

3. **Plan for downtime.** The chart runs a single ClickHouse pod. During the upgrade it stops and starts again on the new image. Logs and analytics are unavailable until it is ready. Pick a maintenance window.

4. **Test the upgrade on a non-production environment first.**

## Upgrade

Set exactly these values in your values file:

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

The image change restarts the ClickHouse pod. It starts on 26.11 with `compatibility` set to 26.6.

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

- `version()` must start with `26.11.`
- `getSetting('compatibility')` must return `26.6`

If `getSetting('compatibility')` returns an empty value, the pod is running without the compatibility setting. Fix your values and restart the pod as described below before you send traffic.

## Changing Compatibility Later

Do this only to fix a wrong value. After you change `clickhouse.compatibility` and run `helm upgrade`, **you must restart ClickHouse yourself.** The value does not take effect until the pod restarts.

The `users.xml` file is mounted into the pod with `subPath`, and Kubernetes never updates `subPath` mounts in a running pod. If you change only `compatibility`, Helm updates the ConfigMap but does not restart the pod, so ClickHouse keeps the old value. (The exception is `clickhouse.external.existingSecretName`. When it is set, changing the value restarts the pod.)

Check that persistence is enabled, then restart:

```bash
kubectl get statefulset -n <namespace> | grep clickhouse
kubectl rollout restart statefulset/<clickhouse-statefulset-name> -n <namespace>
```

Then run the checks in [Verifying the Upgrade](#verifying-the-upgrade) again.