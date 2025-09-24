# hh Security Architecture

This document details the security design and implementation of the hh system.

## Overview

The hh system uses a secure token-based authentication model with the following security principles:
- **Defense in depth** - Multiple security layers
- **Least privilege** - Minimal required permissions
- **Secrets isolation** - No plaintext secrets in code or logs
- **Audit trail** - Comprehensive logging of all operations

## Secrets Manager Design

### Secret Storage Locations

All sensitive credentials are stored in AWS Secrets Manager:

- **HubSpot credentials** - `/hh/prod/hubspot/access-token`
- **GHCR credentials** - `/hh/prod/ghcr/username` and `/hh/prod/ghcr/token`

### Regions

Primary region: `us-west-2`
Backup region: `us-east-1` (planned)

### IAM Policy Pattern

Lambda execution role has minimal permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue"
      ],
      "Resource": [
        "arn:aws:secretsmanager:us-west-2:ACCOUNT:secret:/hh/prod/*"
      ]
    }
  ]
}
```

### 5-Minute Lambda Cache

Lambda functions cache secrets for 5 minutes to reduce API calls while maintaining security:

- **Cache key** - Secret ARN + version + `CACHE_BUSTER` environment variable
- **Cache lifetime** - 300 seconds (5 minutes)
- **Cache invalidation** - Automatic expiry or increment `CACHE_BUSTER`

## Rotation Procedures

### HubSpot Token Rotation

1. **Generate new private app token** in HubSpot
2. **Test new token** with read/write operations
3. **Update secret** in AWS Secrets Manager:
   ```bash
   aws secretsmanager update-secret \
     --secret-id "/hh/prod/hubspot/access-token" \
     --secret-string "new-hubspot-token" \
     --region us-west-2 \
     --profile hh-deployer
   ```
4. **Force Lambda refresh** by incrementing `CACHE_BUSTER`:
   ```bash
   aws lambda update-function-configuration \
     --function-name hh-lease-prod \
     --environment Variables="{CACHE_BUSTER=$(date +%s)}" \
     --profile hh-deployer
   ```
5. **Monitor logs** for successful authentication
6. **Disable old token** in HubSpot after verification

### GHCR Token Rotation

1. **Generate new GitHub PAT** with `read:packages` scope
2. **Test new token** with docker pull operations
3. **Update secrets** in AWS Secrets Manager:
   ```bash
   aws secretsmanager update-secret \
     --secret-id "/hh/prod/ghcr/token" \
     --secret-string "new-github-pat" \
     --region us-west-2 \
     --profile hh-deployer
   ```
4. **Force refresh** same as HubSpot procedure
5. **Revoke old PAT** in GitHub settings

## Emergency Revocation Procedure

### Immediate Token Revocation

In case of security incident:

1. **Set maintenance mode** (immediate):
   ```bash
   aws lambda update-function-configuration \
     --function-name hh-lease-prod \
     --environment Variables='{MAINTENANCE_MODE=true}' \
     --profile hh-deployer
   ```

2. **Clear all download tokens** (bulk operation in HubSpot):
   - Export all contacts with `download_token` property
   - Bulk update to clear `download_token` field
   - Or use HubSpot API with batch operations

3. **Rotate all secrets** following procedures above

4. **Review audit logs** for compromise timeline

5. **Notify users** via communication channels

### API Gateway Circuit Breaker

Enable throttling or maintenance mode at API Gateway level:

```bash
# Enable request throttling
aws apigateway update-stage \
  --rest-api-id YOUR_API_ID \
  --stage-name prod \
  --patch-ops op=replace,path=/throttle/rateLimit,value=1
```

## Authentication Flow Security

### Token Format

Pairing codes follow the pattern: `hh_[32-char-hex]`
- **Prefix** - `hh_` for easy identification
- **Entropy** - 128 bits (cryptographically secure)
- **Character set** - Hexadecimal (0-9, a-f)

### Validation Steps

1. **Format validation** - Check prefix and character set
2. **HubSpot lookup** - Verify token exists in Contact records
3. **Freshness check** - Ensure token age < TTL (30 days default)
4. **Rate limiting** - Per-IP and global throttling
5. **Audit logging** - Record all attempts (success/failure)

### Credential Exchange

The Docker credential helper never stores GHCR credentials:
- **Token exchange** - Pairing code → temporary GHCR credentials
- **Short-lived credentials** - 1-hour expiry typical
- **No local storage** - Credentials fetched on each docker pull
- **Fallback behavior** - Anonymous access if token invalid

## Network Security

### TLS Configuration

- **API Gateway** - TLS 1.2+ required
- **Certificate** - AWS-managed certificate
- **HSTS headers** - Enforced via API Gateway response headers
- **Client authentication** - Token-based (no mutual TLS)

### Rate Limiting

Multi-layered rate limiting:

1. **API Gateway throttling**
   - Burst: 50 requests/second
   - Sustained: 25 requests/second

2. **Per-IP limiting** (future enhancement)
   - 10 requests/minute per IP
   - 100 requests/hour per IP

3. **Lambda concurrency**
   - Reserved concurrency prevents resource exhaustion

### IP Allowlisting

Currently no IP restrictions (public endpoint), but architecture supports:
- **WAF rules** for geographic blocking
- **VPC endpoints** for internal access only
- **Source IP logging** for forensic analysis

## Data Protection

### PII Handling

- **No PII in logs** - Email addresses masked in CloudWatch logs
- **Token-only storage** - No names, emails, or personal data in Lambda
- **HubSpot isolation** - Personal data stays in HubSpot
- **Minimal data retention** - CloudWatch logs purged after 30 days

### Encryption

- **Secrets at rest** - AWS Secrets Manager (AES-256)
- **Logs at rest** - CloudWatch Logs encryption with AWS KMS
- **Data in transit** - TLS 1.2+ for all connections
- **Lambda environment** - No sensitive data in environment variables

## Monitoring and Alerting

### Security Events

Monitor for:
- **Brute force attacks** - High frequency of lease_denied events
- **Token enumeration** - Sequential or patterned token attempts
- **Geographic anomalies** - Requests from unexpected regions
- **Volume spikes** - Unusual request patterns

### Automated Response

- **Lambda circuit breaker** - Auto-disable on error threshold
- **CloudWatch alarms** - Alert on security event patterns
- **WAF rules** - Block malicious IP ranges automatically

## Compliance Considerations

### Audit Requirements

- **Request logging** - All API calls logged with source IP, timestamp, outcome
- **Secret access** - Secrets Manager logs all GetSecretValue calls
- **Change tracking** - CloudTrail logs all AWS API modifications

### Data Residency

- **Primary region** - us-west-2 (Oregon)
- **Data sovereignty** - All data processing within configured AWS regions
- **Cross-border transfers** - Minimal, only for CDN and public facing services

### Retention Policies

- **Application logs** - 30 days in CloudWatch
- **Audit trails** - 90 days in CloudTrail
- **Secrets history** - AWS Secrets Manager maintains version history
- **HubSpot data** - Per HubSpot's retention policies

## Security Testing

### Regular Assessments

- **Quarterly vulnerability scans** - Automated security scanning
- **Annual penetration testing** - Third-party security assessment
- **Code security review** - Static analysis on all commits

### Threat Model Reviews

Review threat model annually or when major changes occur:
- **Attack vectors** - Token compromise, API abuse, credential theft
- **Risk assessment** - Impact vs. likelihood analysis
- **Mitigation strategies** - Technical and procedural controls