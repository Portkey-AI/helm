## **Complete List of Outbound Calls from Gateway to Control Plane**

### 1. API Key & Authentication

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/v2/api-keys/self/details` | GET | Validate API key and fetch org/workspace details |

### 2. Resource Fetching

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/v2/virtual-keys/{slug}` | GET | Fetch virtual key details |
| `/v2/configs/{slug}` | GET | Fetch gateway config |
| `/v2/prompts/{slug}` | GET | Fetch prompt template |
| `/v2/prompts/partials/{slug}` | GET | Fetch prompt partials |
| `/v2/guardrails/{slug}` | GET | Fetch guardrail config |
| `/v2/integrations/` | GET | Fetch integrations |

### 3. Usage & Sync

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/v1/organisation/{orgId}/resync` | POST | Resync usage/budget data to control plane |
| `/v1/organisation/{orgId}/sync/{timestamp}` | GET | Sync cache invalidations from control plane |

### 4. Analytics

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/dp/metrics` (CONTROL_PLANE)| POST | Push analytics/metrics |

### 5. MCP 

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/v2/mcp-servers/{serverId}` | GET | Get MCP server config |
| `/v2/mcp-servers/{serverId}/client-info` | GET | Get MCP client info |
| `/v2/mcp-servers/{serverId}/tokens` | GET | Get server tokens |
| `/v2/mcp-servers/{serverId}/tokens` | PUT | Save server tokens |
| `/v2/mcp-servers/{serverId}/tokens` | DELETE | Delete server tokens |
| `/v2/oauth/introspect` | POST | Token introspection |
| `/v2/oauth/register` | POST | OAuth client registration |
| `/v2/oauth/{resourceId}/authorize` | GET | OAuth authorize |
| `/v2/oauth/revoke` | POST | Revoke token |
| `/v2/oauth/token` | POST | Token exchange |