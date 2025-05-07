## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started.

## Setup
Update the following details in `values.yaml`
1. Use Docker token details shared
```
imageCredentials:
- name: portkeyenterpriseregistrycredentials
  create: true
  registry: https://index.docker.io/v1/
  username: <docker-user>
  password: <docker-pwd>
```

2. Use the Env parameters shared

``` yaml
environment:
  ...
  data:
    SERVICE_NAME: 
    LOG_STORE: 
    MONGO_DB_CONNECTION_URL:
    MONGO_DATABASE: 
    MONGO_COLLECTION_NAME:
    MONGO_GENERATION_HOOKS_COLLECTION_NAME:
    LOG_STORE_REGION: 
    LOG_STORE_ACCESS_KEY: 
    LOG_STORE_SECRET_KEY: 
    LOG_STORE_GENERATIONS_BUCKET: 
    LOG_STORE_BASEPATH: 
    LOG_STORE_AWS_ROLE_ARN:
    LOG_STORE_AWS_EXTERNAL_ID:
    AWS_ASSUME_ROLE_ACCESS_KEY_ID:
    AWS_ASSUME_ROLE_SECRET_ACCESS_KEY:
    AWS_ASSUME_ROLE_REGION:
    AWS_IMDS_V1:
    AZURE_AUTH_MODE: 
    AZURE_MANAGED_CLIENT_ID: 
    AZURE_STORAGE_ACCOUNT: 
    AZURE_STORAGE_KEY: 
    AZURE_STORAGE_CONTAINER:
    AZURE_ENTRA_CLIENT_ID:
    AZURE_ENTRA_CLIENT_SECRET:
    AZURE_ENTRA_TENANT_ID:
    ANALYTICS_STORE: 
    ANALYTICS_STORE_ENDPOINT: 
    ANALYTICS_STORE_USER: 
    ANALYTICS_STORE_PASSWORD: 
    ANALYTICS_LOG_TABLE: 
    ANALYTICS_FEEDBACK_TABLE:
    ANALYTICS_GENERATION_HOOKS_TABLE:
    CACHE_STORE: 
    REDIS_URL: 
    REDIS_TLS_ENABLED: 
    REDIS_MODE: 
    PORTKEY_CLIENT_AUTH: 
    ORGANISATIONS_TO_SYNC:
```
### Analytics Store

Supported `ANALYTICS_STORE` is `clickhouse` or `control_plane` .

If `ANALYTICS_STORE` is `control_plane`, no additional details are needed.

If `ANALYTICS_STORE` is `clickhouse`, the following values are needed for storing analytics data.

``` yaml
  ANALYTICS_STORE_ENDPOINT: 
  ANALYTICS_STORE_USER: 
  ANALYTICS_STORE_PASSWORD: 
  ANALYTICS_LOG_TABLE:
  ANALYTICS_FEEDBACK_TABLE:
  ANALYTICS_GENERATION_HOOKS_TABLE:
```

Portkey also supports pushing your analytics data to an OTEL compatible endpoint,
the following values are needed for pushing to OTEL
```yaml
  OTEL_PUSH_ENABLED: true
  OTEL_ENDPOINT: http://localhost:4318
```
Additionally you can configure arbitrary resource attributes of the otel logs by setting a comma separated value for `OTEL_RESOURCE_ATTRIBUTES` like `ApplicationShortName=gateway,AssetId=12323,deployment.service=production`

### Log Storage

`LOG_STORE` can be `mongo`, `s3`, `s3_assume`, `wasabi`, `gcs`, `azure`, or `netapp`.

**1. Mongo**

- If you want to use Mongo or Document DB for storage, `LOG_STORE` will be `mongo`. 
- The following values are mandatory
  ```
    MONGO_DB_CONNECTION_URL: 
    MONGO_DATABASE: 
    MONGO_COLLECTION_NAME:
    MONGO_GENERATION_HOOKS_COLLECTION_NAME
  ```
- If you are using pem file for authentication, you need to follow the below additional steps
  - In `resources-config.yaml` file supply pem file details under data(for example, document_db.pem) along with its content.
  - In `values.yaml` use the below config
    ``` yaml
    volumes:
    - name: shared-folder
      configMap:
        name: resource-config
    volumeMounts:
    - name: shared-folder
      mountPath: /etc/shared/<shared_pem>
      subPath: <shared_pem>
    ```
  - The `MONGO_DB_CONNECTION_URL` should use /etc/shared<shared_pem> in tlsCAFile param. For example, `mongodb://<user>:<password>@<host>?tls=true&tlsCAFile=/etc/shared/document_db.pem&retryWrites=false`

**2. AWS S3 Compatible Blob storage**

