# Customising Email Templates

## Overview

The Control Plane uses an HTML-based email templating system that supports customization through environment variables and the ability to load custom templates from external sources (Kubernetes volumes). This allows organisations to fully rebrand and customize email content.

## Available Email Templates

| Template Name | Description | Used For |
|---------------|-------------|----------|
| `user-invite.html` | organisation invite emails | Inviting users to join an organisation |
| `user-email-verification.html` | Email verification | Verifying new user accounts |
| `virtualkey-usage-threshold-alert.html` | Virtual key threshold alert | When virtual key usage crosses threshold |
| `virtualkey-usage-exhausted-alert.html` | Virtual key exhausted | When virtual key budget is fully consumed |
| `virtualkey-expired-alert.html` | Virtual key expiration | When a virtual key expires |
| `apikey-usage-threshold-alert.html` | API key threshold alert | When API key usage crosses threshold |
| `apikey-usage-exhausted-alert.html` | API key exhausted | When API key budget is fully consumed |
| `apikey-expired-alert.html` | API key expiration | When an API key expires |
| `entity-usage-threshold-alert.html` | Generic entity threshold | When any entity reaches usage threshold |
| `entity-usage-exhausted-alert.html` | Generic entity exhausted | When any entity budget is consumed |
| `entity-expired-alert.html` | Generic entity expiration | When any entity expires |
| `domain-verification-alert.html` | Domain verification | Domain ownership verification |

---

## Environment Variables for Email Configuration

### Template Path Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `EMAIL_TEMPLATES_PATH` | Custom path to load email templates from (for Kubernetes volumes) | `./src/configs/email-templates` (bundled) |

### Branding & Content Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `EMAIL_COMPANY_NAME` | Company name displayed in emails | `Portkey` |
| `EMAIL_LOGO_URL` | URL to company logo image | Portkey logo URL |
| `EMAIL_SUPPORT_EMAIL` | Support email address | `support@portkey.ai` |
| `EMAIL_DOCS_URL` | Documentation URL | `https://docs.portkey.ai` |
| `CONTROL_PLANE_URL` | Control plane/dashboard URL | `https://app.portkey.ai` |

### SMTP Configuration 

| Variable | Description | Required |
|----------|-------------|----------|
| `SMTP_HOST` | SMTP server hostname | Yes |
| `SMTP_PORT` | SMTP server port | Yes |
| `SMTP_USER` | SMTP authentication username | Yes |
| `SMTP_PASSWORD` | SMTP authentication password | Yes |
| `SMTP_FROM` | Default sender email address | Yes |
| `SMTP_MAIL` | Enable SMTP mode | Yes |

---

## Template Placeholder System

Templates use mustache-style `{{placeholder}}` syntax. There are two types of variables:

### 1. Configuration Variables (from Environment)

These are automatically injected from environment variables:

```html
{{EMAIL_COMPANY_NAME}}      <!-- From EMAIL_COMPANY_NAME env var -->
{{EMAIL_LOGO_URL}}          <!-- From EMAIL_LOGO_URL env var -->
{{EMAIL_SUPPORT_EMAIL}}     <!-- From EMAIL_SUPPORT_EMAIL env var -->
{{EMAIL_DOCS_URL}}          <!-- From EMAIL_DOCS_URL env var -->
{{CONTROL_PLANE_URL}}       <!-- From CONTROL_PLANE_URL env var -->
```

### 2. Dynamic Variables (passed at runtime)

These are passed dynamically when sending emails:

```html
<!-- User Invite Template -->
{{inviterUserName}}         <!-- Name of person sending invite -->
{{inviterEmail}}            <!-- Email of person sending invite -->
{{organisationName}}        <!-- organisation name -->
{{inviteLink}}              <!-- Generated invite link -->

<!-- Alert Templates -->
{{userName}}                <!-- Recipient's name -->
{{virtualKeyName}}          <!-- Virtual key name -->
{{creditThreshold}}         <!-- Threshold value -->
{{creditLimit}}             <!-- Budget limit -->

<!-- Domain Verification -->
{{domain}}                  <!-- Domain being verified -->
{{verificationCode}}        <!-- Verification code -->
```

