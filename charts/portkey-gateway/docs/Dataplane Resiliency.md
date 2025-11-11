The hybrid architecture ensures that your production LLM traffic continues flowing even during extended Control Plane outages, with automatic recovery once connectivity is restored.

## Data Plane to Control Plane Communication

### Network Flow Diagram

```
## Data Plane ↔ Control Plane Communication Flow

┌─────────────────────────────────────────────────────────────────────────┐
│                        YOUR VPC (Data Plane)                            │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐  │
│  │               EKS/GKE/AKS Cluster                                 │  │
│  │                                                                   │  │
│  │  ┌─────────────────────────────────────────────────────────┐      │  │
│  │  │         Portkey AI Gateway Pods (3+ replicas)           │      │  │
│  │  │  ┌──────────┐  ┌──────────┐  ┌──────────┐               │      │  │
│  │  │  │Gateway-1 │  │Gateway-2 │  │Gateway-3 │               │      │  │
│  │  │  │  (pod)   │  │  (pod)   │  │  (pod)   │               │      │  │
│  │  │  └────┬─────┘  └────┬─────┘  └────┬─────┘               │      │  │
│  │  └───────┼─────────────┼─────────────┼─────────────────────┘      │  │
│  │          │             │             │                            │  │
│  └──────────┼─────────────┼─────────────┼────────────────────────────┘  │
│             │             │             │                               │
│             └─────────────┼─────────────┘                               │
│                           │                                             │
│  ┌────────────────────────▼───────────────────────────┐                 │
│  │         Redis Cache (ElastiCache/Memorystore)      │                 │
│  │                                                    │                 │
│  │  Cached Data (refreshed every 30s):                │                 │
│  │  ✓ Provider configurations                         │                 │
│  │  ✓ Routing configs                                 │                 │
│  │  ✓ Virtual keys & integrations                     │                 │
│  │  ✓ Prompt templates                                │                 │
│  │  ✓ API keys (encrypted)                            │                 │
│  │  ✓ Rate limit and Budget limit states              │                 │
│  └────────────────────────────────────────────────────┘                 │
│                           │                                             │
│  ┌────────────────────────▼───────────────────────────┐                 │
│  │        S3/GCS/Blob Storage                         │                 │
│  │                                                    │                 │
│  │  ✓ LLM Request/Response Logs (Full)                │                 │
│  │  ✓ Encrypted at Rest (AES-256/KMS)                 │                 │
│  │  ✓ Metadata & Timestamps                           │                 │
│  └────────────────────────────────────────────────────┘                 │
│                                                                         │
└─────────────┬─────────────────────────────────┬─────────────────────────┘
              │                                 │
              │ HTTPS:443                       │ HTTPS:443
              │ (Outbound Only)                 │ (Outbound Only)
              │                                 │
    ┌─────────▼─────────────┐         ┌─────────▼────────────────┐
    │  1. Config Sync       │         │  2. Analytics Push       │
    │  (Every 30 seconds)   │         │  (Batch 3000 every 3 sec)│
    └─────────┬─────────────┘         └─────────┬────────────────┘
              │                                 │
              └─────────────────┬───────────────┘
                                │
                                │
              ┌─────────────────▼──────────────────────────────────────┐
              │        PORTKEY CONTROL PLANE (Portkey VPC)             │
              │              api.portkey.ai:443                        │
              │                                                        │
              │  ┌──────────────────────────────────────────────────┐  │
              │  │  Endpoints Used by Data Plane:                   │  │
              │  │                                                  │  │
              │  │  1. sync                                         │  │
              │  │     - Fetch routing configs                      │  │
              │  │     - Fetch provider integrations                │  │
              │  │     - Fetch virtual keys (encrypted)             │  │
              │  │     - Fetch prompt templates                     │  │
              │  │     - Fetch API keys                             │  │
              │  │     Frequency: 30-second polling                 │  │
              │  │                                                  │  │
              │  │  2. analytics                                    │  │
              │  │     - Send anonymized metrics                    │  │
              │  │     - Token counts, latencies, costs             │  │
              │  │     - Model usage stats                          │  │
              │  │     - Error rates                                │  │
              │  │     Frequency: Batch                             │  │
              │  │                                                  │  │
              │  └──────────────────────────────────────────────────┘  │
              │                                                        │
              │  ┌──────────────────────────────────────────────────┐  │
              │  │  Control Plane Components:                       │  │
              │  │                                                  │  │
              │  │  • Web Dashboard (UI)                            │  │
              │  │  • ClickHouse (Analytics Store)                  │  │
              │  └──────────────────────────────────────────────────┘  │
              └────────────────────────────────────────────────────────┘
```