- Portkey supports following S3 compatible Blob storages 
  - AWS S3
  - Google Cloud Storage
  - Wasabi
  - Netapp (s3 compliant APIs)

- The above mentioned S3 Compatible document storages are interopable with S3 API. 
- The following values are mandatory
  ``` yaml
    LOG_STORE_REGION: 
    LOG_STORE_GENERATIONS_BUCKET:
    LOG_STORE_ACCESS_KEY: 
    LOG_STORE_SECRET_KEY: 
  ```
- You need to  generate `Access Key` and `Secret Key` from the respective providers as mentioned below.

**2.1. AWS S3**
- `LOG_STORE` will be `s3`.
- Access Key can be generated as mentioned here
  - https://aws.amazon.com/blogs/security/wheres-my-secret-access-key
  - Security Credentials -> Access Keys -> Create Access Keys

**2.2. Google Cloud Storage**
- `LOG_STORE` will be `gcs`.
- Only s3 interopable way of gcs is supported currently. 
- Access Key can be generated as mentioned here - 
  - https://cloud.google.com/storage/docs/interoperability
  - https://cloud.google.com/storage/docs/authentication/hmackeys
- Cloud Storage -> Settings -> Interopability -> Access keys for service accounts -> Create Key for Service Accounts

**2.3. Wasabi**
- `LOG_STORE` will be `wasabi`.
- Access Key can be generated from
  - Access Keys ->  Create Access Key

**2.4. Netapp**
- `LOG_STORE` will be `netapp`. 
- Additional param `LOG_STORE_BASEPATH` is needed
- The following values are mandatory
``` yaml
  LOG_STORE_REGION:
  LOG_STORE_ACCESS_KEY:
  LOG_STORE_SECRET_KEY:
  LOG_STORE_BASEPATH:
```

**2.5. S3 Assumed Role**

- If you want to use s3 using Assumed Role Authentication, `LOG_STORE` will be `s3_assume`. 

**Method 1(requires Long Term Credentials)** 

- The following values are mandatory

  ``` yaml
    LOG_STORE_REGION:
    LOG_STORE_GENERATIONS_BUCKET:
    LOG_STORE_ACCESS_KEY:
    LOG_STORE_SECRET_KEY:
    LOG_STORE_AWS_ROLE_ARN:
    LOG_STORE_AWS_EXTERNAL_ID:
  ```

- `LOG_STORE_ACCESS_KEY`,`LOG_STORE_SECRET_KEY` will be supplied by Portkey. Rest needs to be provisioned and supplied.

- `LOG_STORE_AWS_ROLE_ARN` and `LOG_STORE_AWS_EXTERNAL_ID` need to be enabled by following the below steps

  1. Go to the IAM console in the AWS Management Console.
  2. Click "Roles" in the left sidebar, then "Create role".
  3. Choose "Another AWS account" as the trusted entity.
  4. Enter the Account ID of the Portkey Aws Account Id (which will be shared).
  5. Select "Require external Id" for added security.
  6. Attach the necessary permissions: 
      ```json
      {
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Effect": "Allow",
                  "Action": [
                      "s3:GetObject",
                      "s3:PutObject"
                  ],
                  "Resource": [
                      "arn:aws:s3:::<bucket>",
                      "arn:aws:s3:::<bucket>/*"
                  ]
              }
          ]
      }
      ```
  7. Name the role (e.g., "S3AssumedRolePortkey") and create it.
  8. After creating the role, select it and go to the "Trust relationships" tab.
  9. Edit the trust relationship and ensure it looks similar to this:
      ``` json
      {
        "Version": "2012-10-17",
        "Statement": [
          {
            "Effect": "Allow",
            "Principal": {
              "AWS": "<arn_shared_by_portkey>"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
              "StringEquals": {
                "sts:ExternalId":"<LOG_STORE_AWS_EXTERNAL_ID>"
              }
            }
          }
        ]
      }
      ```
- `LOG_STORE_AWS_ROLE_ARN` will be the same as arn for the above role.

**Method 2 (Using IRSA for EKS)**
- The following values are mandatory
  ``` yaml
  LOG_STORE_REGION:
  LOG_STORE_GENERATIONS_BUCKET:
  ```
- Enable IAM OIDC Provider in EKS
  - Check if an OIDC provider is already associated with your EKS cluster

    ``` bash
    aws eks describe-cluster --name <cluster-name> --query "cluster.identity.oidc.issuer" --output text
    ```

  - If an OIDC provider is not attached, associate one:
    ``` bash
    aws eks --region <region> update-cluster-config --name <cluster-name> --identity-oidc-issuer <oidc-issuer-url>
    ```