---

## Template Loading Mechanism

The template loading follows this priority:

```
1. Custom Path (EMAIL_TEMPLATES_PATH) - if set and contains templates
   ↓ (fallback)
2. Default Path (./src/configs/email-templates) - bundled templates
```

**Key Features:**
- Custom templates **override** default templates with the same name
- Missing custom templates **fall back** to default templates
- Allows partial customization (only override specific templates)

## Variable Substitution Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    Email Template (HTML)                        │
│                                                                 │
│   {{EMAIL_COMPANY_NAME}} {{userName}} {{organisationName}}      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Step 1: Environment Variables                  │
│                                                                 │
│   Replace: EMAIL_COMPANY_NAME, EMAIL_LOGO_URL,                  │
│            EMAIL_SUPPORT_EMAIL, EMAIL_DOCS_URL,                 │
│            CONTROL_PLANE_URL                                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  Step 2: Dynamic Variables                      │
│                                                                 │
│   Replace: userName, organisationName, inviteLink,              │
│            virtualKeyName, creditLimit, etc.                    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Final Rendered HTML                          │
│                                                                 │
│   "YourCompany" "Jane Smith" "Acme Corp"                        │
└─────────────────────────────────────────────────────────────────┘
```

---

## Per-Template Variable Reference

This section details all placeholders (environment variables and dynamic variables) used in each email template.

---

### 1. `user-invite.html` — organisation Invite

**Purpose:** Sent when a user is invited to join an organisation.

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `{{EMAIL_LOGO_URL}}` | Environment | Company logo image URL | `https://cdn.yourcompany.com/logo.png` |
| `{{EMAIL_COMPANY_NAME}}` | Environment | Company/product name | `YourCompany` |
| `{{EMAIL_SUPPORT_EMAIL}}` | Environment | Support email address | `support@yourcompany.com` |
| `{{EMAIL_DOCS_URL}}` | Environment | Documentation URL | `https://docs.yourcompany.com` |
| `{{organisationName}}` | Dynamic | Name of the organisation | `Acme Corp` |
| `{{inviterUserName}}` | Dynamic | Name of the person sending the invite | `John Doe` |
| `{{inviterEmail}}` | Dynamic | Email of the person sending the invite | `john@acme.com` |
| `{{inviteLink}}` | Dynamic | Full invite acceptance URL | `https://app.yourcompany.com/invite/abc123` |

---

### 2. `user-email-verification.html` — Email Verification

**Purpose:** Sent when a new user needs to verify their email address.

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `{{EMAIL_LOGO_URL}}` | Environment | Company logo image URL | `https://cdn.yourcompany.com/logo.png` |
| `{{EMAIL_COMPANY_NAME}}` | Environment | Company/product name | `YourCompany` |
| `{{EMAIL_SUPPORT_EMAIL}}` | Environment | Support email address | `support@yourcompany.com` |
| `{{verificationLink}}` | Dynamic | Email verification URL | `https://app.yourcompany.com/verify/xyz789` |

---

### 3. `virtualkey-usage-threshold-alert.html` — Virtual Key Threshold Alert

**Purpose:** Sent when a virtual key usage reaches the configured threshold.

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `{{EMAIL_LOGO_URL}}` | Environment | Company logo image URL | `https://cdn.yourcompany.com/logo.png` |
| `{{EMAIL_COMPANY_NAME}}` | Environment | Company/product name | `YourCompany` |
| `{{EMAIL_SUPPORT_EMAIL}}` | Environment | Support email address | `support@yourcompany.com` |
| `{{CONTROL_PLANE_URL}}` | Environment | Control plane base URL (for CTA link) | `https://app.yourcompany.com` |
| `{{userName}}` | Dynamic | Recipient's name | `Jane Smith` |
| `{{virtualKeyName}}` | Dynamic | Name of the virtual key | `Production Key` |
| `{{organisationName}}` | Dynamic | organisation name | `Acme Corp` |
| `{{creditThreshold}}` | Dynamic | Alert threshold value | `$80.00` |
| `{{creditLimit}}` | Dynamic | Total budget limit | `$100.00` |

