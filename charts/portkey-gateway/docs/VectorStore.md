# Vector Cache Configuration

This guide explains how to configure Milvus as a vector store for semantic caching in Portkey Gateway.

## Enable MinIO in Helm Chart

Milvus requires MinIO for object storage. Ensure MinIO is enabled in your deployment before proceeding. See [MinIO setup in README](./MinioConfiguration.md) for configuration details.

**Note:** If local MinIO is already enabled for log storage, skip this section and proceed to the next step.

## Enable Milvus in Helm Chart

Add the following to your `values.yaml`:

```yaml
milvus:
  enabled: true
  etcd:
    persistence:
      enabled: true
      size: 10Gi
  milvus:
    persistence:
      enabled: true
      size: 10Gi
```

## Configure Gateway for Semantic Cache

Update your `values.yaml` with the semantic cache configuration:

```yaml
environment:
  data:
    VECTOR_STORE: "milvus"
    VECTOR_STORE_ADDRESS: "http://milvus:19530"
    VECTOR_STORE_COLLECTION_NAME: "textEmbedding3Small"
    VECTOR_STORE_API_KEY: "<root>:Milvus"
    SEMANTIC_CACHE_EMBEDDINGS_URL: "<embeddings endpoint>"
    SEMANTIC_CACHE_EMBEDDING_MODEL: "<embeddings model>"
    SEMANTIC_CACHE_EMBEDDING_API_KEY: "<embeddings api key>"
```

## Upgrade Gateway

Apply the configuration by upgrading the Helm installation:

```sh
helm upgrade --install portkey-ai portkey-ai/gateway -f ./values.yaml -n portkeyai --create-namespace
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

Create the required collection for semantic caching. The example below creates a collection named `textEmbedding3Small` with 1536 dimensions (suitable for OpenAI's text-embedding-3-small model):

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





## Notes

- The `dim` value in the collection schema must match your embedding model's output dimensions. Refer to your embedding provider's documentation for the correct dimension size.
- Ensure Milvus is fully ready before creating collections. You can check pod status with:
  ```sh
  kubectl get pods -n portkeyai | grep milvus
  ```