## Portkey Gateway Configuration Variables

### General Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `replicaCount` | integer | `1` | Number of gateway pod replicas to deploy |
| `nameOverride` | string | `""` | Override for the chart name |
| `fullnameOverride` | string | `""` | Override for the full resource name |
| `autoRestart` | boolean | `false` | Enable automatic pod restart |

### Image Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `images.gatewayImage.repository` | string | `"docker.io/portkeyai/gateway_enterprise"` | Gateway container image repository |
| `images.gatewayImage.pullPolicy` | string | `"IfNotPresent"` | Image pull policy for gateway |
| `images.gatewayImage.tag` | string | `"1.15.8"` | Gateway image tag |
| `images.dataserviceImage.repository` | string | `"docker.io/portkeyai/data-service"` | Dataservice container image repository |
| `images.dataserviceImage.pullPolicy` | string | `"IfNotPresent"` | Image pull policy for dataservice |
| `images.dataserviceImage.tag` | string | `"1.2.8"` | Dataservice image tag |
| `images.redisImage.repository` | string | `"docker.io/redis"` | Redis container image repository |
| `images.redisImage.pullPolicy` | string | `"IfNotPresent"` | Image pull policy for Redis |
| `images.redisImage.tag` | string | `"7.2-alpine"` | Redis image tag |
| `imagePullSecrets` | array | `[portkeyenterpriseregistrycredentials]` | Kubernetes secrets for pulling private images |

### Image Credentials

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `imageCredentials[].name` | string | `"portkeyenterpriseregistrycredentials"` | Name of the image pull secret |
| `imageCredentials[].create` | boolean | `true` | Whether to create the secret |
| `imageCredentials[].registry` | string | `"https://index.docker.io/v1/"` | Docker registry URL |
| `imageCredentials[].username` | string | `"<docker-user>"` | Docker registry username |
| `imageCredentials[].password` | string | `"<docker-pwd>"` | Docker registry password |
| `imageCredentials[].email` | string | `""` | Email for Docker registry (optional) |
| `imageCredentials[].auth` | string | `""` | Base64 encoded auth token (alternative to username/password) |

### Vault Integration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `useVaultInjection` | boolean | `false` | Enable HashiCorp Vault secret injection |
| `vaultConfig.vaultHost` | string | `"vault.hashicorp.com"` | Vault server hostname |
| `vaultConfig.secretPath` | string | `"path/to/your/secret"` | Path to secrets in Vault |
| `vaultConfig.role` | string | `"your-vault-role"` | Vault role for authentication |
| `vaultConfig.kubernetesSecret` | string | `""` | Kubernetes secret name for Vault |

### Environment Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `environment.create` | boolean | `true` | Create environment configuration |
| `environment.secret` | boolean | `true` | Deploy as Secret (true) or ConfigMap (false) |
| `environment.existingSecret` | string | `""` | Use existing Secret instead of creating new one |

