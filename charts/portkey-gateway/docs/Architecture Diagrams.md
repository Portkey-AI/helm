# Architecture Diagrams

Visual representations of Portkey AI Gateway deployment patterns across AWS, GCP, and Azure environments.

---

## Table of Contents

1. [Single Gateway Multi-Provider](#single-gateway-multi-provider)
2. [Multi-Gateway Regional](#multi-gateway-regional)
3. [Network Flow Diagrams](#network-flow-diagrams)
4. [Data Flow Patterns](#data-flow-patterns)
5. [High Availability Patterns](#high-availability-patterns)

---

## Single Gateway Multi-Provider

### Centralized Gateway Architecture

**Scenario:** Application on AWS EKS routing to all three LLM providers

```

         ┌─────────────────────────────────────┐    
         │     Application Layer               │    
         └─────────────────────────────────────┘    
                            │
                            │                           
    ┌───────────────────────▼──────────────────────────────────────┐
    │                  Your AWS Account                            │
    │                       (VPC)                                  │
    │                                                              │
    │  ┌────────────────────────────────────────────────────────┐  │
    │  │               EKS Cluster                              │  │
    │  │  ┌─────────────────────────────────────────────┐       │  │
    │  │  │     Portkey Gateway (3+ replicas)           │       │  │
    │  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐   │       │  │
    │  │  │  │Gateway-1 │  │Gateway-2 │  │Gateway-3 │   │       │  │
    │  │  │  │  (pod)   │  │  (pod)   │  │  (pod)   │   │       │  │
    │  │  │  └──────────┘  └──────────┘  └──────────┘   │       │  │
    │  │  │         Service (ClusterIP/LoadBalancer)    │       │  │
    │  │  └─────────────────────────────────────────────┘       │  │
    │  └────────────────────│───────────────────────────────────┘  │
    │    ┌──────────────────▼──────────────────┐    │              │
    │    │     ElastiCache Redis Cluster       │    │              │
    │    │         (Cache Layer)               │    │              │
    │    └─────────────────────────────────────┘    │              │
    │                                               │              │
    │                                               │              │
    │  ┌────────────────────────────────────────────▼ ───┐         │
    │  │    S3 Bucket (portkey-logs-prod)                │         │
    │  │    - LLM Request/Response Logs                  │         │
    │  │    - Encrypted at Rest (AES-256/KMS)            │         │
    │  └─────────────────────────────────────────────────┘         │
    └────┬─────────────│─────┬───────────────────┬─────────────────┘
         │             │     │                   │
         │ HTTPS:443   │     │ HTTPS:443         │ HTTPS:443
         │             │     │                   │
         ▼             │     ▼                   ▼
     ┌────────────────┐│  ┌──────────────────┐  ┌──────────────────┐
     │  AWS Bedrock   ││  │  GCP Vertex AI   │  │  Azure OpenAI    │
     │                ││  │                  │  │  / AI Foundry    │
     │ ┌────────────┐ ││  │ ┌──────────────┐ │  │ ┌──────────────┐ │
     │ │  Claude    │ ││  │ │   Gemini     │ │  │ │   GPT-4      │ │
     │ │  Llama     │ ││  │ │   Claude     │ │  │ │   GPT-4o     │ │
     │ │  Mistral   │ ││  │ │   PaLM       │ │  │ │   Other      │ │
     │ └────────────┘ ││  │ └──────────────┘ │  │ └──────────────┘ │
     │                ││  │                  │  │                  │
     │ us-east-1      ││  │ us-central1      │  │ eastus           │
     └────────────────┘│  └──────────────────┘  └──────────────────┘
                       │                         
                       │
     ┌─────────────────▼───────────────────────────────────────────────────┐
     │                      Portkey Control Plane                          │
     │                     (api.portkey.ai:443)                            │
     │                                                                     │
     │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐               │
     │  │  Provider    │  │Config Sync   │  │  Analytics   │               │
     │  │  Management  │  │              │  │              │               │
     │  └──────────────┘  └──────────────┘  └──────────────┘               │
     └─────────────────────────────────────────────────────────────────────┘

```

**Key Characteristics:**
- **Single Gateway Deployment**: One Kubernetes cluster hosting gateway
- **Multi-Provider Access**: Routes to AWS, GCP, and Azure LLMs
- **Cost**: Medium
- **Complexity**: Low to Medium

---

## Multi-Gateway Regional

### Provider-Affinity Architecture

**Scenario:** Separate gateway in each cloud for optimal latency

```
                    ┌───────────────────────────┐
                    │  Application/API GW Layer │
                    │  (Smart Routing Logic)    │
                    │                           │
                    │  Route to:                │
                    │  - AWS GW for Bedrock     │
                    │  - GCP GW for Vertex      │
                    │  - Azure GW for OpenAI    │
                    └───────────────────────────┘
                               │ HTTPS:443
                ┌──────────────┼──────────────────┐
                │              │                  │
                ▼              ▼                  ▼
    ┌───────────────────┐ ┌──────────────┐ ┌───────────────┐
    │   AWS Account     │ │ GCP Project  │ │Azure          │
    │      (VPC)        │ │    (VPC)     │ │Subscription   │
    │                   │ │              │ │   (VNet)      │
    │ ┌───────────────┐ │ │┌────────────┐│ │┌────────────┐ │
    │ │  EKS Cluster  │ │ ││GKE Cluster ││ ││AKS Cluster │ │
    │ │               │ │ ││            ││ ││            │ │
    │ │ ┌───────────┐ │ │ ││┌──────────┐││ ││┌──────────┐│ │
    │ │ │  Portkey  │ │ │ │││ Portkey  │││ │││ Portkey  ││ │
    │ │ │  (x3)     │ │ │ │││  (x3)    │││ │││  (x3)    ││ │
    │ │ └─────┬─────┘ │ │ ││└────┬─────┘││ ││└────┬─────┘│ │
    │ │       │       │ │ ││     │      ││ ││     │      │ │
    │ │   ElastiCache │ │ ││Memorystore ││ ││Azure Cache │ │
    │ │   Redis       │ │ ││   Redis    ││ ││  for Redis │ │
    │ │       │       │ │ ││     │      ││ ││     │      │ │
    │ │   S3 Bucket   │ │ ││ GCS Bucket ││ ││Blob Storage│ │
    │ └───────┼───────┘ │ │└─────┼──────┘│ │└─────┼──────┘ │
    └─────────┼─────────┘ └──────┼───────┘ └──────┼────────┘
              │       │          │       │                 │
              ▼       │          ▼       │                 |
      ┌──────────────┐│   ┌─────────────┐│  ┌─────────────┐|
      │AWS Bedrock   ││   │GCP Vertex AI││  │Azure OpenAI │|
      └──────────────┘│   └─────────────┘│  └─────────────┘|
                      │                  │                 │ 
                      │                  │                 │
                      ▼                  ▼                 |
     ┌───────────────────────────────────────────────┐     |
     │          Portkey Control Plane                │▼────┘
     │  (Shared Configuration Sync and Analytics)    │
     └───────────────────────────────────────────────┘
```

**Key Characteristics:**
- **Three Gateway Deployments**: One per cloud provider
- **Optimal Latency**: Each gateway near its primary LLM provider reducing network latency
- **Application Routing**: Smart routing logic to select appropriate gateway
- **Cost**: High
- **Complexity**: High

**When to Use:**
- Need low network latency to all providers
- Compliance requires data residency at each provider
---

## Network Flow Diagrams

### Request Flow - Successful Path

```
┌──────────┐
│Your App  │
│(Client)  │
└────┬─────┘
     │ 1. POST /v1/chat/completions
     │    Headers:
     │    - x-portkey-api-key
     │    - x-portkey-provider
     │
     ▼
┌─────────────────────────┐
│  Portkey Gateway        │
│  (Kubernetes Service)   │
└────┬────────────────────┘
     │ 2. Validate API Key
     │    Load Provider Config
     │    Check Cache
     │
     ▼
┌─────────────────────────┐          ┌─────────────────────────┐
│  Redis Cache            │  Cache   │                         │
│  - Provider Config      │  miss    │   Control Plane         │
│  - Rate Limits          │─────────▼│                         │
│  - Cached Responses     │          └─────────────────────────┘
└────┬────────────────────┘          
     │ 3. Config Retrieved
     │    Transform Request
     │
     ▼
┌─────────────────────────┐
│  LLM Provider           │
│  (AWS/GCP/Azure)        │
│  - Assume Role (if AWS) │
│  - Use SA (if GCP)      │
│  - Use MI (if Azure)    │
└────┬────────────────────┘
     │ 4. LLM Response
     │
     ▼
┌─────────────────────────┐
│  Portkey Gateway        │
│  - Log to Storage       │
│  - Send Analytics       │
│  - Transform Response   │
└────┬────────────────────┘
     │         6. Log Request (Async)
     │              │
     |              │
     │              ▼
     │    ┌─────────────────┐
     │    │ S3/GCS/Blob     │
     │    │ Storage         │
     │    │ (Logs)          │
     │    └─────────────────┘
     │              │ 
     │              │
     │              ▼
     │    ┌─────────────────┐
     │    │ Control Plane   │
     │    │ (Analytics)     │
     │    └─────────────────┘
     │ 
 5. Return Response
     │
     ▼
┌──────────┐
│Your App  │
│(Client)  │
└──────────┘
```

### Authentication Flow - AWS IRSA

```
┌─────────────────┐
│ Gateway Pod     │
│ (EKS)           │
└────┬────────────┘
     │
     │ 1. Pod starts with
     │    ServiceAccount annotation:
     │    eks.amazonaws.com/role-arn
     │
     ▼
┌─────────────────────────────┐
│  Kubernetes                 │
│  Mutating Webhook           │
│  - Injects env vars         │
│  - AWS_WEB_IDENTITY_TOKEN   │
│  - AWS_ROLE_ARN             │
└────┬────────────────────────┘
     │ 2. Pod has token mounted
     │    at /var/run/secrets/eks...
     │
     ▼
┌─────────────────┐
│ Gateway Pod     │
│ Makes AWS Call  │
│ (e.g., Bedrock) │
└────┬────────────┘
     │ 3. AWS SDK auto-detects
     │    web identity token
     │
     ▼
┌─────────────────────────────┐
│  AWS STS                    │
│  AssumeRoleWithWebIdentity  │
└────┬────────────────────────┘
     │ 4. Returns temporary
     │    credentials
     │    - Access Key
     │    - Secret Key
     │    - Session Token
     │    (Valid: 1 hour)
     │
     ▼
┌─────────────────┐
│ Gateway Pod     │
│ Uses temp creds │
└────┬────────────┘
     │ 5. Call Bedrock API
     │
     ▼
┌─────────────────┐
│ AWS Bedrock     │
│ (Success)       │
└─────────────────┘

Security Benefits:
✓ No long-term credentials
✓ Auto-rotation (1 hour)
✓ IAM policy enforcement
✓ CloudTrail audit logs
```

---

## Data Flow Patterns

### Log Storage Flow

```
Application Request
      │
      ▼
┌─────────────────┐
│ Gateway         │
│ (Receives)      │
└────┬────────────┘
     │
     ├─────────────────┐ Synchronous Path (Critical)
     │                 │
     │                 ▼
     │         ┌──────────────┐
     │         │ LLM Provider │
     │         │ (Call)       │
     │         └──────┬───────┘
     │                │
     │                ▼
     │         ┌──────────────┐
     │         │ Return to    │
     │         │ Application  │
     │         └──────────────┘
     │
     └─────────────────┐ Asynchronous Path (Non-blocking)
                       │
                       ▼
               ┌───────────────┐
               │ Log Queue     │
               │ (In-memory)   │
               └───────┬───────┘
                       │
                       ├──────────────┐
                       │              │
                       ▼              ▼
           ┌──────────────────┐  ┌──────────────────┐
           │ S3/GCS/Blob      │  │ Control Plane    │
           │ (Full Logs)      │  │ (Metrics)        │
           │                  │  │                  │
           │ - Request        │  │ - Token count    │
           │ - Response       │  │ - Latency        │
           │ - Metadata       │  │ - Cost           │
           │ - Timestamp      │  │ - Error rate     │
           │ - Virtual Key    │  │                  │
           └──────────────────┘  └──────────────────┘
```

### Analytics Flow

```

Control Plane Analytics (Recommended)
┌─────────┐     ┌─────────┐     ┌───────────────┐
│ Gateway │ ──> │ Batch   │ ──> │ Control Plane │
│         │     │ Buffer  │     │ (HTTPS POST)  │
└─────────┘     └─────────┘     └───────┬───────┘
                                        │
                                        ▼
                               ┌─────────────────┐
                               │ Portkey UI      │
                               │ - Dashboards    │
                               │ - Alerts        │
                               │ - Reports       │
                               └─────────────────┘


Option 2: OpenTelemetry
┌─────────┐     ┌─────────┐     ┌───────────────┐
│ Gateway │ ──> │ OTEL    │ ──> │ OTEL Collector│
│         │     │ Export  │     │               │
└─────────┘     └─────────┘     └───────┬───────┘
                                        │
                     ┌──────────────────┼─────────────┐
                     ▼                  ▼             ▼
              ┌───────────┐      ┌──────────┐  ┌──────────┐
              │Prometheus │      │Datadog   │  │New Relic │
              └───────────┘      └──────────┘  └──────────┘
```

---

## High Availability Patterns

### Active-Active Multi-AZ

```
                    ┌────────────────────┐
                    │  Application LB    │
                    │  (Layer 7)         │
                    └─────────┬──────────┘
                              │
        ┌─────────────────────┼─────────────────────┐
        │                     │                     │
        ▼                     ▼                     ▼
┌──────────────┐      ┌──────────────┐     ┌──────────────┐
│  AZ-1        │      │  AZ-2        │     │  AZ-3        │
│  (us-east-1a)│      │  (us-east-1b)│     │  (us-east-1c)│
│              │      │              │     │              │
│ ┌──────────┐ │      │ ┌──────────┐ │     │ ┌──────────┐ │
│ │Gateway-1 │ │      │ │Gateway-2 │ │     │ │Gateway-3 │ │
│ │(Active)  │ │      │ │(Active)  │ │     │ │(Active)  │ │
│ └──────────┘ │      │ └──────────┘ │     │ └──────────┘ │
│              │      │              │     │              │
│ ┌──────────┐ │      │ ┌──────────┐ │     │ ┌──────────┐ │
│ │Gateway-4 │ │      │ │Gateway-5 │ │     │ │Gateway-6 │ │
│ │(Active)  │ │      │ │(Active)  │ │     │ │(Active)  │ │
│ └──────────┘ │      │ └──────────┘ │     │ └──────────┘ │
└──────────────┘      └──────────────┘     └──────────────┘
        │                     │                     │
        └─────────────────────┼─────────────────────┘
                              │
                    ┌─────────▼──────────┐
                    │  ElastiCache       │
                    │  Redis Cluster     │
                    │  (Multi-AZ)        │
                    │  - Primary: AZ-1   │
                    │  - Replicas: AZ-2,3│
                    └────────────────────┘
                              │
                    ┌─────────▼──────────────────────────┐
                    │  S3 Bucket (Regional)              │
                    │  - LLM Request/Response Logs       │
                    │  - Encrypted at Rest (AES-256/KMS) │
                    │  - Versioning Enabled              │
                    │  - Auto-replicated across all AZs  │
                    └────────────────────────────────────┘


Characteristics:
- All gateways actively serving traffic
- Load balanced across AZs
- If one AZ fails, traffic routes to others
- Redis replication ensures cache availability
- All AZ gateways write to same S3 bucket
- S3 automatically handles multi-AZ data distribution
```

### Active-Passive with Failover

```
Primary Region (Active)               Secondary Region (Passive)
┌────────────────────────┐            ┌────────────────────────┐
│   us-east-1            │            │   us-west-2            │
│                        │            │                        │
│  ┌──────────────────┐  │            │  ┌──────────────────┐  │
│  │  Gateway (x5)    │  │            │  │  Gateway (x2)    │  │
│  │  (Active)        │  │            │  │  (Standby)       │  │
│  └────────┬─────────┘  │            │  └────────┬─────────┘  │
│           │            │            │           │            │
│  ┌────────▼─────────┐  │            │  ┌────────▼─────────┐  │
│  │  Redis           │  │───────────>│  │  Redis           │  │
│  │  (Primary)       │  │ Replication│  │  (Replica)       │  │
│  └──────────────────┘  │            │  └──────────────────┘  │
│                        │            │                        │
└────────────────────────┘            └────────────────────────┘
            │                                     │
            │                                     │
            ▼                                     ▼
    ┌────────────────┐                  ┌────────────────┐
    │ S3 Bucket      │                  │ S3 Bucket      │
    │ (Primary)      │──────────────────│ (Replica)      │
    │                │  CRR Replication │                │
    └────────────────┘                  └────────────────┘

            │
            ▼
    ┌────────────────────────┐
    │ Route53 Health Check   │
    │ - Check: /v1/health    │
    │ - Interval: 30s        │
    │ - Threshold: 3 fails   │
    └────────┬───────────────┘
             │
    ┌────────▼───────────────┐
    │ On Failure:            │
    │ 1. Update DNS          │
    │ 2. Point to us-west-2  │
    │ 3. Scale up secondary  │
    └────────────────────────┘
```