### Detailed Communication Patterns

#### 1. Configuration Sync Flow (Every 30 seconds)

```
┌──────────────┐
│ Gateway Pod  │
└──────┬───────┘
       │
       │ 1. Heartbeat Timer (30s)
       │
       ▼
┌────────────────────────┐
│ Check Redis Cache      │
│ - Last sync timestamp  │
└──────┬─────────────────┘
       │
       │ 2. If 30s elapsed
       │
       ▼
┌────────────────────────────────┐
│ HTTPS POST to Control Plane    │
│                                │
│ Headers:                       │
│ - Authorization                │
└──────┬─────────────────────────┘
       │
       │ 3. Response received
       │
       ▼
┌────────────────────────────────┐
│ Control Plane Response         │
│                                │
│ 1. providers                   │ 
│ 2. api keys                    │
│ 3. configs                     │
│ 4. prompts                     │
└──────┬─────────────────────────┘
       │
       │ 4. Decrypt locally
       │
       ▼
┌─────────────────────────────────┐
│ Store in Redis Cache            │
└─────────────────────────────────┘
       │
       │ 5. Ready for requests
       │
       ▼
┌─────────────────────────────────┐
│ Gateway serves LLM requests     │
│ using cached configs            │
└─────────────────────────────────┘
```

#### 2. Analytics Push Flow

```
┌──────────────┐
│ Gateway Pod  │
│ Receives     │
│ LLM Request  │
└──────┬───────┘
       │
       │ 1. Process request
       │
       ▼
┌────────────────────────┐
│ Call LLM Provider      │
│ (AWS/GCP/Azure)        │
└──────┬─────────────────┘
       │
       │ 2. Receive response
       │
       ▼
┌────────────────────────────┐
│ Extract Metrics (Non-PII)  │
│ - model: "gpt-4"           │
│ - total_tokens: 1523       │
│ - response_time: 2340ms    │
│ - cost: 0.045 (cents)      │
│ - created_at: UTC          │
└──────┬─────────────────────┘
       │
       │ 3. Add to batch buffer
       │    (in-memory queue)
       │
       ▼
┌──────────────────────────────┐
│ Batch Buffer                 │
│ (Flush when:)                │
│ - 3000 events, OR            │
│ - 3 seconds elapsed          │
└──────┬───────────────────────┘
       │
       │ 4. Batch ready
       │
       ▼
┌──────────────────────────────────┐
│ HTTPS POST (Async)               │
│                                  │
│ Body: [{metrics}, {metrics}...]  │
└──────┬───────────────────────────┘
       │
       │ 5. Fire & forget
       │    (non-blocking)
       │
       ▼
┌──────────────────────────────┐
│ Return response to app       │
│ (Analytics doesn't block)    │
└──────────────────────────────┘


       Meanwhile in Control Plane:
       
       ▼
┌──────────────────────────────┐
│ Analytics Service            │
│ - Receives batch             │
│ - Validates metrics          │
│ - Stores in ClickHouse       │
│ - Updates dashboards         │
└──────────────────────────────┘
```

---

## Control Plane Outage Scenario

```

Normal Operation
┌──────────────┐
│ Gateway      │◄──30s sync──► Control Plane ✓
│ Cached: OK   │
└──────────────┘

Control Plane Unreachable
┌──────────────┐
│ Gateway      │  ──sync──X     Control Plane ✗
│ Cached: OK   │                (Network issue)
└──────────────┘
│
└──► Gateway continues using cached config
     All LLM requests work normally
     Analytics queued in memory


Network restored
┌──────────────┐
│ Gateway      │◄──sync──✓      Control Plane ✓
│ Cached: FRESH│
└──────────────┘
│
└──► Sync succeeds
     Cached configs updated
     Queued analytics sent
     Normal operation resumed

✅ IMPACT: ZERO - No user-facing disruption
✅ LLM Requests: All successful
✅ Data Loss: None (analytics queued)
```

