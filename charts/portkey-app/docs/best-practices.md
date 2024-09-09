# Portkey Best Practices

## Security
1. **OIDC Authentication**: Implement before production for robust, standardized auth.
2. **API Key Management**: Rotate regularly, use different keys for each environment.

## Infrastructure
1. **External Databases**: Use managed services for MySQL, Redis, and ClickHouse for better scaling and backups.
2. **Load Balancing**: Implement a managed load balancer with SSL termination for improved security and performance.

## Monitoring and Logging
1. Set up comprehensive monitoring with alerting.
2. Implement centralized logging for all components.

## Resource Management

### Node Recommendations
- Minimum 2 nodes
- Each node: 4 vCPUs, 16 GB RAM
- Adjust based on workload and scaling needs

### Pod Resources
Recommended starting points:

| Component | CPU Request/Limit | Memory Request/Limit |
|-----------|-------------------|----------------------|
| Frontend  | 100m/500m         | 128Mi/512Mi          |
| Backend   | 500m/1000m        | 512Mi/1Gi            |
| Gateway   | 500m/1000m        | 512Mi/1Gi            |
| MySQL*    | 1000m/2000m       | 2Gi/4Gi              |
| Redis*    | 100m/500m         | 256Mi/512Mi          |
| ClickHouse* | 1000m/2000m     | 8Gi/16Gi             |

*Note: For databases, we recommend using managed services instead of running in Kubernetes.

Adjust resources based on your specific workload and performance requirements.

## Additional Best Practices
1. Implement regular backups and test restore procedures.
2. Use Kubernetes Horizontal Pod Autoscaler (HPA) for key components.
3. Employ canary deployments for upgrades.
4. Keep all configurations in version control.

For detailed guidance, contact your Customer Success Manager or support@portkey.ai.