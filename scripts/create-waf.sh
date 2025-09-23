#!/usr/bin/env bash
set -euo pipefail

# Usage: scripts/create-waf.sh
# Requires AWS_PROFILE=hh-deployer AWS_REGION=us-west-2 in env

WAF_ARN=$(aws wafv2 create-web-acl \
  --name hh-api-waf \
  --scope REGIONAL \
  --default-action Allow={} \
  --visibility-config SampledRequestsEnabled=true,CloudWatchMetricsEnabled=true,MetricName=hhApiWaf \
  --rules '[{"Name":"RateLimit1k5m","Priority":0,"Statement":{"RateBasedStatement":{"Limit":1000,"AggregateKeyType":"IP"}},"Action":{"Block":{}},"VisibilityConfig":{"SampledRequestsEnabled":true,"CloudWatchMetricsEnabled":true,"MetricName":"RateLimit1k5m"}}]' \
  --query 'Summary.ARN' --output text)

echo "WAF_ARN=$WAF_ARN"

aws wafv2 associate-web-acl \
  --scope REGIONAL \
  --web-acl-arn "$WAF_ARN" \
  --resource-arn "arn:aws:apigateway:us-west-2::/apis/pc4x1xgehc/stages/$default"

echo 'done'