**CTA Link:** `{{CONTROL_PLANE_URL}}/virtual-keys`

---

### 4. `virtualkey-usage-exhausted-alert.html` — Virtual Key Budget Exhausted

**Purpose:** Sent when a virtual key has fully consumed its budget.

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `{{EMAIL_LOGO_URL}}` | Environment | Company logo image URL | `https://cdn.yourcompany.com/logo.png` |
| `{{EMAIL_COMPANY_NAME}}` | Environment | Company/product name | `YourCompany` |
| `{{EMAIL_SUPPORT_EMAIL}}` | Environment | Support email address | `support@yourcompany.com` |
| `{{CONTROL_PLANE_URL}}` | Environment | Control plane base URL | `https://app.yourcompany.com` |
| `{{userName}}` | Dynamic | Recipient's name | `Jane Smith` |
| `{{virtualKeyName}}` | Dynamic | Name of the virtual key | `Production Key` |
| `{{organisationName}}` | Dynamic | organisation name | `Acme Corp` |
| `{{creditLimit}}` | Dynamic | Budget limit that was reached | `$100.00` |

**CTA Link:** `{{CONTROL_PLANE_URL}}/virtual-keys`

---

### 5. `virtualkey-expired-alert.html` — Virtual Key Expired

**Purpose:** Sent when a virtual key has expired.

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `{{EMAIL_LOGO_URL}}` | Environment | Company logo image URL | `https://cdn.yourcompany.com/logo.png` |
| `{{EMAIL_COMPANY_NAME}}` | Environment | Company/product name | `YourCompany` |
| `{{EMAIL_SUPPORT_EMAIL}}` | Environment | Support email address | `support@yourcompany.com` |
| `{{CONTROL_PLANE_URL}}` | Environment | Control plane base URL | `https://app.yourcompany.com` |
| `{{userName}}` | Dynamic | Recipient's name | `Jane Smith` |
| `{{virtualKeyName}}` | Dynamic | Name of the virtual key | `Production Key` |
| `{{organisationName}}` | Dynamic | organisation name | `Acme Corp` |

**CTA Link:** `{{CONTROL_PLANE_URL}}/virtual-keys`

---

### 6. `apikey-usage-threshold-alert.html` — API Key Threshold Alert

**Purpose:** Sent when an API key usage reaches the configured threshold.

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `{{EMAIL_LOGO_URL}}` | Environment | Company logo image URL | `https://cdn.yourcompany.com/logo.png` |
| `{{EMAIL_COMPANY_NAME}}` | Environment | Company/product name | `YourCompany` |
| `{{EMAIL_SUPPORT_EMAIL}}` | Environment | Support email address | `support@yourcompany.com` |
| `{{CONTROL_PLANE_URL}}` | Environment | Control plane base URL | `https://app.yourcompany.com` |
| `{{userName}}` | Dynamic | Recipient's name | `Jane Smith` |
| `{{apiKeyType}}` | Dynamic | Type of API key (e.g., "Standard", "Admin") | `Standard` |
| `{{apiKey}}` | Dynamic | API key identifier/name | `pk-prod-xxx` |
| `{{organisationName}}` | Dynamic | organisation name | `Acme Corp` |
| `{{creditThreshold}}` | Dynamic | Alert threshold value | `$80.00` |
| `{{creditLimit}}` | Dynamic | Total budget limit | `$100.00` |

**CTA Link:** `{{CONTROL_PLANE_URL}}/api-keys`

---

### 7. `apikey-usage-exhausted-alert.html` — API Key Budget Exhausted

