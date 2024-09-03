# Configuration

Portkey uses Helm charts for deployment. Here are the key configuration settings you need to consider when setting up your private deployment. In this example we will be using 
- AWS S3 for blob storage
- Internal Mysql for database
- Internal Redis for caching
- Internal ClickHouse for analytics

You can choose any other supported blob storage, database and caching options. More about configuration options [here](./advanedConfigurations.md).

### Image Configuration

These will be provided by the Portkey team once you have purchased a license key.

```yaml
imageCredentials:
  - name: portkeyenterpriseregistrycredentials
    create: true
    registry: https://index.docker.io/v1/
    username: <your_username>
    password: <your_password>

images:
  backendImage:
    repository: "docker.io/portkeyai/backend"
    tag: "latest"
  frontendImage:
    repository: "docker.io/portkeyai/frontend"
    tag: "latest"
  dataserviceImage:
    repository: "docker.io/portkeyai/data-service"
    tag: "latest"
  gatewayImage:
    repository: "docker.io/portkeyai/gateway-enterprise"
    tag: "latest"
  mysqlImage:
    repository: "docker.io/mysql"
    tag: "8.1"
  redisImage:
    repository: "docker.io/redis"
    tag: "alpine"
  clickhouseImage:
    repository: "docker.io/clickhouse/clickhouse-server"
    tag: "latest"
```

Ensure you replace `your_username` and `your_password` with your actual Docker registry credentials. Its safe to use latest tag for all Portkey images (unless there is a specific tag shared with you).

### Basic Configuration

```yaml
config:
  existingSecretName: ""
  defaultGatewayURL: ""
  logStore: "s3"
  jwtPrivateKey: "some_random_string"
```
Log store can be set to s3 or any other supported blob storage. 
JWT Private Key is required for session management.

### Authentication Configuration
Portkey supports 2 types of authentication:
1. No Authentication (not recommended for production)
2. OIDC OAuth Authentication

**Only one of the authentication methods can be enabled**

JWT Private Key is required for both authentication modes for session management.

```yaml
config:
  noAuth:
    enabled: true
  oauth:
    enabled: false
    # Configure if using OAuth
```

If you are installing for the first time you should set noAuth.enabled true. This will allow you to access the application without any authentication, post which you can configure OAuth and switch it on.

Strongly recommended to use OAuth for authentication in production.

### Blob Storage Configuration

```yaml
logStorage:
  s3:
    enabled: true
    AWS_ACCESS_KEY_ID: "your_access_key"
    AWS_SECRET_ACCESS_KEY: "your_secret_key"
    AWS_REGION: "your_region"
    AWS_BUCKET_NAME: "your_bucket_name"
```

Replace the AWS credentials and bucket information with your actual S3 storage details.

### Database Configurations

#### MySQL

```yaml
mysql:
  external:
    enabled: false
    user: ""
    password: ""
    database: ""
    rootPassword: ""
```
The credentials passed here will be used for the internal mysql instance.

#### Redis

```yaml
redis:
  external:
    enabled: false
```
No additional configuration needed for redis.

#### ClickHouse

```yaml
clickhouse:
  external:
    enabled: false
    user: "default"
    password: "password"
```
The credentials passed here will be used for the internal clickhouse instance.

### Resource Allocation

You can adjust resource allocation for each component. Here's an example for the backend:

```yaml
backend:
  deployment:
    resources:
      limits:
        cpu: 1000m
        memory: 1Gi
      requests:
        cpu: 200m
        memory: 500Mi
```

Similar resource configurations can be set for other components like frontend, gateway, and databases.

Remember to adjust these configurations based on your specific requirements and infrastructure capabilities. It's recommended to start with these settings and fine-tune based on your usage and performance needs.