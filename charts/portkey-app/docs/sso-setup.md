# SSO Setup Guide

## Control Plane Url

Setup the Control plane url in your values file. It will be the same as `<frontend alb endpoint>`

```yaml
config:
  controlPlaneURL: "<frontend alb endpoint>"
```

Config example

``` yaml
config:
  controlPlaneURL: "https://frontend.example.com"
```

## SAML

### Setup

**In your Identity Provider (IdP), configure:**

  * **Assertion Consumer Service (ACS) URL:**

    ```
    <frontend alb endpoint>/albus/v2/auth/saml/callback/<uuid>
    ```
  * **Audience URI (SP Entity ID):**

    ```
    <frontend alb endpoint>/albus/v2/auth/saml
    ```

Update the below in your values file

``` yaml
config:
  noAuth:
    enabled: false
  oauth:
    enabled: true
    oauthType: saml
    oauthIssuerUrl: "<idp metadata saml url>"
```

### Config Example

```yaml
config:
  jwtPrivateKey: "secret123"
  controlPlaneURL: "https://frontend.example.com"
  noAuth:
    enabled: false
  oauth:
    enabled: true
    oauthType: "saml"
    oauthIssuerUrl: "https://idp.example.com/saml/metadata"
    # In your Idp setup
    # SAML Assertion Consumer Service (ACS) URL:
    #   https://frontend.example.com/albus/v2/auth/saml/callback/bf0afde9-b14c-4da6-a716-76b215b76812
    # SAML Audience URI (SP Entity ID):
    #   https://frontend.example.com/albus/v2/auth/saml
```

---

## OIDC

### Setup

**In your OIDC Client, register:**

  * **Redirect URI:**

    ```
    <frontend alb endpoint>/v2/auth/callback
    ```
Update the below in your values file

``` yaml
config:
  noAuth:
    enabled: false
  oauth:
    enabled: true
    oauthType: "oidc"
    oauthIssuerUrl: "<idp oidc issuer url>"
    oauthClientId: "<idp oidc clientid>"
    oauthClientSecret: "<idp oidc client secret>"
    oauthRedirectURI: "<frontend alb endpoint>/v2/auth/callback"
```


### Config Example

```yaml
config:
  jwtPrivateKey: "secret123"
  controlPlaneURL: "https://frontend.example.com"
  noAuth:
    enabled: false
  oauth:
    enabled: true
    oauthType: oidc
    oauthIssuerUrl: "https://accounts.example-oidc.com"
    oauthClientId: "my-client-id"
    oauthClientSecret: "my-client-secret"
    oauthRedirectURI: "https://frontend.example.com/v2/auth/callback"
    # Register this redirect URI in your OIDC client:
    #   https://frontend.example.com/v2/auth/callback
```

---

**Note:**

* Use only one `oauthType` (`saml` or `oidc`) in the config at a time.
* Replace example values in the config with your actual deployment values.