**Purpose:** Sent when an API key has fully consumed its budget.

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `{{EMAIL_LOGO_URL}}` | Environment | Company logo image URL | `https://cdn.yourcompany.com/logo.png` |
| `{{EMAIL_COMPANY_NAME}}` | Environment | Company/product name | `YourCompany` |
| `{{EMAIL_SUPPORT_EMAIL}}` | Environment | Support email address | `support@yourcompany.com` |
| `{{CONTROL_PLANE_URL}}` | Environment | Control plane base URL | `https://app.yourcompany.com` |
| `{{userName}}` | Dynamic | Recipient's name | `Jane Smith` |
| `{{apiKeyType}}` | Dynamic | Type of API key | `Standard` |
| `{{apiKey}}` | Dynamic | API key identifier/name | `pk-prod-xxx` |
| `{{organisationName}}` | Dynamic | organisation name | `Acme Corp` |
| `{{creditLimit}}` | Dynamic | Budget limit that was reached | `$100.00` |

**CTA Link:** `{{CONTROL_PLANE_URL}}/api-keys`

---

### 8. `apikey-expired-alert.html` — API Key Expired

**Purpose:** Sent when an API key has expired.

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `{{EMAIL_LOGO_URL}}` | Environment | Company logo image URL | `https://cdn.yourcompany.com/logo.png` |
| `{{EMAIL_COMPANY_NAME}}` | Environment | Company/product name | `YourCompany` |
| `{{EMAIL_SUPPORT_EMAIL}}` | Environment | Support email address | `support@yourcompany.com` |
| `{{CONTROL_PLANE_URL}}` | Environment | Control plane base URL | `https://app.yourcompany.com` |
| `{{userName}}` | Dynamic | Recipient's name | `Jane Smith` |
| `{{apiKeyType}}` | Dynamic | Type of API key | `Standard` |
| `{{apiKey}}` | Dynamic | API key identifier/name | `pk-prod-xxx` |
| `{{organisationName}}` | Dynamic | organisation name | `Acme Corp` |

**CTA Link:** `{{CONTROL_PLANE_URL}}/api-keys`

---

### 9. `entity-usage-threshold-alert.html` — Generic Entity Threshold Alert

**Purpose:** Sent when any entity (workspace, team, etc.) usage reaches threshold.

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `{{EMAIL_LOGO_URL}}` | Environment | Company logo image URL | `https://cdn.yourcompany.com/logo.png` |
| `{{EMAIL_COMPANY_NAME}}` | Environment | Company/product name | `YourCompany` |
| `{{EMAIL_SUPPORT_EMAIL}}` | Environment | Support email address | `support@yourcompany.com` |
| `{{entityType}}` | Dynamic | Type of entity (e.g., "Workspace", "Team") | `Workspace` |
| `{{entityName}}` | Dynamic | Name of the entity | `Production Workspace` |
| `{{entityKey}}` | Dynamic | Unique identifier/key of the entity | `ws-prod-123` |
| `{{entityUrl}}` | Dynamic | Full URL to manage the entity | `https://app.yourcompany.com/workspaces/123` |
| `{{userName}}` | Dynamic | Recipient's name | `Jane Smith` |
| `{{organisationName}}` | Dynamic | organisation name | `Acme Corp` |
| `{{creditThreshold}}` | Dynamic | Alert threshold value | `$800.00` |
| `{{creditLimit}}` | Dynamic | Total budget limit | `$1000.00` |

**CTA Link:** `{{entityUrl}}` (dynamic per entity)

---

### 10. `entity-usage-exhausted-alert.html` — Generic Entity Budget Exhausted

