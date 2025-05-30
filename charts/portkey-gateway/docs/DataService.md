# Overview:
Currently finetuning is fully supported API communication only vs partial support via UI.

## Architecture:

![](https://lh7-rt.googleusercontent.com/docsz/AD_4nXffbhrnjyEjpmgafZtZ2qZVM55G6yCRB8FHf5BbbJAa-XTM4km6mfip2OnpZ5Ts-373avnjqMONLhaJOuQpDL-3pAPx7viYRrq1W-KJicd_OIu_0tJ1aDXAnPo_NjL6h7Jd0CuhmTqMcWKOE_FoGoYzsROg?key=GSWy0RPh6CRcV4iKuzA0zQ)

The above document describes the architecture of a hydrid data service system. 

The gateway acts as an intermediary between control plane and deployed data service, providing a streamlined and secure method of communication.
- The data service is only accessible from within the cluster via gateway only.
- Gateway exposes following endpoints
    1. v1/datasets 
    2. v1/fine-tuning/jobs
    3. v1/dataservice/datasets 
    4. v1/dataservice/finetune

    Note: 
    - `v1/datasets` & `v1/fine-tuning/jobs` are exposed via API with at least `completions.write` scope.
    - `v1/dataservice/datasets` and `v1/dataservice/finetune` are used internally by the Control Plane for communication with the data service via gateway.

## Fine-tuning Process
To start a fine-tune job, follow these steps:

1. Create a Dataset
2. Upload File to S3 (optional if file is already in S3)
3. Update the dataset with the uploaded S3 Key
4. Start Finetune
5. Cancel Finetune (if Needed)

> When you create a `dataset` , API will return a S3 Signed URL to upload file to S3. We can use that link to push the file to into S3 before starting the finetune.

Example cURL for each step as follows:
### Create Dataset
#### cURL:

```bash
curl --request POST \
  --url <deployed_url>/v1/datasets \
  --header 'content-type: application/json' \
  --header 'x-portkey-api-key: <api_key>' \
  --data '{
  "name": "{{filename}}",
  "provider": "string", #ex `openai`, `bedrock` or `anyscale`
  "purpose": "fine-tune"
}'
```

> Make sure to update the `{{filename}}` variable in the request body with the filename of dataset.

#### Response
```json
{
	"success": true,
	"data": {
		"id": "string",
		"signed_url": "string"
	}
}
```

### Update dataset

#### cURL:
```bash
curl --request PUT \
  --url <deployed_url>/v1/datasets/:dataset_id \
  --header 'content-type: application/json' \
  --header 'x-portkey-api-key: <api_key>' \
  --data '{
  "filename": "filename.jsonl" 
}'
```

This will update the dataset details with the path of S3 file i.e Key of S3.

#### Response
```json
{
	"success": true,
	"data": {}
}
```

### Create a Finetune
Create a finetune

#### cURL:
```bash
curl --request POST \
  --url <deployed_url>/v1/fine-tuning/jobs \
  --header 'content-type: application/json' \
  --header 'x-portkey-api-key: <api_key>' \
  --data '{
	  "training_file":"{{datasetId}}",
	  "validation_file": "{{validationDatasetId}}", # optional
	  "model":"{{model}}",
	  "provider":"{{provider}}", # bedrock, open-ai
	  "suffix":"test-cohere-bed", # Name for finetune model
	  "hyperparameters": {
	    "n_epochs":1 # Epoch count.
	  },
	  "model_type":"text", # Model type training (or dataset), supported are `text` and `chat`.
	  "description":"Test bedrock spec finetune with bedrock",
	  "virtual_key":"{{virtualKey}}", # Virtual key associated with the provider
	  "override_params": {
	    "model":"cohere.command-light-text-v14:7:4k" # Parameters to override when sending to the provider.
	  }
}
'
```

#### Response
```json
{
	"success": true,
	"data": {
		"id": "string"
	}
}
```

Currently `override_params` support 3 keys i.e `model` , `model_type` and `template`. 

- `model` is being used with `bedrock` as bedrock expects a different model `modelId` for finetune than for inference. 
- `model_type` and `template` are being used for `fireworks` these parameters are being used for differentiating the dataset values for finetune job. More on this [Here](https://docs.fireworks.ai/fine-tuning/fine-tuning-models#preparing-your-dataset)


> For bedrock related `modelId` list, you can hit the `foundation-models` [endpoint](https://bedrock.us-east-1.amazonaws.com/foundation-models) to see the list of models supported for finetuning.

The above API call will automatically starts a dataset validation job and then continues finetune progress with provider if everything seems good with dataset and it's structure.

The finetuning service comes equipped with transformers that seamlessly convert OpenAI-formatted datasets into formats required by different providers. 
- Consider Bedrock as an example - although its finetuning capabilities are centered around text-to-text models, we accept chat-formatted datasets as well. 

- Through our transformation pipeline, we ensure your data aligns perfectly with Provider's specifications. 

- This approach enables us to use one consistent dataset format that works across our supported providers.

- To ensure proper transformation, always specify the `model_type` parameter. This tells our system how to process your dataset appropriately. 
For instance, when finetuning a Bedrock chat model, set `model_type` to `chat`. Similarly, use `text` when working with text-based models.


### Cancel finetune
If you want to cancel a finetune, you can do so by using the following `cURL`.

#### cURL:

```bash
curl --request POST \
  --url <deployed_url>/v1/fine-tuning/jobs/:finetuneId \
  --header 'content-type: application/json' \
  --header 'x-portkey-api-key: <api_key>' \
```

#### Response
```json
{
	"success": true
}
```

### Fetch a finetune
We can verify the status of a finetune job either from Frontend or via Request.

#### cURL:
```bash
curl --request GET \
  --url <deployed_url>/v1/fine-tuning/jobs/:finetuneId \
  --header 'x-portkey-api-key: <api_key>'
```

#### Response
```
{
  "success": true,
  "data": {
    "id": "<id>",
    "name": "test-cohere-bed",
    "description": "Test bedrock spec finetune with bedrock",
    "slug": "ft:amazon.titan-text-lite-v1:test-cohere-bed-c10a3",
    "organisationId": "<id>",
    "organisationProviderApiKeyId": "<id>",
    "ownerId": "<id>",
    "aiModelId": "<id>",
    "status": "provider_finetune_in_progress",
    "createdAt": "2024-11-26T13:36:20.000Z",
    "lastUpdatedAt": "2024-11-26T13:36:21.000Z",
    "trainingDatasetId": "<id>",
    "validationDatasetId": null,
    "hyperparameters": {
      "epochs": 1
    },
    "providerFinetuneId": "<id>",
    "metadata": {
      "trainingUnits": 0,
      "trainingRecords": 0,
      "trainingRecordCost": null,
      "validationRecordCost": null
    },
    "providerFinetuneSlug": null,
    "aiModelVersion": "amazon.titan-text-lite-v1",
    "aiModelType": "text",
    "trainingDataset": {
      "id": "<id>",
      "name": "test-assume.jsonl",
      "description": "",
      "organisationId": "<id>",
      "createdBy": "<id>",
      "aiModelId": null,
      "s3Path": "test-assume.jsonl",
      "totalRecords": null,
      "totalUnits": null,
      "type": "fine-tune",
      "status": "active",
      "createdAt": "2024-11-26T13:24:14.000Z",
      "lastUpdatedAt": "2024-11-26T13:24:14.000Z",
      "filters": null,
      "providerFileId": "test-assume_transformed.jsonl",
      "fileSize": null
    },
    "validationDataset": null
  }
}
```