- Create an IAM Role for Service Accounts
  - Define a trust policy for the role to allow the EKS OIDC provider to
  assume the role. Use the OIDC issuer URL from the previous step and specify your namespace and service account name in the `StringLike`
  condition:

    ```json
    {
      "Version": "2012-10-17",
      "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Federated": "arn:aws:iam::<account-id>:oidc-provider/<oidc-provider-url>"
        },
        "Action": "sts:AssumeRoleWithWebIdentity",
        "Condition": {
          "StringLike": {
            "<oidc-provider-url>:sub": "system:serviceaccount:<namespace>:*"
          }
        }
      }
      ]
    }
    ```

  - Create the IAM role using the above trust policy:
    ``` bash
    aws iam create-role --role-name <ROLE_NAME> --assume-role-policy-document file://custom-policy.json
    ```
  - Example custom-policy.json 
    - for S3 (configuring blob storage)
      ``` json
      {
        "Version": "2012-10-17",
        "Statement": [
              {
                "Effect": "Allow",
                "Action": [
                    "s3:GetObject",
                    "s3:PutObject"
                ],
                "Resource": [
                    "arn:aws:s3:::<bucket>",
                    "arn:aws:s3:::<bucket>/*"
                ]
              }
        ]
      }
      ```

**Method 3 (Using IMDS for ECS)**
- The following values are mandatory
  ``` yaml
  LOG_STORE_REGION:
  LOG_STORE_GENERATIONS_BUCKET:
  ```
- If using IMDS V1 `AWS_IMDS_V1` must be set to `true`. For IMDS V2 this can be ignored
- Create Custom IAM Role
  ``` bash
    aws iam create-role --role-name <ROLE_NAME> \
      --assume-role-policy-document '{
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Effect": "Allow",
                  "Principal": {
                      "Service": "ec2.amazonaws.com"
                  },
                  "Action": "sts:AssumeRole"
              }
          ]
      }'
  ```
- Create a custom policy
  ``` bash
  aws iam create-policy --policy-name <POLICY_NAME> --policy-document file://custom-policy.json
  ```
  - Example custom-policy.json 
    - for S3 (configuring blob storage)
      ``` json
      {
        "Version": "2012-10-17",
        "Statement": [
              {
                "Effect": "Allow",
                "Action": [
                    "s3:GetObject",
                    "s3:PutObject"
                ],
                "Resource": [
                    "arn:aws:s3:::<bucket>",
                    "arn:aws:s3:::<bucket>/*"
                ]
              }
        ]
      }
      ```
- Attach policy to the the  role
  ``` bash
  aws iam attach-role-policy --role-name <ROLE_NAME> \
      --policy-arn arn:aws:iam::aws:policy/<POLICY_NAME>
  ```
- Attach the role to Instance or Auto Scaling launch template
  - Attach to instance
    - Create an instance profile
      ``` bash
      aws iam create-instance-profile --instance-profile-name "<INSTANCE_PROFILE_NAME>" >
      ```
    - Add the role to the instance profile
      ``` bash
      aws iam add-role-to-instance-profile --instance-profile-name "<INSTANCE_PROFILE_NAME>" --role-name "<ROLE_NAME>"
      ```
    - Associate the instance profile with the EC2 instance
      ``` bash
      aws ec2 associate-iam-instance-profile --instance-id "<INSTANCE_ID>" --iam-instance-profile Name="<INSTANCE_PROFILE_NAME>"
      ```
  - Attach to Auto Scaling launch template
    - Create a Launch Template with the IAM Role
      ``` bash
        aws ec2 create-launch-template --launch-template-name LAUNCH_TEMPLATE_NAME \
      --version-description "With IAM Role" \
      --launch-template-data '{
          "ImageId": "<AMI_ID>",  # Replace with your AMI ID
          "InstanceType": "<Instance Type>",
          "IamInstanceProfile": {
              "Name": "<ROLE_NAME>"
          },
          "KeyName": "<KEY_PAIR>"  # Replace with your key pair name
      }'
      ```
    -  Associate the Launch Template with the Auto Scaling Group
        ``` bash
          aws autoscaling create-auto-scaling-group --auto-scaling-group-name AUTO_SCALING_GROUP_NAME \
        --launch-template "LaunchTemplateName=<LAUNCH_TEMPLATE_NAME>,Version=1" \
        --min-size 1 --max-size 5 --desired-capacity 2 \
        --vpc-zone-identifier "subnet-abc12345"  # Replace with your subnet ID
        ```
**2.6. Azure Blob Storage**
- If you want to use Azure blob storage, `LOG_STORE` will be `azure`. 
  The following values are mandatory
  ``` yaml
    AZURE_STORAGE_ACCOUNT: 
    AZURE_STORAGE_CONTAINER: 
  ```

