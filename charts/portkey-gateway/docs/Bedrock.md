# AWS Bedrock Assumed Role Configuration

This document provides a simplified guide for configuring AWS assumed roles to access Amazon Bedrock services with Portkey Gateway.

## Overview

To use Amazon Bedrock with Portkey Gateway, you need to configure AWS assumed roles with the appropriate permissions. This allows the gateway to authenticate with AWS and invoke Bedrock models on your behalf.

Alternatively you can use an access token and secret key id, but using assumed roles is a more secure and recommended way to interact with Bedrock.

## Step 1: Create Bedrock IAM Policy

Create an IAM policy with the necessary Bedrock permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": "*"
    }
  ]
}
```

**Note:** You can make the `Resource` field more granular by specifying specific model ARNs instead of using `"*"`.

## Step 2: Role Configuration Options

You have two options for attaching the policy:

### Option A: Attach to Principal Role
Attach the Bedrock policy directly to your existing principal role (the role used for log storage).

### Option B: Create Separate Bedrock Role
Create a dedicated role for Bedrock access with the following trust relationship:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "<Bedrock Role ARN>"
        ]
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "<External ID>"
        }
      }
    }
  ]
}
```

## Step 3: Authentication Method Configuration

Choose one of the following authentication methods:

### Method 1: Long-term Credentials
Add the following environment variables to your `values.yaml`:

```yaml
environment:
  data:
    AWS_ASSUME_ROLE_ACCESS_KEY_ID: <your-access-key>
    AWS_ASSUME_ROLE_SECRET_ACCESS_KEY: <your-secret-key>
    AWS_ASSUME_ROLE_REGION: <your-region>
```

### Method 2: IRSA (IAM Roles for Service Accounts) for EKS
- Use the role attached to your EKS service account as the principal role
- No additional environment variables needed for authentication

### Method 3: IMDS (Instance Metadata Service) for EC2
- Use the role attached to your EC2 instance as the principal role
- No additional environment variables needed for authentication

## Step 4: Virtual Key Creation

When creating Virtual Keys in Portkey, provide:

- **Bedrock AWS Role ARN**: The ARN of the role with Bedrock permissions (Principal or Separate role)
- **Bedrock AWS External ID**: (Optional) The external ID for additional security
- **Bedrock AWS Region**: The AWS region where your Bedrock models are available
![alt text](../resources/bedrock.png)

## Important Notes

- Ensure the role ARN used in Virtual Key creation matches the role with Bedrock policy attached
- External ID is optional but recommended for enhanced security
- The principal role must have appropriate trust relationships configured
- Test the configuration with a simple Bedrock model invocation before production use

## Troubleshooting

If you encounter authentication issues:

1. Verify the trust relationship is correctly configured
2. Ensure the Bedrock policy is attached to the correct role
3. Check that the role ARN in Virtual Keys matches your configuration
4. Validate that the AWS region supports your chosen Bedrock models