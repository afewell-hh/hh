# HubSpot Workflow & Email Setup Guide

This guide covers setting up the HubSpot workflow for the pairing code flow that automatically sends download emails with tokens when forms are submitted.

## Workflow Overview

**Goal**: When a download form is submitted, mint a token (via webhook) and send the user an email with pairing code instructions.

## Prerequisites

1. **HubSpot Form**: Create a form to capture download requests with required fields:
   - First Name (`firstname`)
   - Email (`email`)
   - Any other fields you want to collect

2. **Contact Properties**: Ensure these custom contact properties exist:
   - `download_requested` (Single checkbox)
   - `download_token` (Single-line text)
   - `download_enabled` (Single checkbox, defaults to "Yes")

## Step-by-Step Workflow Setup

### 1. Create the Workflow

1. Navigate to **Marketing** → **Workflows** in HubSpot
2. Click **Create workflow**
3. Choose **Contact-based** workflow
4. Select **From scratch**

### 2. Configure the Trigger

**Trigger Type**: Form submission

1. Click **Set enrollment triggers**
2. Select **Form submissions**
3. Choose your download form
4. Set additional filters if needed
5. Click **Apply filter**

### 3. Action 1: Set download_requested = true

This triggers the webhook to mint a token.

1. Click **+** to add an action
2. Select **Set property value**
3. Choose contact property: `download_requested`
4. Set value to: `true` (checked)
5. Click **Save**

### 4. Action 2: Delay (2 minutes)

Gives webhook time to write the `download_token`.

1. Click **+** to add an action
2. Select **Delay**
3. Set delay amount: `2 minutes`
4. Click **Save**

### 5. Action 3: Send Email with Personalization Tokens

#### Create the Email Template

1. Click **+** to add an action
2. Select **Send email**
3. Click **Create new email**
4. Choose email type: **Regular email**

#### Email Configuration

**Email Template (use exactly as provided):**

**Subject**: Your Hedgehog download is ready

**Body**:
```
Hi {{ contact.firstname | default('there') }},

Here's your pairing code for authenticated downloads:

  {{ contact.download_token }}

Get started:
  1) Install hh:
     curl -fsSL https://github.com/afewell-hh/hh/releases/download/v0.1.12/install-hh.sh | bash
  2) Log in with your code:
     hh login --code "{{ contact.download_token }}"
  3) Install helper and tools:
     hh download

Next:
  mkdir -p ~/hhfab-dir && cd ~/hhfab-dir
  hhfab init --dev && hhfab vlab gen && hhfab build

Need help? Reply to this email with any error messages or run "hh doctor" and share the output.
```

### 6. Add If/Then Guard (Fallback Email)

Add a conditional branch to handle cases where `download_token` is empty after the delay.

1. After the delay action, click **+** to add an action
2. Select **If/then branch**
3. **If** condition:
   - Property: `download_token`
   - Is equal to: (leave empty for "is empty")
4. **Then** branch: Send fallback email
5. **Else** branch: Send the main email (move Action 3 here)

#### Fallback Email Template

**Subject**: Your Hedgehog download is being processed

**Body**:
```html
Hi {{ contact.firstname|default:"there" }},

We're processing your download request right now. You'll receive your pairing code shortly (usually within 5 minutes).

If you don't receive it within 10 minutes, please reply to this email and we'll help you get set up.

Thanks for your patience!
```

### 7. Workflow Settings

1. **Enrollment**:
   - Allow re-enrollment: No (unless you want users to get multiple codes)
   - Suppress for unengaged contacts: No

2. **Goal**: Optional - you can set a goal like "Contact downloaded successfully"

3. **Review and Activate**:
   - Review all actions
   - Click **Review and publish**
   - Click **Turn on**

## Testing the Workflow

### Create a Test Contact

1. Navigate to **Contacts** → **Contacts**
2. Click **Create contact**
3. Fill in test details:
   - First name: Test User
   - Email: your-test-email@example.com
   - Set `download_enabled` to `true`

### Submit Test Form

1. Go to your download form
2. Submit with the test contact's information
3. Check the workflow execution in **Marketing** → **Workflows** → Your workflow → **Performance**

### Verify Results

1. **Webhook logs**: Check CloudWatch logs for `minted_token` message
   ```bash
   aws logs tail /aws/lambda/hh-webhook --follow
   ```

2. **Contact record**: Verify the contact now has:
   - `download_requested`: true
   - `download_token`: [some generated token]

3. **Email delivery**: Check that test email contains non-empty token

4. **Token functionality**: Test the token works:
   ```bash
   hh login --code "TOKEN_FROM_EMAIL"
   hh download
   ```

## Troubleshooting

### Common Issues

1. **Empty token in email**:
   - Check webhook CloudWatch logs for errors
   - Verify webhook subscription is active
   - Ensure `download_enabled` is true on contact

2. **No email sent**:
   - Check workflow enrollment
   - Verify email template is published
   - Check contact's email engagement settings

3. **Token doesn't work**:
   - Verify token format in contact record
   - Check `/aws/lambda/hh-lease` logs for auth errors
   - Ensure contact has `download_enabled` = true

### Manual Token Reset

If a user reports issues, you can manually reset their token:

```bash
CONTACT_ID=156855158284
curl -sS -X PATCH "https://api.hubapi.com/crm/v3/objects/contacts/$CONTACT_ID" \
  -H "Authorization: Bearer $HS_TOKEN" -H "Content-Type: application/json" \
  -d '{"properties":{"download_token":"", "download_requested":"true"}}' >/dev/null
```

This will trigger the webhook to mint a new token.

## Monitoring

### CloudWatch Insights Queries

**Lease outcomes (24h)**:
```
fields @timestamp, type, reason, contactId, email
| filter type in ["lease_ok","lease_denied"]
| stats count() by type, reason
| sort type asc
```

**Webhook activity**:
```
fields @timestamp, level, msg, contactId
| filter level = "info"
| sort @timestamp desc
| limit 50
```