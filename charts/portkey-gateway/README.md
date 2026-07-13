# Portkey Gateway Helm Chart

## Prerequisites

[Helm](https://helm.sh) must be installed to use the charts. Please refer to Helm's [documentation](https://helm.sh/docs) to get started.

## Quick Start

### 1. Register your Gateway

Follow the [Gateway Registration guide](http://localhost:3000/self-hosting/hybrid-deployments/gateway-registration) to register your gateway and download the pre-filled `values.yaml` configuration file.

### 2. Configure Storage

Update your `values.yaml` with the appropriate storage backends:

- **Log Store** — See [Log Store Configuration](./docs/LogStore.md) for AWS S3, Azure Blob Storage, GCS, and S3-compatible options
- **Cache Store** — See [Redis Configuration](./docs/Redis.md) for AWS ElastiCache, Azure Managed Redis, GCP Memorystore, and in-cluster Redis
- **Vector Store** *(Optional)* — See [Vector Store Setup](./docs/VectorStore.md) for semantic caching with Milvus
- **OTEL** *(Optional)* — See [OTEL Configuration](#otel-opentelemetry) to push analytics to OpenTelemetry-compatible endpoints

### 3. Deploy

```bash
helm repo add portkey-ai https://portkey-ai.github.io/helm
helm repo update
helm upgrade --install portkey-ai portkey-ai/gateway \
  -f ./values.yaml \
  -n portkeyai \
  --create-namespace
```

### 4. Verify

```bash
kubectl get pods -n portkeyai
```

### 5. Test (Optional)

```bash
kubectl port-forward <pod-name> -n portkeyai 8787:8787
```

## Data Service (Optional)

Enable data service for 

- Custom fine-tuning 
- Custom batches
- Data exports

```yaml
dataservice:
  enabled: true
```

**Note**: Currently only S3 is supported for fine-tuning data storage.

For detailed fine-tuning information, see [DataService.md](./docs/DataService.md).

---

## Uninstallation

```bash
helm uninstall portkey-gateway --namespace portkeyai
```

---

## Support

For additional help:

- Check the [full configuration reference](values.yaml)
- Review logs: `kubectl logs -n portkeyai deployment/portkey-gateway`
- Contact support([suport@portkey.ai](mailto:suport@portkey.ai)) with your configuration details

