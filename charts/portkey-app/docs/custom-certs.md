If you are using custom certs for any communications, this would results in TLS rejection error. 

You can use the below two solutions to solve this

## Solution 1: Use NODE_EXTRA_CA_CERTS (Recommended)

### 1. Create the ConfigMap (only once):
```bash
kubectl create configmap custom-ca-cert \
  --from-file=ca-cert.pem=/path/to/your/mgtd-ca-cert.pem \
  -n portkey
```

### 2. Update the values for the three below services

```yaml
backend:
  name: "backend"
  containerPort: 8080
  deployment:
    autoRestart: true
    replicas: 1
    labels: {}
    annotations: {}
    podSecurityContext: {}
    securityContext: {}
    
    # Add extra environment variables for backend
    extraEnv:
      - name: NODE_EXTRA_CA_CERTS
        value: "/etc/ssl/certs/custom/ca-cert.pem"
    
    # Add volume mounts for backend
    volumeMounts:
      - name: custom-ca-cert
        mountPath: /etc/ssl/certs/custom
        readOnly: true
    
    # Add volumes for backend
    volumes:
      - name: custom-ca-cert
        configMap:
          name: custom-ca-cert
    
    # ... rest of your backend configuration ...

gateway:
  name: "gateway"
  enabled: true
  containerPort: 8787
  deployment:
    autoRestart: true
    replicas: 1
    labels: {}
    annotations: {}
    podSecurityContext: {}
    securityContext: {}
    resources:
      limits:
        cpu: 1000m
        memory: 1Gi
      requests:
        cpu: 200m
        memory: 500Mi
    
    # Add extra environment variables for gateway
    extraEnv:
      - name: NODE_EXTRA_CA_CERTS
        value: "/etc/ssl/certs/custom/ca-cert.pem"
    
    # Add volume mounts for gateway
    volumeMounts:
      - name: custom-ca-cert
        mountPath: /etc/ssl/certs/custom
        readOnly: true
    
    # Add volumes for gateway
    volumes:
      - name: custom-ca-cert
        configMap:
          name: custom-ca-cert
    
    # ... rest of your gateway configuration ...

dataservice:
  name: "dataservice"
  enabled: true
  containerPort: 8081
  finetuneBucket: ""
  logexportsBucket: ""
  deployment:
    autoRestart: true
    replicas: 1
    labels: {}
    annotations: {}
    podSecurityContext: {}
    securityContext: {}
    
    # Add extra environment variables for dataservice
    extraEnv:
      - name: NODE_EXTRA_CA_CERTS
        value: "/etc/ssl/certs/custom/ca-cert.pem"
    
    # Add volume mounts for dataservice
    volumeMounts:
      - name: custom-ca-cert
        mountPath: /etc/ssl/certs/custom
        readOnly: true
    
    # Add volumes for dataservice
    volumes:
      - name: custom-ca-cert
        configMap:
          name: custom-ca-cert
    
    # ... rest of your dataservice configuration ...
```

### 3. Apply the updated values.yaml:
```bash
helm upgrade portkey-app ./charts/portkey-app \
  -n portkey \
  -f your-values.yaml
```

## Solution 2: Disable SSL Verification (Quick Fix - NOT Recommended)
⚠️ Warning: This is insecure and should only be used for testing.

Update the below config in values.yaml

```yaml
backend:
  deployment:
    extraEnv:
      - name: NODE_TLS_REJECT_UNAUTHORIZED
        value: "0"
    # ... rest of your backend configuration ...

gateway:
 deployment:
    extraEnv:
      - name: NODE_TLS_REJECT_UNAUTHORIZED
        value: "0"
    # ... rest of your gateway configuration ...

dataservice:
 deployment:
    extraEnv:
      - name: NODE_TLS_REJECT_UNAUTHORIZED
        value: "0"
     # ... rest of your dataservice configuration ...
```