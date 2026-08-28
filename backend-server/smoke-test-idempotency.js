// Smoke test to assert idempotency behaviour. Sends two requests with same idempotency key.
const http = require('http');
const port = process.env.PORT || process.argv[2] || 4242;
const idempotencyKey = `test-key-${Math.random().toString(36).substring(2,8)}`;

function send(postData, headers, cb) {
  const options = {
    hostname: 'localhost',
    port: port,
    path: '/create-payment-intent',
    method: 'POST',
    headers: headers,
  };

  const req = http.request(options, (res) => {
    let data = '';
    res.on('data', (chunk) => (data += chunk));
    res.on('end', () => cb(null, res.statusCode, data));
  });

  req.on('error', (err) => cb(err));
  req.write(postData);
  req.end();
}

const body = JSON.stringify({ amount: 1999, currency: 'usd' });
const headers = {
  'Content-Type': 'application/json',
  'Content-Length': Buffer.byteLength(body),
  'Idempotency-Key': idempotencyKey,
};

send(body, headers, (err, status, data) => {
  if (err) return console.error('First request error', err);
  console.log('First status', status, data);

  // second request with same idempotency key
  send(body, headers, (err2, status2, data2) => {
    if (err2) return console.error('Second request error', err2);
    console.log('Second status', status2, data2);
    process.exit(0);
  });
});
