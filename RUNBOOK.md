# RUNBOOK

## Mint a token (manual)

If you want to mint a token for a contact, either set the contact's Download Requested property to true in HubSpot, or use the simulator:

node scripts/simulate-hs-webhook.js --url "https://pc4x1xgehc.execute-api.us-west-2.amazonaws.com/webhook" --secret "<HS_APP_SECRET>" --contact <CONTACT_ID>

Watch logs:

aws logs tail /aws/lambda/hh-webhook --follow

Look for `minted_token <contactId> <token>` in CloudWatch.

## Revoke/disable a token

Set the contact property `download_enabled` to false. The `/lease` endpoint will then return 403 and CloudWatch will show `lease_denied reason=disabled contactId=<id>`.

## Rotate GHCR PAT

Update the `GHCR_PAT` environment variable on the `hh-lease` Lambda and redeploy.

## Where to check

- Projects → Webhooks monitor in HubSpot
- CloudWatch logs: `/aws/lambda/hh-webhook` and `/aws/lambda/hh-lease`
- WAF metrics in CloudWatch

## Installer

Use the Releases URL to bootstrap:

curl -fsSL https://github.com/afewell-hh/hh/releases/latest/download/install-hh.sh | bash

*** End Patch