**What Works:**
- ✅ All LLM requests (using cached provider configs)
- ✅ Rate limiting (using cached limits)
- ✅ Routing/Load balancing (using cached rules)
- ✅ Caching responses (local Redis)
- ✅ Log storage (to S3/GCS/Blob)

**What's Affected:**
- ⚠️ Analytics delayed (queued, sent after recovery)
- ⚠️ Dashboard shows stale data
- ⚠️ Can't create new virtual keys (UI)
- ⚠️ Can't update routing configs (UI)


Operational Impact:
```
✅ WORKING:
┌───────────────────────────────────────────────┐
│ • All existing LLM provider calls             │
│ • Rate limiting (last known state)            │
│ • Caching (local Redis)                       │
│ • Request logging (S3/GCS/Blob)               │
│ • Guardrails (cached configs)                 │
│ • Load balancing (cached strategy)            │
└───────────────────────────────────────────────┘
❌ NOT WORKING:
┌───────────────────────────────────────────────┐
│ • New provider configurations                 │
│ • New virtual key creation                    │
│ • Routing config updates                      │
│ • Prompt template updates                     │
│ • Real-time dashboard analytics               │
│ • Control Plane UI operations                 │
└───────────────────────────────────────────────┘
```

### WORKAROUND for urgent provider changes:
```
┌─────────────────────────────────────────────────────┐
│ Direct Portkey API Key in Request Headers           │
│                                                     │
│ curl -X POST <gateway-url>/v1/chat/completions \    │
│   -H "Authorization: Bearer sk-abc123" \            │
│   -H "x-portkey-provider: azure-openai" \           │
│   -H "x-portkey-api-key: <azure-key>" \             │
│   -d '{"model": "gpt-4", ...}'                      │
│                                                     │
└─────────────────────────────────────────────────────┘
⚠️ Bypasses provider config, but works during outage 

WHEN CONTROL PLANE RECOVERS:
┌─────────────────────────────────────────────────────┐
│ 1. User completes provider setup in UI              │
│ 2. Gateway syncs new config within 30 seconds       │
│ 3. New provider immediately available               │
│ 4. Provider keys work as expected                   │
└─────────────────────────────────────────────────────┘
```

---


## Security During Outages

```
┌─────────────────────────────────────────────────────┐
│ Data Security Maintained During Control Plane       │
│ Outage:                                             │
│                                                     │
│ ✅ LLM Request/Response Data:                       │
│    • Never leaves your VPC                          │
│    • Stored in your S3/GCS/Blob                     │
│    • Encrypted at rest                              │
│    • Zero dependency on Control Plane               │
│                                                     │
│ ✅ API Keys & Secrets:                              │
│    • Cached in encrypted form in Redis              │
│    • Decrypted locally by gateway                   │
│    • Never exposed during outage                    │
│                                                     │
│ ✅ Authentication:                                  │
│    • Portkey API keys validated from cache          │
│    • Rate limits enforced locally                   │
│    • No auth bypasses during outage                 │
│                                                     │
│ ⚠️  Analytics Data:                                 │
│    • Queued locally (non-sensitive metrics only)    │
│    • No PII or prompt content                       │
│    • Sent when connection restored                  │
└─────────────────────────────────────────────────────┘
```

---

## Best Practices for Control Plane Outage Resilience

### 1. **Use External Managed Redis with Persistence enabled**
```yaml
# In your values.yaml
REDIS_URL: <external redis url>
```

### 2. **Horizontal Pod Autoscaling During Outages**
```yaml
autoscaling:
  enabled: true
  minReplicas: 3  # Higher minimum during outage risk
  maxReplicas: 20
  targetCPUUtilizationPercentage: 60
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 600  # Slower scale-down during uncertainty
```
---

## References

- [Portkey Hybrid Architecture Documentation](https://portkey.ai/docs/self-hosting/hybrid-deployments/architecture)
- Helm Chart Values: `values.yaml`
- Architecture Diagrams: `/docs/Architecture Diagrams.md`