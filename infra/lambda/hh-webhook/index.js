const crypto = require('crypto');

function buildRequestUrl(evt) {
  const q = evt.rawQueryString ? `?${evt.rawQueryString}` : '';
  return `https://${evt.requestContext.domainName}${evt.rawPath}${q}`;
}

function verifyV3(evt, appSecret) {
  const sig = evt.headers && (evt.headers['x-hubspot-signature-v3'] || evt.headers['X-HubSpot-Signature-V3']);
  const ts  = evt.headers && (evt.headers['x-hubspot-request-timestamp'] || evt.headers['X-HubSpot-Request-Timestamp']);
  if (!sig || !ts) return false;

  const tsNum = Number(ts);
  const skew = Math.abs(Date.now() - tsNum);
  if (!tsNum || skew > 5 * 60 * 1000) return false;

  const method = (evt.requestContext && evt.requestContext.http && evt.requestContext.http.method) || 'POST';
  const url = buildRequestUrl(evt);
  const body = evt.body || '';

  const base = '' + method + url + body + ts;
  const expected = crypto.createHmac('sha256', appSecret).update(base, 'utf8').digest('base64');

  try {
    return crypto.timingSafeEqual(Buffer.from(expected), Buffer.from(sig));
  } catch (e) {
    return false;
  }
}

exports.handler = async function(event) {
  const secret = process.env.HS_APP_SECRET;
  const ok = secret && verifyV3(event, secret);

  if (!ok) {
    console.log('✖ invalid hubspot signature', (event.requestContext && event.requestContext.http && event.requestContext.http.method) || 'POST', event.rawPath);
    return { statusCode: 401, body: 'invalid signature' };
  }

  console.log('✅ hubspot webhook verified', (event.requestContext && event.requestContext.http && event.requestContext.http.method) || 'POST', event.rawPath);

  // quick processing: mint download_token when requested
  const hsToken = process.env.HS_TOKEN; // must be set to call HubSpot CRM
  const base = 'https://api.hubapi.com';

  let events = [];
  try { events = JSON.parse(event.body || '[]'); } catch (e) { events = []; }

  if (Array.isArray(events) && events.length && hsToken) {
    for (const e of events) {
      try {
        if (
          e &&
          e.subscriptionType === 'contact.propertyChange' &&
          e.propertyName === 'download_requested' &&
          String(e.propertyValue) === 'true'
        ) {
          const contactId = e.objectId;
          if (!contactId) continue;

          // 1) read current download_token
          const getRes = await fetch(`${base}/crm/v3/objects/contacts/${contactId}?properties=download_token`, {
            headers: { Authorization: `Bearer ${hsToken}` }
          });
          if (!getRes.ok) {
            console.error('hubspot get failed', contactId, await getRes.text());
            continue;
          }
          const c = await getRes.json();
          const current = c && c.properties && c.properties.download_token;

          // 2) prepare patch: always clear the flag; set token if missing
          const props = { download_requested: 'false' };
          if (!current) props.download_token = genToken(16);

          const upRes = await fetch(`${base}/crm/v3/objects/contacts/${contactId}`, {
            method: 'PATCH',
            headers: {
              Authorization: `Bearer ${hsToken}`,
              'Content-Type': 'application/json'
            },
            body: JSON.stringify({ properties: props })
          });
          if (!upRes.ok) {
            const t = await upRes.text();
            console.error('hubspot patch failed', contactId, upRes.status, t);
          } else {
            console.log('minted_token', contactId, props.download_token || current || '<existing>');
            // optional confirmation GET if requested
            if (process.env.HS_CONFIRM_WRITE === '1') {
              try {
                const conf = await fetch(`${base}/crm/v3/objects/contacts/${contactId}?properties=download_token,download_requested`, { headers: { Authorization: `Bearer ${hsToken}` } });
                if (conf.ok) {
                  const confj = await conf.json();
                  console.log('confirm_write', contactId, confj && confj.properties ? { download_token: confj.properties.download_token, download_requested: confj.properties.download_requested } : null);
                } else {
                  const tt = await conf.text();
                  console.error('confirm get failed', contactId, conf.status, tt);
                }
              } catch (err) {
                console.error('confirm get failed', contactId, err && err.stack || err);
              }
            }
          }
        }
      } catch (err) {
        console.error('processing event failed', err && err.stack || err);
      }
    }
  }

  return { statusCode: 200, body: 'ok' };
};

function genToken(n = 16) {
  const A = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  let s = '';
  for (let i = 0; i < n; i++) s += A[Math.floor(Math.random() * A.length)];
  return s.match(/.{1,4}/g).join('-');
}
