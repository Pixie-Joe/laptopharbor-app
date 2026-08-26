// Simple smoke test for the local Stripe stub server.
// Usage: node smoke-test.js [port]

const http = require('http');
const port = process.env.PORT || process.argv[2] || 4242;

const postData = JSON.stringify({ amount: 1999, currency: 'usd' });

const options = {
  hostname: 'localhost',
  port: port,
  path: '/create-payment-intent',
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Content-Length': postData.length,
  },
};

const req = http.request(options, (res) => {
  let data = '';
  res.on('data', (chunk) => (data += chunk));
  res.on('end', () => {
    console.log('Status:', res.statusCode);
    console.log('Body:', data);
    process.exit(res.statusCode === 200 ? 0 : 2);
  });
});

req.on('error', (err) => {
  console.error('Request error:', err);
  process.exit(3);
});

req.write(postData);
req.end();
