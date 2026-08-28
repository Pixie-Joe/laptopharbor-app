// Smoke test for webhook reconciliation flow
// Steps:
// 1) POST /create-payment-intent with an Idempotency-Key and order_id
// 2) Read idempotency.json to find the stored intent id
// 3) POST a simulated payment_intent.succeeded webhook to /webhook
// 4) Verify idempotency.json reflects the paid status

const http = require('http');
const fs = require('fs');
const path = require('path');

const port = process.env.PORT || process.argv[2] || 4242;
const ID_FILE = path.join(__dirname, 'idempotency.json');

const idempotencyKey = `test-key-${Math.random().toString(36).substring(2,8)}`;
const orderId = `order-${Math.random().toString(36).substring(2,8)}`;

function sendCreateIntent(cb) {
  const body = JSON.stringify({ amount: 1999, currency: 'usd', order_id: orderId });
  const options = {
    hostname: 'localhost',
    port: port,
    path: '/create-payment-intent',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(body),
      'Idempotency-Key': idempotencyKey,
    },
  };

  const req = http.request(options, (res) => {
    let data = '';
    res.on('data', (chunk) => (data += chunk));
    res.on('end', () => cb(null, res.statusCode, data));
  });
  req.on('error', cb);
  req.write(body);
  req.end();
}

function postWebhook(intentId, cb) {
  const payload = JSON.stringify({
    type: 'payment_intent.succeeded',
    data: { object: { id: intentId, status: 'succeeded', metadata: { order_id: orderId } } },
  });

  const options = {
    hostname: 'localhost',
    port: port,
    path: '/webhook',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(payload),
    },
  };

  const req = http.request(options, (res) => {
    let data = '';
    res.on('data', (chunk) => (data += chunk));
    res.on('end', () => cb(null, res.statusCode, data));
  });
  req.on('error', cb);
  req.write(payload);
  req.end();
}

function readStore() {
  try {
    if (!fs.existsSync(ID_FILE)) return null;
    const raw = fs.readFileSync(ID_FILE, 'utf8');
    return JSON.parse(raw || '{}');
  } catch (e) {
    return null;
  }
}

console.log('Starting webhook smoke test with idempotencyKey', idempotencyKey, 'orderId', orderId);

sendCreateIntent((err, status, data) => {
  if (err) return console.error('create intent error', err);
  console.log('create intent status', status, data);

  // read idempotency file to find intent id
  const store = readStore();
  if (!store) return console.error('Failed to read idempotency store');
  const entry = store[idempotencyKey];
  if (!entry) return console.error('Idempotency entry not found in store (was it written?)', store);
  const intentId = (entry.intent && (entry.intent.id || entry.intent.payment_intent)) || null;
  if (!intentId) return console.error('Could not determine intent id from store entry', entry);

  console.log('Found intent id in store:', intentId);

  // Post simulated webhook
  postWebhook(intentId, (err2, status2, data2) => {
    if (err2) return console.error('webhook post error', err2);
    console.log('webhook post status', status2, data2);

    // Re-read store to confirm paid flag
    const store2 = readStore();
    const entry2 = store2 && store2[idempotencyKey];
    if (entry2 && entry2.paid) {
      console.log('SUCCESS: entry marked paid:', entry2);
      process.exit(0);
    }

    // As fallback, check for loose intent_* key
    const looseKey = `intent_${intentId}`;
    if (store2 && store2[looseKey] && store2[looseKey].payment_intent) {
      console.log('SUCCESS (loose record):', store2[looseKey]);
      process.exit(0);
    }

    console.error('FAILED: store did not show paid status', store2);
    process.exit(2);
  });
});