**Purpose:** Sent when any entity has fully consumed its budget.

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `{{EMAIL_LOGO_URL}}` | Environment | Company logo image URL | `https://cdn.yourcompany.com/logo.png` |
| `{{EMAIL_COMPANY_NAME}}` | Environment | Company/product name | `YourCompany` |
| `{{EMAIL_SUPPORT_EMAIL}}` | Environment | Support email address | `support@yourcompany.com` |
| `{{entityType}}` | Dynamic | Type of entity | `Workspace` |
| `{{entityName}}` | Dynamic | Name of the entity | `Production Workspace` |
| `{{entityKey}}` | Dynamic | Unique identifier/key of the entity | `ws-prod-123` |
| `{{entityUrl}}` | Dynamic | Full URL to manage the entity | `https://app.yourcompany.com/workspaces/123` |
| `{{userName}}` | Dynamic | Recipient's name | `Jane Smith` |
| `{{organisationName}}` | Dynamic | organisation name | `Acme Corp` |
| `{{creditLimit}}` | Dynamic | Budget limit that was reached | `$1000.00` |

**CTA Link:** `{{entityUrl}}` (dynamic per entity)

---

### 11. `entity-expired-alert.html` — Generic Entity Expired

**Purpose:** Sent when any entity has expired.

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `{{EMAIL_LOGO_URL}}` | Environment | Company logo image URL | `https://cdn.yourcompany.com/logo.png` |
| `{{EMAIL_COMPANY_NAME}}` | Environment | Company/product name | `YourCompany` |
| `{{EMAIL_SUPPORT_EMAIL}}` | Environment | Support email address | `support@yourcompany.com` |
| `{{entityType}}` | Dynamic | Type of entity | `Workspace` |
| `{{entityName}}` | Dynamic | Name of the entity | `Production Workspace` |
| `{{entityKey}}` | Dynamic | Unique identifier/key of the entity | `ws-prod-123` |
| `{{entityUrl}}` | Dynamic | Full URL to manage the entity | `https://app.yourcompany.com/workspaces/123` |
| `{{userName}}` | Dynamic | Recipient's name | `Jane Smith` |
| `{{organisationName}}` | Dynamic | organisation name | `Acme Corp` |

**CTA Link:** `{{entityUrl}}` (dynamic per entity)

---

### 12. `domain-verification-alert.html` — Domain Verification

**Purpose:** Sent when domain ownership verification is required.

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `{{EMAIL_LOGO_URL}}` | Environment | Company logo image URL | `https://cdn.yourcompany.com/logo.png` |
| `{{EMAIL_COMPANY_NAME}}` | Environment | Company/product name | `YourCompany` |
| `{{EMAIL_SUPPORT_EMAIL}}` | Environment | Support email address | `support@yourcompany.com` |
| `{{organisationName}}` | Dynamic | organisation name | `Acme Corp` |
| `{{domain}}` | Dynamic | Domain being verified | `acme.com` |
| `{{verificationCode}}` | Dynamic | Verification code to use | `vrf-abc123xyz` |

---

## Environment Variables Quick Reference (All Templates)

These environment variables are shared across **all** templates:

| Environment Variable | Description | Default Value | Required |
|---------------------|-------------|---------------|----------|
| `EMAIL_TEMPLATES_PATH` | Path to custom templates directory | Bundled templates | No |
| `EMAIL_COMPANY_NAME` | Your company/product name | `Portkey` | Yes (for branding) |
| `EMAIL_LOGO_URL` | Full URL to your logo image | Portkey logo | Yes (for branding) |
| `EMAIL_SUPPORT_EMAIL` | Support contact email | `support@portkey.ai` | Yes (for branding) |
| `EMAIL_DOCS_URL` | Documentation URL | `https://docs.portkey.ai` | No |
| `CONTROL_PLANE_URL` | Base URL for your control plane/dashboard | `https://app.portkey.ai` | Yes (for CTAs) |

---

## Kubernetes Implementation

### Step 1: Create ConfigMap with Custom Templates

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: control-plane-email-templates
  namespace: your-namespace
