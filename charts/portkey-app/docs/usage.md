# Portkey Usage Guide

This guide will help you get started with using Portkey after installation. There are two main components you'll be interacting with:

1. Portkey UI
2. Portkey AI Gateway

## 1. Portkey UI

The Portkey UI provides a web interface for managing your AI operations, viewing analytics, and configuring settings.

**Access:**
- URL: `http://<External-IP>`
- Port: 80

Replace `<External-IP>` with the IP address of your Portkey frontend service.

To find your Frontend IP, run the following command:

```bash
kubectl get services -n portkey
```

Look for the EXTERNAL-IP of the `portkey-frontend` service.

### Obtaining an API Key

To make API calls to the Portkey AI Gateway, you'll need an API key. Here's how to get one:

1. Log in to the Portkey UI at `http://<External-IP>`.
2. Navigate to the "API Keys" section in the UI.
3. You can either:
   - Select an existing API key if available, or
   - Create a new API key by clicking "Create New API Key"
4. If creating a new key, you'll be prompted to set the required permissions for the key.
5. Once created or selected, copy the API key. Make sure to store it securely.

## 2. Portkey AI Gateway

The Portkey AI Gateway is the API endpoint you'll use to make calls to AI models through Portkey.

**Base URL:** `http://<External-IP>:8787/v1`

Replace `<External-IP>` with the same IP address used for the Portkey UI.

### Making API Calls

Here are examples of how to make API calls to the Portkey AI Gateway using different methods:

#### cURL

```bash
curl http://<External-IP>:8787/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "x-portkey-api-key: $PORTKEY_API_KEY" \
  -H "x-portkey-provider: openai" \ 
  -d '{
    "model": "gpt-4-turbo",
    "messages": [{
        "role": "system",
        "content": "You are a helpful assistant."
      },{
        "role": "user",
        "content": "Hello!"
      }]
  }'
```


## Further Documentation

For detailed information on integrating with various providers and using advanced features, please refer to our comprehensive documentation at [docs.portkey.ai](https://docs.portkey.ai).

This documentation includes:
- Supported AI model providers
- Advanced configuration options
- Prompt management techniques
- Analytics and monitoring features
- User and access management
- Troubleshooting guides

If you encounter any issues or have questions, please contact our support team at support@portkey.ai.

Next: [Best Practices](./best-practices.md)