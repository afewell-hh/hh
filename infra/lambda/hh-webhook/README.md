Lambda handler for receiving and verifying HubSpot webhooks (v3 signature)

Deployment

1. Zip the handler and upload to your Lambda (or use your CI/CD):

```bash
cd infra/lambda/hh-webhook
zip -r ../hh-webhook.zip index.js
aws lambda update-function-code --function-name hh-webhook --zip-file fileb://../hh-webhook.zip --profile hh-deployer --region us-west-2
```

2. Set the app secret as an environment variable (do not commit the secret):

```bash
AWS_PROFILE=hh-deployer AWS_REGION=us-west-2 \
  aws lambda update-function-configuration \
  --function-name hh-webhook \
  --environment "Variables={HS_APP_SECRET=PASTE_YOUR_APP_SECRET_HERE}" \
  --no-cli-pager

aws lambda wait function-updated-v2 --function-name hh-webhook --profile hh-deployer --region us-west-2
```

3. Tail logs to verify:

```bash
AWS_PROFILE=hh-deployer AWS_REGION=us-west-2 aws logs tail /aws/lambda/hh-webhook --follow
```