data:
  user-invite.html: |
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title></title>
    </head>
    <body style="font-family: Inter, sans-serif;line-height: 1.6;color: #333;max-width: 610px;margin: 0 auto;padding: 20px;background-color: #f0f0f0;">
      <div class="email-content" style="background-color: #ffffff;padding: 50px;border-radius: 10px;">
        <img src="{{EMAIL_LOGO_URL}}" alt="{{EMAIL_COMPANY_NAME}} Banner" style="width: 30%; height: auto;">
        
        <div class="banner" style="display: flex;align-items: center;justify-content: space-between;background-color: #F5F5F5;padding: 10px 30px;border-radius: 8px;margin: 20px 0;">
          <h2 class="banner-title" style="font-size: 20px;font-weight: 600;letter-spacing: 0.4px;color: #1F2937;">
            You're Invited to Join {{organisationName}}
          </h2>
        </div>
        
        <p>Hey,</p>
        <div>{{inviterUserName}} ({{inviterEmail}}) has invited you to join {{organisationName}} on {{EMAIL_COMPANY_NAME}}.</div>
        <br>
        <a href="{{inviteLink}}" class="cta" style="display: fit;padding: 12px 28px;justify-content: center;align-items: center;gap: 10px;border-radius: 6px;background: #06B6D4;color: #ffffff;text-decoration: none;margin-top: 10px;font-weight: 600px;">
          <strong style="color: #FFFFFF;font-weight:600px">Accept Invite</strong>
        </a>
        <br><br>
        <p>{{EMAIL_COMPANY_NAME}} serves as your mission control for launching and managing AI apps in production.
          <a class="docs-link" href="{{EMAIL_DOCS_URL}}" style="color: #06B6D4;font-family: Inter, sans-serif;text-decoration: none;font-style: normal;font-weight: 600px;letter-spacing: -0.1px;">
            🔗 Learn More.
          </a>
        </p>
        <p>This invitation expires in 2 days. If you weren't expecting this invite, you can ignore this email.</p>
        <p>Best,<br> Team {{EMAIL_COMPANY_NAME}}</p>
        <hr style="border: none;height: 1px;background-color: #e5e5e5;margin: 20px 0;">
        <p>Need help? Email <a href="mailto:{{EMAIL_SUPPORT_EMAIL}}" class="docs-link" style="color: #06B6D4;font-family: Inter, sans-serif;text-decoration: none;font-style: normal;font-weight: 600px;letter-spacing: -0.1px;">{{EMAIL_SUPPORT_EMAIL}}</a></p>
      </div>
    </body>
    </html>

  virtualkey-usage-threshold-alert.html: |
    <!-- Add your custom template content here -->
    <!-- Only include templates you want to override -->
```

### Step 2: Update helm values for backend

```yaml
backend:
  deployment:
    extraEnv:
      # Email Templates Path - Points to mounted volume
      - name: EMAIL_TEMPLATES_PATH
        value: "/app/custom-email-templates"
      # Branding Configuration
      - name: EMAIL_COMPANY_NAME
        value: "YourCompany"
      - name: EMAIL_LOGO_URL
        value: "https://your-cdn.com/logo.png"
      - name: EMAIL_SUPPORT_EMAIL
        value: "support@yourcompany.com"
      - name: EMAIL_DOCS_URL
        value: "https://docs.yourcompany.com"
      - name: CONTROL_PLANE_URL
        value: "https://app.yourcompany.com"
    volumeMounts:
      - name: email-templates
        mountPath: /app/custom-email-templates
        readOnly: true
    volumes:
      - name: email-templates
        configMap:
          name: control-plane-email-templates
```

---

## Testing Your Configuration

1. **Verify templates are loaded:**
   Check application logs for:
   ```
   Attempting to load email templates from custom path
   Loaded X custom email templates from /app/custom-email-templates
   Total templates available: 12
   ```

2. **Fallback behavior:**
   If custom path has issues, logs will show:
   ```
   No templates found in custom path, falling back to default templates
   ```

3. **Send test invite:**
   Trigger an invite email to verify branding and links are correct.

---

## Best Practices

1. **Partial Override:** Only include templates you want to customize in the ConfigMap
2. **CDN for Images:** Host logo images on a CDN with proper HTTPS
3. **Template Validation:** Test all templates in a staging environment first
