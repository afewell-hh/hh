import { getJsonSecret } from "./secret.js";
const fetch = globalThis.fetch;

// Simple /lease handler: verifies header, queries HubSpot for contact with download_token, returns GHCR creds
export const handler = async function(event) {
  try {
    const headers = event.headers || {};
    const token = headers['x-download-token'] || headers['X-Download-Token'];
    if (!token) return { statusCode: 401, body: JSON.stringify({ error: 'missing token' }) };

    const HUBSPOT_TOKEN_NAME = process.env.HH_SECR_ARN_HUBSPOT_TOKEN; // /hh/prod/hubspot/token
    const { token: hs } = await getJsonSecret(HUBSPOT_TOKEN_NAME);
    if (!hs) return { statusCode: 500, body: JSON.stringify({ error: 'missing hs token' }) };

    const base = 'https://api.hubapi.com';
    const res = await fetch(`${base}/crm/v3/objects/contacts/search`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${hs}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({
        filterGroups: [{ filters: [{ propertyName: 'download_token', operator: 'EQ', value: token }] }],
        properties: ['email','download_token','download_enabled']
      })
    });

    if (!res.ok) {
      const text = await res.text().catch(()=>null);
      console.log('hubspot search failed', res.status, text);
      return { statusCode: 502, body: JSON.stringify({ error: 'hubspot search failed' }) };
    }

    const data = await res.json();
    if (!data.total) return { statusCode: 403, body: JSON.stringify({ error: 'invalid token' }) };

    const hit = data.results && data.results[0];
    const props = hit && hit.properties ? hit.properties : {};
    // download_enabled may be 'false' or unset; treat missing as enabled
    const downloadEnabled = (props.download_enabled || '').toString();
    const email = props.email || '';
    const maskedEmail = email.includes('@') ? email.replace(/^(.).+(@.*)$/, '$1***$2') : (email ? '***' : '');

    if (downloadEnabled === 'false') {
      console.log(`lease_denied reason=disabled contactId=${hit.id} email=${maskedEmail}`);
      return { statusCode: 403, body: JSON.stringify({ error: 'disabled' }) };
    }

    const GHCR_CREDS_NAME = process.env.HH_SECR_ARN_GHCR_CREDS;    // /hh/prod/ghcr/creds
    const { username: u, pat: p } = await getJsonSecret(GHCR_CREDS_NAME);
    if (!u || !p) return { statusCode: 500, body: JSON.stringify({ error: 'missing ghcr creds' }) };

  // log success with masked email
  console.log(`lease_ok contactId=${hit.id} email=${maskedEmail}`);

  const body = JSON.stringify({ ServerURL: 'ghcr.io', Username: u, Secret: p });
  return { statusCode: 200, headers: { 'content-type': 'application/json' }, body };
  } catch (err) {
    console.error('lease error', err);
    return { statusCode: 500, body: JSON.stringify({ error: 'internal error' }) };
  }
};