### Application Environment Variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `environment.data.SERVICE_NAME` | string | `"portkeyenterprise"` | Service name identifier |
| `environment.data.PORT` | string | `"8787"` | Gateway service port |
| `environment.data.LOG_STORE` | string | `""` | Log storage backend (e.g., s3, azure) |
| `environment.data.MONGO_DB_CONNECTION_URL` | string | `""` | MongoDB connection URL |
| `environment.data.MONGO_DATABASE` | string | `""` | MongoDB database name |
| `environment.data.MONGO_COLLECTION_NAME` | string | `""` | MongoDB collection for logs |
| `environment.data.MONGO_GENERATIONS_HOOKS_COLLECTION_NAME` | string | `""` | MongoDB collection for generation hooks |
| `environment.data.LOG_STORE_REGION` | string | `""` | AWS/Azure region for log storage |
| `environment.data.LOG_STORE_ACCESS_KEY` | string | `""` | Access key for log storage |
| `environment.data.LOG_STORE_SECRET_KEY` | string | `""` | Secret key for log storage |
| `environment.data.LOG_STORE_GENERATIONS_BUCKET` | string | `""` | S3/Azure bucket for generation logs |
| `environment.data.LOG_STORE_BASEPATH` | string | `""` | Base path within log storage bucket |
| `environment.data.LOG_STORE_AWS_ROLE_ARN` | string | `""` | AWS IAM role ARN for log storage |
| `environment.data.LOG_STORE_AWS_EXTERNAL_ID` | string | `""` | External ID for AWS role assumption |
| `environment.data.AWS_ASSUME_ROLE_ACCESS_KEY_ID` | string | `""` | Access key for AWS role assumption |
| `environment.data.AWS_ASSUME_ROLE_SECRET_ACCESS_KEY` | string | `""` | Secret key for AWS role assumption |
| `environment.data.AWS_ASSUME_ROLE_REGION` | string | `""` | AWS region for role assumption |
| `environment.data.AZURE_AUTH_MODE` | string | `""` | Azure authentication mode |
| `environment.data.AZURE_MANAGED_CLIENT_ID` | string | `""` | Azure managed identity client ID |
| `environment.data.AZURE_STORAGE_ACCOUNT` | string | `""` | Azure storage account name |
| `environment.data.AZURE_STORAGE_KEY` | string | `""` | Azure storage account key |
| `environment.data.AZURE_STORAGE_CONTAINER` | string | `""` | Azure storage container name |
| `environment.data.ANALYTICS_STORE` | string | `"clickhouse"` | Analytics storage backend |
| `environment.data.ANALYTICS_STORE_ENDPOINT` | string | `""` | Analytics store endpoint URL |
| `environment.data.ANALYTICS_STORE_USER` | string | `""` | Analytics store username |
| `environment.data.ANALYTICS_STORE_PASSWORD` | string | `""` | Analytics store password |
| `environment.data.ANALYTICS_LOG_TABLE` | string | `""` | Table name for analytics logs |
| `environment.data.ANALYTICS_FEEDBACK_TABLE` | string | `""` | Table name for feedback data |
| `environment.data.CACHE_STORE` | string | `"redis"` | Cache storage backend |
| `environment.data.REDIS_URL` | string | `"redis://redis:6379"` | Redis connection URL |
| `environment.data.REDIS_TLS_ENABLED` | string | `"false"` | Enable TLS for Redis connection |
| `environment.data.REDIS_MODE` | string | `""` | Redis deployment mode (standalone/cluster) |
| `environment.data.PORTKEY_CLIENT_AUTH` | string | `""` | Client authentication configuration |
| `environment.data.ORGANISATIONS_TO_SYNC` | string | `""` | Organizations to synchronize |
| `environment.data.FINETUNES_BUCKET` | string | `""` | S3/Azure bucket for fine-tuning data |
| `environment.data.LOG_EXPORTS_BUCKET` | string | `""` | S3/Azure bucket for log exports |
| `environment.data.FINETUNES_AWS_ROLE_ARN` | string | `""` | AWS IAM role ARN for fine-tunes |
| `environment.data.SERVER_MODE` | string | `""` | Server operation mode |
| `environment.data.MCP_PORT` | string | `""` | MCP service port |

### Service Account

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `serviceAccount.create` | boolean | `true` | Create a service account |
| `serviceAccount.automount` | boolean | `true` | Automatically mount service account credentials |
| `serviceAccount.annotations` | object | `{}` | Annotations for the service account |
| `serviceAccount.name` | string | `""` | Service account name (auto-generated if empty) |

### Pod Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `podAnnotations` | object | `{}` | Annotations to add to gateway pods |
| `podLabels` | object | `{}` | Labels to add to gateway pods |
| `podSecurityContext` | object | `{}` | Security context for pods |
| `securityContext` | object | `{}` | Security context for containers |

### Service Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `service.type` | string | `"NodePort"` | Kubernetes service type |
| `service.port` | integer | `8787` | Service port |
| `service.additionalLabels` | object | `{}` | Additional labels for the service |
| `service.annotations` | object | `{}` | Annotations for the service |

### Ingress Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `ingress.enabled` | boolean | `false` | Enable ingress resource |
| `ingress.hostname` | string | `""` | Ingress hostname |
| `ingress.ingressClassName` | string | `"nginx"` | Ingress class name |
| `ingress.annotations` | object | `{}` | Ingress annotations |
| `ingress.labels` | object | `{}` | Ingress labels |
| `ingress.tls` | array | `[]` | TLS configuration for ingress |

### Resource Management

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `resources` | object | `{}` | CPU/memory resource requests and limits |

