# Vector Store Configuration

This guide explains how to configure local/in-cluster Milvus as a vector store for semantic caching in Portkey Gateway.

## Enable MinIO in Helm Chart

Milvus requires MinIO for object storage. Ensure MinIO is enabled in your deployment before proceeding. See [MinIO setup in README](../README.md#minio-localin-cluster) for configuration details.

**Note:** If local MinIO is already enabled for log storage, skip this section and proceed to the next step.

## Enable Milvus in Helm Chart

Add the following to your `values.yaml`:

```yaml
environment:
  data: 
    VECTOR_STORE: local

milvus:
  name: "milvus"
  persistence:
    enabled: true
    size: 10Gi
    storageClassName: ""                                # Provide k8s storage class for creating storage volumes. 
    accessMode: ReadWriteOnce
  etcd:
    name: "etcd"
    persistence:
      enabled: true
      size: 10Gi
      storageClassName: "gp3"                           # Provide k8s storage class for creating storage volumes. 
      accessMode: ReadWriteOnce  
```

## Access Milvus Instance

After deploying, port-forward the Milvus service to access it locally:

```sh
kubectl port-forward -n portkeyai svc/milvus 19530:19530
```

## Connect to Milvus

You can use a client like [Attu](https://github.com/zilliztech/attu) to connect to the Milvus instance:

| Field | Value |
|-------|-------|
| Host | `localhost:19530` |
| Username | `root` |
| Password | `Milvus` |

## Create Collection

Create the required collection for semantic caching. The example below creates a collection named `textEmbedding3Small` with 1536 dimensions (update `dim` based on your embedding model):

```sh
curl --location --request POST 'http://localhost:19530/v2/vectordb/collections/create' \
--header 'Authorization: Bearer root:Milvus' \
--header 'Content-Type: application/json' \
--data '{
  "collectionName": "textEmbedding3Small",
  "schema": {
    "autoId": false,
    "enableDynamicField": true,
    "fields": [
      {
        "fieldName": "id",
        "dataType": "VarChar",
        "isPrimary": true,
        "elementTypeParams": {
          "max_length": 1024
        }
      },
      {
        "fieldName": "vector",
        "dataType": "FloatVector",
        "elementTypeParams": {
          "dim": "1536"
        }
      },
      {
        "fieldName": "workspace_id",
        "dataType": "VarChar",
        "elementTypeParams": {
          "max_length": 512
        }
      }
    ]
  },
  "indexParams": [
    {
      "fieldName": "vector",
      "metricType": "COSINE",
      "indexName": "vector",
      "indexType": "AUTOINDEX"
    }
  ],
  "enableDynamicField": true
}'
```

### Verify Collection

Confirm the collection was created successfully:

```sh
curl --location --request POST 'http://localhost:19530/v2/vectordb/collections/describe' \
--header 'Authorization: Bearer root:Milvus' \
--header 'Content-Type: application/json' \
--data '{
    "collectionName": "textEmbedding3Small"
}'
```