
## Installation Guide

This guide will walk you through the process of deploying Portkey to your Kubernetes cluster. We'll cover the prerequisites, installation steps, and post-installation verification.

### Prerequisites

1. A Kubernetes cluster (we recommend using a dedicated namespace for Portkey)
2. Helm 3.x installed on your local machine
3. `kubectl` configured to communicate with your cluster
4. A configured values.yaml file (see [Configuration Guide](./configuration.md))
5. A sample config file is provided [here](./sample-config.yaml)

### Prepare Your Kubernetes Environment

First, ensure you have access to your Kubernetes cluster:

```bash
kubectl get nodes
```

## Install Chart 
If this command returns a list of nodes, you're good to go. If not, check your Kubernetes configuration.

1. Add the helm repo 
   ```bash
   helm repo add portkey-ai https://portkeyai.github.io/portkey-app
   ```

2. Update the helm repo 
   ```bash
   helm repo update
   ```

3. Install the chart 
   ```bash
   helm upgrade --install portkey-ai portkey-ai/portkey-app -f ./chart/values.yaml -n portkeyai --create-namespace
   ```

4. Check the deployment 
   ```bash
   kubectl get pods -n portkeyai
   ```

This command will:
- Create the specified namespace if it doesn't exist
- Install Portkey with the configurations from `values.yaml`
- Wait for all resources to be ready before completing

You should see pods for components like backend, frontend, gateway, and databases (MySQL, Redis, ClickHouse) in a "Running" state.

## Access Portkey Services

To access Portkey services:

1. List the services:
   ```bash
   kubectl get services -n portkeyai
   ```

2. Note the EXTERNAL-IP for the `portkey-frontend` service. This is your entry point to the Portkey UI.

3. Check the health of the backend:
   ```bash
   curl http://<EXTERNAL-IP>/
   ```
   You should receive a response indicating the service is healthy.

4. Open a web browser and navigate to `http://<EXTERNAL-IP>` to access the Portkey dashboard.

### Troubleshooting

If you encounter issues:

1. Check pod status:
   ```bash
   kubectl describe pods -n portkeyai
   ```

2. View logs for a specific pod:
   ```bash
   kubectl logs <pod-name> -n portkeyai
   ```

3. Ensure all config values in `portkey_config.yaml` are correct for your environment.

For persistent issues, please contact our support team (support@portkey.ai) or consult the Portkey documentation.

NEXT: [Usage](./usage.md)
