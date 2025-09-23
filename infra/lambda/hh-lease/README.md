hh-lease Lambda

This Lambda provides a minimal /lease endpoint that accepts an X-Download-Token header, looks up a HubSpot contact with property `download_token`, and returns GHCR credentials in Docker's expected JSON format.

Deployment (create or update)

1. Zip and upload code (this example creates the function if it doesn't exist):

```bash
cd infra/lambda/hh-lease
zip -r ../../hh-lease-deploy.zip .

# create (first time)
aws lambda create-function --function-name hh-lease \
  --runtime nodejs20.x --role arn:aws:iam::972067303195:role/hh-lambda-exec \
  --handler index.handler --zip-file fileb://../../hh-lease-deploy.zip \
  --profile hh-deployer --region us-west-2

# or update
aws lambda update-function-code --function-name hh-lease --zip-file fileb://../../hh-lease-deploy.zip --profile hh-deployer --region us-west-2
```

2. Set environment variables (HS_TOKEN, GHCR_USER, GHCR_PAT) as described in your plan.

3. Integrate with the existing API Gateway (replace <api-id> with the API id created earlier):

```bash
API_ID=pc4x1xgehc
REGION=us-west-2

# create integration
INTEGRATION_ID=$(aws apigatewayv2 create-integration --api-id "$API_ID" --integration-type AWS_PROXY --integration-uri "arn:aws:apigateway:$REGION:lambda:path/2015-03-31/functions/$(aws lambda get-function --function-name hh-lease --profile hh-deployer --region $REGION --query 'Configuration.FunctionArn' --output text)/invocations" --profile hh-deployer --region $REGION --query 'IntegrationId' --output text)

# create route
aws apigatewayv2 create-route --api-id "$API_ID" --route-key "POST /lease" --target "integrations/$INTEGRATION_ID" --profile hh-deployer --region $REGION

# deploy
aws apigatewayv2 create-deployment --api-id "$API_ID" --profile hh-deployer --region $REGION
```

4. Add Lambda permission for the API:

```bash
aws lambda add-permission --function-name hh-lease --statement-id hh-lease-invoke --action lambda:InvokeFunction --principal apigateway.amazonaws.com --source-arn arn:aws:execute-api:$REGION:972067303195:$API_ID/*/POST/lease --profile hh-deployer --region $REGION
```
