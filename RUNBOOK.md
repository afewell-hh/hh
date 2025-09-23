# RUNBOOK

## Mint

To mint a token for a contact, toggle the `download_requested` property to `true` in HubSpot, or use the simulator:

```bash
node scripts/simulate-hs-webhook.js --url "https://pc4x1xgehc.execute-api.us-west-2.amazonaws.com/webhook" --secret "<HS_APP_SECRET>" --contact <CONTACT_ID>
```

Watch logs:
```bash
aws logs tail /aws/lambda/hh-webhook --follow
```

Look for `minted_token <contactId> <token>` in CloudWatch.

## Revoke

Set the contact property `download_enabled` to `false`. The `/lease` endpoint will return 403 and CloudWatch will show `lease_denied`.

## Rotate GHCR PAT

Update the `GHCR_PAT` environment variable on the `hh-lease` Lambda and redeploy:

```bash
aws lambda update-function-configuration --function-name hh-lease --environment Variables={GHCR_PAT=<NEW_PAT>}
```

## Rotate EDGE_SHARED_SECRET

Update the `EDGE_SHARED_SECRET` environment variable on the `hh-authz` Lambda:

```bash
NEW_SECRET="$(openssl rand -base64 32)"
aws lambda update-function-configuration --function-name hh-authz --environment Variables={EDGE_SHARED_SECRET=$NEW_SECRET}
aws lambda wait function-updated-v2 --function-name hh-authz
```

Update releases/installer with the new default value and instruct existing customers to:
- Re-run `hh login`, or
- Manually edit `~/.hh/config.json` to update the `edge_auth` field

## HTTP Response Codes

- **401**: Missing `X-Edge-Auth` header (authorizer)
- **403**: Invalid token or `download_enabled=false` (Lambda handler)
- **200**: Success
- **500**: Internal Lambda error
- **502**: HubSpot API error

## Support Operations

### Revoke a pairing code (auto-remint)

```bash
CONTACT_ID=156855158284
curl -sS -X PATCH "https://api.hubapi.com/crm/v3/objects/contacts/$CONTACT_ID" \
  -H "Authorization: Bearer $HS_TOKEN" -H "Content-Type: application/json" \
  -d '{"properties":{"download_token":"", "download_requested":"true"}}' >/dev/null
```

### Temporarily disable downloads (checkbox No)

```bash
curl -sS -X PATCH "https://api.hubapi.com/crm/v3/objects/contacts/$CONTACT_ID" \
  -H "Authorization: Bearer $HS_TOKEN" -H "Content-Type: application/json" \
  -d '{"properties":{"download_enabled":"false"}}' >/dev/null
```

### Verify a user report (HTTP/API OK)

Expect HTTP/2 200 and a lease_ok log.

- If 403 + invalid-token → wrong/expired code.
- If 403 + disabled → checkbox is No.
- If 401 → missing X-Edge-Auth (client misconfigured).

## CloudWatch Insights Queries

### Lease outcomes (24h)

```
fields @timestamp, type, reason, contactId, email
| filter type in ["lease_ok","lease_denied"]
| stats count() by type, reason
| sort type asc
```

### Errors (24h)

```
fields @timestamp, type, where, detail
| filter type = "lease_error"
| sort @timestamp desc
| limit 50
```

## Where to check

- **HubSpot Webhooks monitor**: Projects → Webhooks monitor
- **Lambda logs**: CloudWatch logs for `/aws/lambda/hh-webhook` and `/aws/lambda/hh-lease`
  - Look for structured JSON logs: `lease_ok`, `lease_denied`, `lease_error`
- **WAF metrics**: CloudWatch metrics for rate limiting