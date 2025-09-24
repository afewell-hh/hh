# hh Admin Guide

This guide provides operational guidance for administrators managing the hh system.

## System Overview

The hh system consists of:
- **AWS API Gateway** - Public endpoint for token lease requests
- **AWS Lambda functions** - Handle token minting and validation
- **AWS Secrets Manager** - Secure storage for HubSpot and GHCR credentials
- **HubSpot Custom Properties** - Store download tokens on Contact records
- **Docker Credential Helper** - Local binary that exchanges pairing codes for GHCR credentials

## HubSpot Workflow Summary

1. **Lead qualification** triggers HubSpot workflow
2. **Token generation** creates unique download token, stores in Contact's `download_token` property
3. **Email delivery** sends pairing code to contact using email template
4. **User activation** when user runs `hh login --code "TOKEN"` and `hh download`

## Manual Token Operations

### Mint a New Token

Use HubSpot UI or API to set the `download_token` property on a Contact:

```bash
# Example API call (replace with actual values)
curl -X PATCH \
  "https://api.hubapi.com/crm/v3/objects/contacts/{contact_id}" \
  -H "Authorization: Bearer YOUR_PRIVATE_APP_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "properties": {
      "download_token": "hh_abcd1234567890abcdef1234567890ab"
    }
  }'
```

### Revoke a Token

Clear the `download_token` property:

```bash
curl -X PATCH \
  "https://api.hubapi.com/crm/v3/objects/contacts/{contact_id}" \
  -H "Authorization: Bearer YOUR_PRIVATE_APP_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "properties": {
      "download_token": ""
    }
  }'
```

## CloudWatch Monitoring

### Key CloudWatch Queries

**Successful lease requests:**
```
fields @timestamp, @message
| filter @message like /lease_ok/
| stats count() by bin(5m)
```

**Failed lease requests:**
```
fields @timestamp, @message
| filter @message like /lease_denied/
| sort @timestamp desc
```

**Token validation errors:**
```
fields @timestamp, @message
| filter @message like /invalid_token/
| sort @timestamp desc
```

**Rate limiting events:**
```
fields @timestamp, @message
| filter @message like /throttled/
| sort @timestamp desc
```

### CloudWatch Alarms

Monitor these metrics:

1. **High error rate** - Alert when 4xx/5xx responses exceed 10% over 5 minutes
2. **Lambda duration** - Alert when function duration exceeds 10 seconds
3. **Lambda errors** - Alert on any Lambda function errors
4. **API Gateway throttling** - Alert when throttle count > 0

## Reading Logs

### lease_ok Events
```json
{
  "timestamp": "2025-01-20T10:30:45Z",
  "level": "INFO",
  "message": "lease_ok",
  "token_prefix": "hh_abcd12",
  "contact_id": "12345",
  "lease_duration": 3600
}
```

### lease_denied Events
```json
{
  "timestamp": "2025-01-20T10:30:45Z",
  "level": "WARN",
  "message": "lease_denied",
  "token_prefix": "hh_xyz789",
  "reason": "token_not_found",
  "source_ip": "203.0.113.1"
}
```

Common denial reasons:
- `token_not_found` - Token doesn't exist in HubSpot
- `token_expired` - Token is older than configured TTL
- `rate_limited` - Too many requests from same IP
- `invalid_format` - Token format is incorrect

## Temporarily Disable Downloads

### Option 1: API Gateway Maintenance Mode

Enable maintenance mode on API Gateway to return 503 responses:

1. Go to AWS Console > API Gateway
2. Find the hh API
3. Go to Settings > Enable maintenance mode
4. Deploy to production stage

### Option 2: Lambda Environment Variable

Set `MAINTENANCE_MODE=true` on the Lambda function:

```bash
aws lambda update-function-configuration \
  --function-name hh-lease-prod \
  --environment Variables='{MAINTENANCE_MODE=true}' \
  --profile hh-deployer
```

Users will see: "Service temporarily unavailable for maintenance"

## Emergency Procedures

### Mass Token Revocation

To revoke all active tokens:

1. **Method A:** Clear all `download_token` properties via HubSpot bulk operation
2. **Method B:** Update Lambda function to deny all requests temporarily

### Credential Compromise Response

If GHCR credentials are compromised:

1. **Rotate secrets** in AWS Secrets Manager
2. **Update Lambda environment** `CACHE_BUSTER` to force refresh
3. **Monitor logs** for unusual access patterns
4. **Notify users** to re-run `hh login` if needed

### HubSpot API Issues

If HubSpot API is unavailable:

1. **Check HubSpot status** at status.hubspot.com
2. **Review CloudWatch logs** for 429/500 responses from HubSpot
3. **Consider maintenance mode** if extended outage expected

## Configuration Management

### Environment Variables (Lambda)

- `HUBSPOT_ACCESS_TOKEN` - Retrieved from Secrets Manager
- `GHCR_USERNAME` - Retrieved from Secrets Manager
- `GHCR_TOKEN` - Retrieved from Secrets Manager
- `CACHE_BUSTER` - Forces secret refresh (increment when rotating)
- `MAINTENANCE_MODE` - Set to "true" to disable service

### Rate Limiting Configuration (API Gateway)

Current settings:
- Burst: 50 requests/second
- Rate: 25 requests/second sustained
- Per-IP throttling enabled

### Token TTL Configuration

Default token lifetime: 30 days from creation
Configured in Lambda environment or code.

## Monitoring Dashboards

Recommended CloudWatch dashboard widgets:

1. **Request Volume** - Successful vs failed lease requests over time
2. **Response Times** - Lambda duration and API Gateway latency
3. **Error Rates** - 4xx and 5xx response percentages
4. **Top Denial Reasons** - Breakdown of why tokens are denied
5. **Geographic Distribution** - Request origins by region/country

## Backup and Recovery

### Critical Data
- **HubSpot Contact data** - Backed up by HubSpot (SaaS)
- **AWS Lambda code** - Stored in version control and deployment artifacts
- **AWS Secrets** - No backup needed; secrets can be regenerated

### Recovery Procedures
1. **Lambda function failure** - Redeploy from CI/CD or manual deployment
2. **API Gateway issues** - Recreate from Infrastructure as Code
3. **Secrets Manager issues** - Regenerate secrets and update configuration

## Compliance and Auditing

### Audit Trail
- **CloudWatch logs** retain all token requests and responses
- **HubSpot activity logs** show token generation and modifications
- **API Gateway access logs** provide detailed request metadata

### Data Retention
- CloudWatch logs: 30 days (configurable)
- API Gateway logs: 30 days (configurable)
- HubSpot data: Per HubSpot retention policies

### Security Reviews
- Review IAM policies quarterly
- Rotate secrets every 90 days
- Monitor for unusual access patterns
- Review user feedback for security concerns