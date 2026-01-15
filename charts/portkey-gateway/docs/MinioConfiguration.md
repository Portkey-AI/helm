# Local/In-cluster Minio Configuration
This guide describes how to configure MinIO for in-cluster deployment, enabling it to function both as a log store and as object storage for local Milvus deployment.

Include the following configuration in your `values.yaml`:

```yaml
minio:
  enabled: true
  name: "minio"
  authKey:
    create: true
    accessKey: "portkey"
    secretKey: "portkey123"
  persistence:
    enabled: true
    size: 10Gi
    storageClassName: "<Storage Class Name>"                 # Provide k8s storage class name to provision volumes for data persistence.
    accessMode: ReadWriteOnce
```


**Notes**

* The values specified for `minio.authKey.accessKey` and `minio.authKey.secretKey` will be used as the MinIO `ROOT USERNAME` and `ROOT PASSWORD`.
* To access the MinIO WebUI console, port-forward the service to your local machine:
  ```sh
  kubectl port-forward svc/minio 9001:9001
  ```
  Then open `http://localhost:9001` in your browser.