- **Managed Identity**
  
  If using Managed Identity, `AZURE_AUTH_MODE` must be set to `managed`.
  
  If using multiple User Managed Identities, `AZURE_MANAGED_CLIENT_ID` must be set.

- **Entra Identity**

  If Using Azure Entra Identity, `AZURE_AUTH_MODE` must be set to `entra`.
  
  The Following keys will be needed
  ``` yaml
    AZURE_ENTRA_CLIENT_ID:
    AZURE_ENTRA_CLIENT_SECRET:
    AZURE_ENTRA_TENANT_ID:
  ```

- P.s: If not using `Managed` or `Entra` Identity, **`AZURE_STORAGE_KEY`** will be mandatory

### Aws Assumed Role (for Bedrock)

- Create policy for Bedrock
  ```json
      {
        "Version": "2012-10-17", "Statement": [
        {
          "Effect": "Allow", 
          "Action": [
            "bedrock:InvokeModel", 
            "bedrock:InvokeModelWithResponseStream"
          ],
          "Resource": "*" // can be more granular 
        }
        ]
      }
  ```
- You can attach the policy to the Principal Role or create a Separate Role. 
- If you create a Separate role, make sure to allow assumed Role access to the Principal Role. You can use the below trust relationship for the Separate Role. 
    ```json
    {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": [
                    "<Principal Role Arn>"
                ]
            },
            "Action": "sts:AssumeRole",
            "Condition": { // optional
                "StringEquals": {
                    "sts:ExternalId": "<External Id>" 
                }
            }
        }
    ]
    }
    ```
- If you wish to follow `method 1` as mentioned in step #2.5.
  - Following keys are mandatory.
    ``` yaml
      AWS_ASSUME_ROLE_ACCESS_KEY_ID:
      AWS_ASSUME_ROLE_SECRET_ACCESS_KEY:
      AWS_ASSUME_ROLE_REGION:
    ```
  - `LOG_STORE_AWS_ROLE_ARN` will be the Principal Role here
- If you wish to follow IRSA or IMDS as mentioned in `method 2` and `method 3`, the above created role attached to EKS or EC2 (i.e.,<ROLE_NAME>) will be the principal Role
- While creating Virtual Keys, make sure to use the same role ARN as the role for which the Bedrock policy is attached (Principal or Separate)
  - Following keys are needed for Virtual Key Creation
    - Bedrock AWS Role ARN
    - Bedrock AWS External Id (optional)
    - Bedrock AWS Region
    ![alt text](resources/bedrock.png)

### Cache Store
- There are three possible ways to configure Redis. Set `CACHE_STORE` as one of the below
  - `redis`: Deploys Redis in the cluster
  - `aws-elastic-cache`: Use AWS managed ElastiCache
  - `custom`: Use any other Redis compatible setup
- Set `CACHE_STORE` to match your chosen cache solution.

  Note: 
  - `REDIS_URL` defaults to `redis://redis:6379`
  - `REDIS_TLS_ENABLED` defaults to `false`
  - `TLS mode` is only supported with `aws-elastic-cache`
  - If you are using Redis in cluster mode, set `REDIS_MODE` to `cluster` in values. If not, this can be left blank.

- The following values are mandatory

  ``` yaml
    REDIS_URL: 
    REDIS_TLS_ENABLED: 
  ```

### Sync

The following are mandatory

``` yaml
  PORTKEY_CLIENT_AUTH:
  ORGANISATIONS_TO_SYNC:
```

## Installation
If this command returns a list of nodes, you're good to go. If not, check your Kubernetes configuration.

1. Add the helm repo 
   ```bash
   helm repo add portkey-ai https://portkey-ai.github.io/helm
   ```

2. Update the helm repo 
   ```bash
   helm repo update
   ```

3. Install the chart 
   ```bash
   helm upgrade --install portkey-ai portkey-ai/gateway -f ./chart/values.yaml -n portkeyai --create-namespace
   ```

4. Check the deployment 
   ```bash
   kubectl get pods -n portkeyai
   ```

## Uninsatallation
- Uninstall the chart:
  ``` bash
  helm uninstall portkey-gateway --namespace portkeyai 
  ```

## Port Tunnel
Optional tunneling port (for local testing)
  ``` bash
    kubectl port-forward <kubectl-pod> -n portkeyai 8787:8787
  ```

# Data Service
To enable data service, please update `dataservice`>`enabled` to `true`

Please note that we use same `LOG_STORE` as the one for gateway. Other Log Store Details are same as Gateway. 

The following keys are mandatory
``` yaml
FINETUNES_BUCKET:
FINETUNES_AWS_ROLE_ARN:
```

## Finetunes
For more details on finetune, referer to [DataService](DataService.md)
### P.s: Currently only S3 as data store is supported for finetuning.