### Health Probes

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `livenessProbe.httpGet.path` | string | `"/v1/health"` | Liveness probe HTTP path |
| `livenessProbe.httpGet.port` | integer | `8787` | Liveness probe port |
| `livenessProbe.initialDelaySeconds` | integer | `5` | Initial delay before liveness probe |
| `livenessProbe.periodSeconds` | integer | `60` | Liveness probe check interval |
| `livenessProbe.timeoutSeconds` | integer | `3` | Liveness probe timeout |
| `livenessProbe.failureThreshold` | integer | `3` | Liveness probe failure threshold |
| `readinessProbe.httpGet.path` | string | `"/v1/health"` | Readiness probe HTTP path |
| `readinessProbe.httpGet.port` | integer | `8787` | Readiness probe port |
| `readinessProbe.initialDelaySeconds` | integer | `5` | Initial delay before readiness probe |
| `readinessProbe.periodSeconds` | integer | `60` | Readiness probe check interval |
| `readinessProbe.timeoutSeconds` | integer | `3` | Readiness probe timeout |
| `readinessProbe.successThreshold` | integer | `1` | Readiness probe success threshold |
| `readinessProbe.failureThreshold` | integer | `3` | Readiness probe failure threshold |

### Autoscaling (Gateway)

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `autoscaling.enabled` | boolean | `false` | Enable HPA for gateway |
| `autoscaling.minReplicas` | integer | `2` | Minimum number of replicas |
| `autoscaling.maxReplicas` | integer | `20` | Maximum number of replicas |
| `autoscaling.targetCPUUtilizationPercentage` | integer | `60` | Target CPU utilization percentage |
| `autoscaling.targetMemoryUtilizationPercentage` | integer | `60` | Target memory utilization percentage |
| `autoscaling.behavior.scaleUp.stabilizationWindowSeconds` | integer | `0` | Scale up stabilization window |
| `autoscaling.behavior.scaleUp.podScaleUpValue` | integer | `2` | Number of pods to add during scale up |
| `autoscaling.behavior.scaleUp.percentScaleUpValue` | integer | `100` | Percentage to scale up |
| `autoscaling.behavior.scaleUp.periodSeconds` | integer | `2` | Scale up evaluation period |
| `autoscaling.behavior.scaleDown.stabilizationWindowSeconds` | integer | `300` | Scale down stabilization window |
| `autoscaling.behavior.scaleDown.podScaleDownValue` | integer | `1` | Number of pods to remove during scale down |
| `autoscaling.behavior.scaleDown.periodSeconds` | integer | `60` | Scale down evaluation period |

### Advanced Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `volumes` | array | `[]` | Additional volumes for gateway pods |
| `volumeMounts` | array | `[]` | Additional volume mounts for gateway containers |
| `extraContainerConfig` | object | `{}` | Extra container configuration options |
| `topologySpreadConstraints` | array | `[]` | Topology spread constraints for pod distribution |
| `nodeSelector` | object | `{}` | Node selector for pod scheduling |
| `tolerations` | array | `[]` | Tolerations for pod scheduling |
| `affinity` | object | `{}` | Affinity rules for pod scheduling |

### Dataservice Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `dataservice.name` | string | `"dataservice"` | Dataservice component name |
| `dataservice.enabled` | boolean | `false` | Enable dataservice component |
| `dataservice.containerPort` | integer | `8081` | Container port for dataservice |
| `dataservice.finetuneBucket` | string | `""` | S3/Azure bucket for fine-tune operations |
| `dataservice.logexportsBucket` | string | `""` | S3/Azure bucket for log exports |
| `dataservice.env.DEBUG_ENABLED` | boolean | `false` | Enable debug mode |
| `dataservice.env.SERVICE_NAME` | string | `"portkeyenterprise-dataservice"` | Service name for dataservice |

### Dataservice Deployment

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `dataservice.deployment.autoRestart` | boolean | `true` | Enable automatic restart |
| `dataservice.deployment.replicas` | integer | `1` | Number of dataservice replicas |
| `dataservice.deployment.labels` | object | `{}` | Labels for dataservice deployment |
| `dataservice.deployment.selectorLabels` | object | `{}` | Selector labels for dataservice |
| `dataservice.deployment.annotations` | object | `{}` | Annotations for dataservice deployment |
| `dataservice.deployment.podSecurityContext` | object | `{}` | Pod security context |
| `dataservice.deployment.securityContext` | object | `{}` | Container security context |
| `dataservice.deployment.resources` | object | `{}` | Resource requests and limits |
| `dataservice.deployment.extraEnv` | array | `[]` | Additional environment variables |
| `dataservice.deployment.extraContainerConfig` | object | `{}` | Extra container configuration |
| `dataservice.deployment.topologySpreadConstraints` | array | `[]` | Topology spread constraints |
| `dataservice.deployment.nodeSelector` | object | `{}` | Node selector |
| `dataservice.deployment.tolerations` | array | `[]` | Tolerations |
| `dataservice.deployment.affinity` | object | `{}` | Affinity rules |
| `dataservice.deployment.volumes` | array | `[]` | Additional volumes |
| `dataservice.deployment.volumeMounts` | array | `[]` | Additional volume mounts |

