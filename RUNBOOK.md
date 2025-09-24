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

## Rotate Secrets (AWS Secrets Manager)

Secrets are now stored in AWS Secrets Manager and rotated without Lambda redeployment.

### Rotate HubSpot token

```bash
aws secretsmanager put-secret-value \
  --secret-id /hh/prod/hubspot/token \
  --secret-string '{"token":"<NEW_TOKEN>"}' \
  --region us-west-2
```

### Rotate GHCR PAT

```bash
aws secretsmanager put-secret-value \
  --secret-id /hh/prod/ghcr/creds \
  --secret-string '{"username":"hh-partner","pat":"<NEW_PAT>"}' \
  --region us-west-2
```

### Rotate HubSpot App Secret

```bash
aws secretsmanager put-secret-value \
  --secret-id /hh/prod/hubspot/app_secret \
  --secret-string '{"secret":"<NEW_SECRET>"}' \
  --region us-west-2
```

**Note:** Cache TTL is ~5 minutes. To force immediate refresh, publish a new Lambda version or trigger UpdateFunctionCode (usually not needed).

## Rotate EDGE_SHARED_SECRET

Update the `EDGE_SHARED_SECRET` environment variable on the `hh-authz` Lambda:

```bash
NEW_SECRET="$(openssl rand -base64 32)"
aws lambda update-function-configuration --function-name hh-authz --environment Variables={EDGE_SHARED_SECRET=$NEW_SECRET}
aws lambda wait function-updated-v2 --function-name hh-authz
```

Update releases/installer with the new default value and instruct existing customers to:
- Re-run `hh login` (user mode), or
- Re-run `hh login --system` (system mode), or
- Manually edit config files to update the `edge_auth` field:
  - User mode: `~/.hh/config.json`
  - System mode: `/etc/hh/config.json`

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

## File Locations

### System Config Files
- System configuration: `/etc/hh/config.json` (requires sudo, readable by root)
- System credential helper: `/usr/local/bin/docker-credential-hh`
- Root Docker config: `/root/.docker/config.json` (for sudo docker commands)

### User Config Files
- User configuration: `~/.hh/config.json` (standard user mode)
- User Docker config: `~/.docker/config.json`
- XDG config: `$XDG_CONFIG_HOME/hh/config.json` (if XDG_CONFIG_HOME is set)

### Environment Variables
- `HH_CONFIG`: Override config file path (highest precedence)
- `XDG_CONFIG_HOME`: XDG base directory specification

## Where to check

- **HubSpot Webhooks monitor**: Projects → Webhooks monitor
- **Lambda logs**: CloudWatch logs for `/aws/lambda/hh-webhook` and `/aws/lambda/hh-lease`
  - Look for structured JSON logs: `lease_ok`, `lease_denied`, `lease_error`
- **WAF metrics**: CloudWatch metrics for rate limiting

## Troubleshooting Docker Permission Issues

### User reports "permission denied" on docker commands

1. **Preferred solution**: Add user to docker group
   ```bash
   sudo usermod -aG docker $USER && newgrp docker
   ```

2. **Alternative for CI/hardened environments**: Use system mode
   ```bash
   hh login --system --code "PAIRING_CODE"
   hh download --system
   ```

### System mode not working

- Verify system config exists: `sudo cat /etc/hh/config.json`
- Check credential helper installation: `ls -la /usr/local/bin/docker-credential-hh`
- Verify root Docker config: `sudo cat /root/.docker/config.json`
- Test helper with system config: `sudo -E env HH_CONFIG=/etc/hh/config.json docker-credential-hh get`