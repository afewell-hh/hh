const crypto = require('crypto');
const https = require('https');
const { URL } = require('url');

function usage() {
  console.error('Usage: node simulate-hs-webhook.js --url <webhookUrl> --secret <appSecret> --contact <contactId>');
  process.exit(2);
}

function parseArgs() {
  const out = {};
  const a = process.argv.slice(2);
  for (let i = 0; i < a.length; i++) {
    const k = a[i];
    if (k.startsWith('--')) {
      const name = k.slice(2);
      const v = a[i+1] && !a[i+1].startsWith('--') ? a[++i] : true;
      out[name] = v;
    } else if (k.startsWith('-')) {
      const name = k.slice(1);
      const v = a[i+1] && !a[i+1].startsWith('-') ? a[++i] : true;
      out[name] = v;
    }
  }
  return out;
}

const argv = parseArgs();
const url = argv.url || argv.u;
const secret = argv.secret || argv.s;
const contact = argv.contact || argv.c;
if (!url || !secret || !contact) usage();

const ts = Date.now().toString();
const body = JSON.stringify([{ subscriptionType: 'contact.propertyChange', propertyName: 'download_requested', propertyValue: 'true', objectId: Number(contact), eventId: Date.now(), occurredAt: new Date().toISOString(), attemptNumber: 0 }]);
const method = 'POST';
const fullUrl = url; // must match exactly the URL used by HubSpot
const base = method + fullUrl + body + ts;
const hmac = crypto.createHmac('sha256', secret).update(base, 'utf8').digest('base64');

const parsed = new URL(fullUrl);
const opts = {
  method: 'POST',
  hostname: parsed.hostname,
  path: parsed.pathname + (parsed.search || ''),
  headers: {
    'content-type': 'application/json',
    'x-hubspot-request-timestamp': ts,
    'x-hubspot-signature-v3': hmac,
    'content-length': Buffer.byteLength(body)
  }
};

const req = https.request(opts, (res) => {
  let out = '';
  res.setEncoding('utf8');
  res.on('data', (d) => out += d);
  res.on('end', () => {
    console.log('status', res.statusCode);
    console.log('body', out);
  });
});
req.on('error', (e) => console.error('request error', e));
req.write(body);
req.end();
