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
```

Ensure you replace `your_username` and `your_password` with your actual Docker registry credentials. Its safe to use latest tag for all Portkey images (unless there is a specific tag shared with you).

### Basic Configuration

```yaml
config:
  logStore: "s3"
  jwtPrivateKey: "some-string-here"
  noAuth:
    enabled: true
```
-  Set the log store as s3
- JWT Private Key is required for session management.
- If you are installing for the first time you should set noAuth.enabled true. This will allow you to access the application without any authentication, post which you can configure OAuth and switch it on.
- Strongly recommended to use OAuth for authentication in production.

### Blob Storage Configuration

```yaml
logStorage:
  logStore: "s3"
  s3Compat:
    enabled: true
    LOG_STORE_ACCESS_KEY: ""
    LOG_STORE_SECRET_KEY: ""
    LOG_STORE_REGION: ""
    LOG_STORE_GENERATIONS_BUCKET: ""
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

### SMTP Configuration

Portkey supports two ways to configure SMTP for email notifications:

#### 1. Using Environment Variables (Default)

```yaml
config:
  smtp:
    enabled: true
    smtpHost: "smtp.example.com"
    smtpPort: "587"
    smtpUser: "username"
    smtpPassword: "password"
    smtpFrom: "noreply@example.com"
    secretMount:
      enabled: false  # This is the default
```

#### 2. Using Volume Mounts (Recommended for Production)

This method allows you to mount SMTP credentials from Kubernetes secrets:

```yaml
config:
  smtp:
    enabled: true
    # The following fields are optional if using secretMount
    smtpHost: "smtp.example.com"  # These values will be stored in the secret
    smtpPort: "587"
    smtpUser: "username"
    smtpPassword: "password"
    smtpFrom: "noreply@example.com"
    secretMount:
      enabled: true
      existingSecret: ""  # Leave empty to create a secret from the values above
      mountPath: "/etc/portkey/smtp"
      keys:
        host: "smtp-host"
        port: "smtp-port"
        user: "smtp-user"
        password: "smtp-password"
        from: "smtp-from"
```

When using volume mounts, a startup script will read the credentials from the mounted files and set them as environment variables for the application. This provides a uniform interface for the application while giving you flexibility in how credentials are provided.

If you have an existing secret, you can specify it in `existingSecret`:

```yaml
config:
  smtp:
    enabled: true
    # You can omit these values when using an existing secret
    smtpHost: ""
    smtpPort: ""
    smtpUser: ""
    smtpPassword: ""
    smtpFrom: ""
    secretMount:
      enabled: true
      existingSecret: "my-smtp-secret"  # Name of your existing secret
      mountPath: "/etc/portkey/smtp"
      keys:
        host: "smtp-host"  # These should match the keys in your existing secret
        port: "smtp-port"
        user: "smtp-user"
        password: "smtp-password"
        from: "smtp-from"
```

When using volume mounts, the application will read the secrets from files at the specified mount path. For example:
- SMTP_HOST will be read from `/etc/portkey/smtp/smtp-host`
- SMTP_PASSWORD will be read from `/etc/portkey/smtp/smtp-password` 

If the file is not found, it will fall back to the environment variable if set. This provides flexibility to combine both approaches if needed.

If using an existing secret, ensure it contains the required keys as specified in the `keys` mapping.

### OAuth/SSO Configuration

Similar to SMTP, OAuth (SSO) configuration can also be provided via environment variables or volume mounts:

#### 1. Using Environment Variables (Default)

```yaml
config:
  oauth:
    enabled: true
    oauthType: "oidc" # or "saml"
    oauthClientId: "your-client-id"
    oauthIssuerUrl: "https://your-identity-provider.com"
    oauthClientSecret: "your-client-secret"
    oauthRedirectURI: "https://your-app-url/callback"
    oauthMetadataXml: "" # for SAML
```

#### 2. Using Volume Mounts

```yaml
config:
  oauth:
    enabled: true
    # The following fields are optional if using secretMount
    oauthType: ""
    oauthClientId: ""
    oauthIssuerUrl: ""
    oauthClientSecret: ""
    oauthRedirectURI: ""
    oauthMetadataXml: ""
    secretMount:
      enabled: true
      # Use an existing secret or leave empty to create one
      existingSecret: "my-existing-oauth-secret"
      # Where to mount the secrets in containers
      mountPath: "/etc/portkey/oauth"
      # Secret keys mapping (customize if needed)
      keys:
        oauthType: "oauth-type"
        oauthClientId: "oauth-client-id"
        oauthIssuerUrl: "oauth-issuer-url"
        oauthClientSecret: "oauth-client-secret"
        oauthRedirectURI: "oauth-redirect-uri"
        oauthMetadataXml: "oauth-metadata-xml"
```

When using volume mounts, the application will read the secrets from files at the specified mount path. For example:
- AUTH_SSO_TYPE will be read from `/etc/portkey/oauth/oauth-type`
- OIDC_CLIENT_SECRET will be read from `/etc/portkey/oauth/oauth-client-secret`

If the file is not found, it will fall back to the environment variable if set.

### MySQL Volume Mount Configuration

For MySQL credentials, you can also use volume mounts when not using an external MySQL:

```yaml
mysql:
  external:
    enabled: false
    # These fields are optional if using secretMount
    user: ""
    password: ""
    database: ""
    rootPassword: ""
    secretMount:
      enabled: true
      # Use an existing secret or leave empty to create one
      existingSecret: "my-existing-mysql-secret"
      # Where to mount the secrets in containers
      mountPath: "/etc/portkey/mysql"
      # Secret keys mapping (customize if needed)
      keys:
        user: "mysql-user"
        password: "mysql-password"
        database: "mysql-database"
        rootPassword: "mysql-root-password"
```

When using volume mounts, the application will read the secrets from files at the specified mount path. For example:
- DB_USER will be read from `/etc/portkey/mysql/mysql-user`
- DB_PASS will be read from `/etc/portkey/mysql/mysql-password`

### Redis Volume Mount Configuration

For Redis credentials, you can also use volume mounts when not using an external Redis:

```yaml
redis:
  external:
    enabled: false
    # These fields are optional if using secretMount
    connectionUrl: ""
    tlsEnabled: "false"
    mode: "standalone"
    store: "redis"
    secretMount:
      enabled: true
      # Use an existing secret or leave empty to create one
      existingSecret: "my-existing-redis-secret"
      # Where to mount the secrets in containers
      mountPath: "/etc/portkey/redis"
      # Secret keys mapping (customize if needed)
      keys:
        connectionUrl: "redis-connection-url"
        tlsEnabled: "redis-tls-enabled"
        mode: "redis-mode"
        store: "redis-store"
```

When using volume mounts, the application will read the secrets from files at the specified mount path. For example:
- REDIS_URL will be read from `/etc/portkey/redis/redis-connection-url`
- REDIS_TLS_ENABLED will be read from `/etc/portkey/redis/redis-tls-enabled`

### ClickHouse Volume Mount Configuration

For ClickHouse credentials, you can also use volume mounts when not using an external ClickHouse:

```yaml
clickhouse:
  external:
    enabled: false
    # These fields are optional if using secretMount
    host: ""
    port: "8123"
    nativePort: "9000"
    user: ""
    password: ""
    database: "default"
    tls: false
    secretMount:
      enabled: true
      # Use an existing secret or leave empty to create one
      existingSecret: "my-existing-clickhouse-secret"
      # Where to mount the secrets in containers
      mountPath: "/etc/portkey/clickhouse"
      # Secret keys mapping (customize if needed)
      keys:
        store: "clickhouse-store"
        host: "clickhouse-host"
        port: "clickhouse-port"
        nativePort: "clickhouse-native-port"
        user: "clickhouse-user"
        password: "clickhouse-password"
        database: "clickhouse-database"
        tls: "clickhouse-tls"
```

When using volume mounts, the application will read the secrets from files at the specified mount path. For example:
- CLICKHOUSE_HOST will be read from `/etc/portkey/clickhouse/clickhouse-host`
- CLICKHOUSE_PASSWORD will be read from `/etc/portkey/clickhouse/clickhouse-password`

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

### Secrets Management

Portkey supports two methods for providing sensitive credentials:

1. **Using Environment Variables** (Default): Credentials are stored in Kubernetes secrets and injected as environment variables
2. **Using Volume Mounts**: Credentials are stored in Kubernetes secrets and mounted as files

The volume mount approach is generally more secure and flexible, but both methods are supported for compatibility.

For each service (SMTP, OAuth, MySQL, Redis, Clickhouse), you can choose which method to use. Both methods will store your credentials in Kubernetes secrets.

#### Environment Variables Approach

```yaml
config:
  smtp:
    enabled: true
    smtpHost: "smtp.example.com"
    smtpPort: "587"
    smtpUser: "username"
    smtpPassword: "password"
    smtpFrom: "noreply@example.com"
    secretMount:
      enabled: false  # This is the default
```

#### Volume Mounts Approach

```yaml
config:
  smtp:
    enabled: true
    smtpHost: "smtp.example.com"  # These values will be stored in the secret
    smtpPort: "587"
    smtpUser: "username"
    smtpPassword: "password"
    smtpFrom: "noreply@example.com"
    secretMount:
      enabled: true
      existingSecret: ""  # Leave empty to create a secret from the values above
      mountPath: "/etc/portkey/smtp"
      keys:
        host: "smtp-host"
        port: "smtp-port"
        user: "smtp-user"
        password: "smtp-password"
        from: "smtp-from"
```

When using volume mounts, a startup script will read the credentials from the mounted files and set them as environment variables for the application. This provides a uniform interface for the application while giving you flexibility in how credentials are provided.

If you have an existing secret, you can specify it in `existingSecret`:

```yaml
config:
  smtp:
    enabled: true
    # You can omit these values when using an existing secret
    smtpHost: ""
    smtpPort: ""
    smtpUser: ""
    smtpPassword: ""
    smtpFrom: ""
    secretMount:
      enabled: true
      existingSecret: "my-smtp-secret"  # Name of your existing secret
      mountPath: "/etc/portkey/smtp"
      keys:
        host: "smtp-host"  # These should match the keys in your existing secret
        port: "smtp-port"
        user: "smtp-user"
        password: "smtp-password"
        from: "smtp-from"
```

When using volume mounts, the application will read the secrets from files at the specified mount path. For example:
- SMTP_HOST will be read from `/etc/portkey/smtp/smtp-host`
- SMTP_PASSWORD will be read from `/etc/portkey/smtp/smtp-password` 

If the file is not found, it will fall back to the environment variable if set. This provides flexibility to combine both approaches if needed.

If using an existing secret, ensure it contains the required keys as specified in the `keys` mapping.

### SMTP Configuration

NEXT: [Installation](./installation.md)
