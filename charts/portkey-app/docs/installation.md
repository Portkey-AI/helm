
## Installation Guide

This guide will walk you through the process of deploying Portkey to your Kubernetes cluster. We'll cover the prerequisites, installation steps, and post-installation verification.

### Prerequisites

1. A Kubernetes cluster (we recommend using a dedicated namespace for Portkey)
2. Helm 3.x installed on your local machine
3. `kubectl` configured to communicate with your cluster

### Step 1: Prepare Your Kubernetes Environment

First, ensure you have access to your Kubernetes cluster:

```bash
kubectl get nodes
```

If this command returns a list of nodes, you're good to go. If not, check your Kubernetes configuration.

### Step 2: Add the Portkey Helm Repository

Unless you're using local charts, add the Portkey Helm repository:

```bash
helm repo add portkey https://portkey-ai.github.io/helm/
helm repo update
```

### Step 3: Install Portkey

Now, let's deploy Portkey using Helm:

```bash
helm install portkey portkey/portkey \
  --values portkey_config.yaml \
  --namespace <your-namespace> \
  --create-namespace \
  --version <version> \
  --wait
```

Replace `<your-namespace>` with your desired namespace and `<version>` with the Portkey version you want to deploy.

This command will:
- Create the specified namespace if it doesn't exist
- Install Portkey with the configurations from `portkey_config.yaml`
- Wait for all resources to be ready before completing

### Step 4: Verify the Deployment

After installation, verify that all Portkey components are running:

```bash
kubectl get pods -n <your-namespace>
```

You should see pods for components like backend, frontend, gateway, and databases (MySQL, Redis, ClickHouse) in a "Running" state.

### Step 5: Access Portkey Services

To access Portkey services:

1. List the services:
   ```bash
   kubectl get services -n <your-namespace>
   ```

2. Note the EXTERNAL-IP for the `portkey-frontend` service. This is your entry point to the Portkey UI.

3. Check the health of the backend:
   ```bash
   curl http://<EXTERNAL-IP>/api/health
   ```
   You should receive a response indicating the service is healthy.

4. Open a web browser and navigate to `http://<EXTERNAL-IP>` to access the Portkey dashboard.

### Troubleshooting

If you encounter issues:

1. Check pod status:
   ```bash
   kubectl describe pods -n <your-namespace>
   ```

2. View logs for a specific pod:
   ```bash
   kubectl logs <pod-name> -n <your-namespace>
   ```

3. Ensure all config values in `portkey_config.yaml` are correct for your environment.

For persistent issues, please contact our support team or consult the Portkey documentation for more advanced troubleshooting steps.