### Dataservice Probes

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `dataservice.deployment.startupProbe.httpGet.path` | string | `"/health"` | Startup probe path |
| `dataservice.deployment.startupProbe.httpGet.port` | integer | `8081` | Startup probe port |
| `dataservice.deployment.startupProbe.initialDelaySeconds` | integer | `60` | Startup probe initial delay |
| `dataservice.deployment.startupProbe.failureThreshold` | integer | `3` | Startup probe failure threshold |
| `dataservice.deployment.startupProbe.periodSeconds` | integer | `10` | Startup probe period |
| `dataservice.deployment.startupProbe.timeoutSeconds` | integer | `1` | Startup probe timeout |
| `dataservice.deployment.livenessProbe.httpGet.path` | string | `"/health"` | Liveness probe path |
| `dataservice.deployment.livenessProbe.httpGet.port` | integer | `8081` | Liveness probe port |
| `dataservice.deployment.livenessProbe.failureThreshold` | integer | `3` | Liveness probe failure threshold |
| `dataservice.deployment.livenessProbe.periodSeconds` | integer | `10` | Liveness probe period |
| `dataservice.deployment.livenessProbe.timeoutSeconds` | integer | `1` | Liveness probe timeout |
| `dataservice.deployment.readinessProbe.httpGet.path` | string | `"/health"` | Readiness probe path |
| `dataservice.deployment.readinessProbe.httpGet.port` | integer | `8081` | Readiness probe port |
| `dataservice.deployment.readinessProbe.failureThreshold` | integer | `3` | Readiness probe failure threshold |
| `dataservice.deployment.readinessProbe.periodSeconds` | integer | `10` | Readiness probe period |
| `dataservice.deployment.readinessProbe.timeoutSeconds` | integer | `1` | Readiness probe timeout |

### Dataservice Service

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `dataservice.service.type` | string | `"ClusterIP"` | Service type for dataservice |
| `dataservice.service.port` | integer | `8081` | Service port for dataservice |
| `dataservice.service.labels` | object | `{}` | Service labels |
| `dataservice.service.annotations` | object | `{}` | Service annotations |
| `dataservice.service.loadBalancerSourceRanges` | array | `[]` | Load balancer source ranges |
| `dataservice.service.loadBalancerIP` | string | `""` | Load balancer IP |

### Dataservice Service Account

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `dataservice.serviceAccount.create` | boolean | `true` | Create service account for dataservice |
| `dataservice.serviceAccount.name` | string | `""` | Service account name |
| `dataservice.serviceAccount.labels` | object | `{}` | Service account labels |
| `dataservice.serviceAccount.annotations` | object | `{}` | Service account annotations |

### Dataservice Autoscaling

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `dataservice.autoscaling.enabled` | boolean | `false` | Enable autoscaling for dataservice |
| `dataservice.autoscaling.createHpa` | boolean | `false` | Create HPA resource |
| `dataservice.autoscaling.minReplicas` | integer | `1` | Minimum replicas |
| `dataservice.autoscaling.maxReplicas` | integer | `5` | Maximum replicas |
| `dataservice.autoscaling.targetCPUUtilizationPercentage` | integer | `80` | Target CPU utilization |
| `dataservice.autoscaling.targetMemoryUtilizationPercentage` | integer | `80` | Target memory utilization |
| `dataservice.autoscaling.behavior.scaleUp.stabilizationWindowSeconds` | integer | `0` | Scale up stabilization window |
| `dataservice.autoscaling.behavior.scaleUp.podScaleUpValue` | integer | `2` | Pods to add during scale up |
| `dataservice.autoscaling.behavior.scaleUp.percentScaleUpValue` | integer | `100` | Percentage scale up value |
| `dataservice.autoscaling.behavior.scaleUp.periodSeconds` | integer | `2` | Scale up period |
| `dataservice.autoscaling.behavior.scaleDown.stabilizationWindowSeconds` | integer | `300` | Scale down stabilization window |
| `dataservice.autoscaling.behavior.scaleDown.podScaleDownValue` | integer | `1` | Pods to remove during scale down |
| `dataservice.autoscaling.behavior.scaleDown.periodSeconds` | integer | `60` | Scale down period |

### Redis Configuration

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `redis.name` | string | `"redis"` | Redis component name |
| `redis.containerPort` | integer | `6379` | Redis container port |
| `redis.resources` | object | `{}` | Resource requests and limits for Redis |