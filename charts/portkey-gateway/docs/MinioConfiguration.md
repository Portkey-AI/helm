# Local/In-cluster Minio Configuration
This guide describes how to configure MinIO for in-cluster deployment, enabling it to function both as a log store and as object storage for local Milvus deployment.

Include the following configuration in your `values.yaml`:

```yaml
minio:
  enabled: true
  name: "minio"
  authKey:
    create: true
    accessKey: "<minio-access-key>"                          # Required when create: true (no default)
    secretKey: "<minio-secret-key>"                          # Required when create: true (no default)
  persistence:
    enabled: true
    size: 10Gi
    storageClassName: "<Storage Class Name>"                 # Provide k8s storage class name to provision volumes for data persistence.
    accessMode: ReadWriteOnce
```


**Notes**

* The values specified for `minio.authKey.accessKey` and `minio.authKey.secretKey` will be used as the MinIO `ROOT USERNAME` and `ROOT PASSWORD`.
* `accessKey` and `secretKey` are **required** when `authKey.create: true`. The chart ships no default credentials, so leaving either empty will cause the chart to fail rendering with a clear error.
* Alternatively, provide credentials from a pre-existing Secret by setting `authKey.existingSecret` together with `authKey.create: false`. Note that `create: true` and `existingSecret` are mutually exclusive — setting both is rejected.
* To access the MinIO WebUI console, port-forward the service to your local machine:
  ```sh
  kubectl port-forward svc/minio 9001:9001
  ```
  Then open `http://localhost:9001` in your browser.