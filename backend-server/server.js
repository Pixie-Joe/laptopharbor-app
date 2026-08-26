/*
Minimal Node/Express server stub for Stripe PaymentIntent creation (test mode)

Usage:
  1. Install dependencies: npm install express stripe cors dotenv
  2. Create a .env file with STRIPE_SECRET_KEY and optionally PORT
  3. Run: node server.js

Endpoints:
  POST /create-payment-intent
    body: { amount: number, currency?: 'usd' }
    returns: { clientSecret }

Security:
  - Do not commit .env or secret keys. Use environment variables in deployment.
  - This is a test stub for local development only.
*/

const express = require('express');
const Stripe = require('stripe');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

const stripeSecret = process.env.STRIPE_SECRET_KEY;
let stripe = null;
let useStripe = false;

if (stripeSecret) {
  stripe = Stripe(stripeSecret);
  useStripe = true;
  console.log('Stripe initialized using provided STRIPE_SECRET_KEY');
} else {
  console.warn('STRIPE_SECRET_KEY not set — running in local stub mode. No calls to Stripe will be performed.');
}

// File-backed simple idempotency store (small JSON file)
const IDEMPOTENCY_FILE = path.join(__dirname, 'idempotency.json');
function _readIdempotencyStore() {
  try {
    if (!fs.existsSync(IDEMPOTENCY_FILE)) return {};
    const raw = fs.readFileSync(IDEMPOTENCY_FILE, 'utf8');
    return JSON.parse(raw || '{}');
  } catch (e) {
    console.error('Failed to read idempotency store:', e);
    return {};
  }
}
function _writeIdempotencyStore(obj) {
  try {
    fs.writeFileSync(IDEMPOTENCY_FILE, JSON.stringify(obj, null, 2));
  } catch (e) {
    console.error('Failed to write idempotency store:', e);
  }
}

// Helper to create a payment intent either via Stripe (if configured) or return a stubbed response.
async function createPaymentIntent({ amount, currency = 'usd' }, options = {}) {
  // If idempotency key is provided and already exists, return stored result
  const idempotencyKey = options.idempotencyKey;
  if (idempotencyKey) {
    const store = _readIdempotencyStore();
    if (store[idempotencyKey]) {
      return store[idempotencyKey].intent;
    }
  }

  let intent;
  if (useStripe && stripe) {
    // If using Stripe, pass idempotencyKey in the second arg to the SDK when present
    if (idempotencyKey) {
      intent = await stripe.paymentIntents.create({
        amount: Math.round(amount),
        currency,
        metadata: { integration_check: 'accept_a_payment' },
      }, { idempotencyKey });
    } else {
      intent = await stripe.paymentIntents.create({
        amount: Math.round(amount),
        currency,
        metadata: { integration_check: 'accept_a_payment' },
      });
    }
  } else {
    // Stubbed response for local development when Stripe secret is not available.
    intent = {
      id: `pi_stub_${Math.random().toString(36).substring(2, 10)}`,
      amount: Math.round(amount),
      currency,
      client_secret: `pi_stub_client_secret_${Math.random().toString(36).substring(2, 12)}`,
    };
  }

  // Persist idempotency mapping if provided
  if (idempotencyKey) {
    const store = _readIdempotencyStore();
    store[idempotencyKey] = {
      intent: intent,
      created_at: new Date().toISOString(),
      order_id: options.orderId || null,
    };
    _writeIdempotencyStore(store);
  }

  return intent;
}

app.get('/health', (_req, res) => res.json({ status: 'ok' }));

app.post('/create-payment-intent', async (req, res) => {
  try {
    const { amount, currency = 'usd', order_id } = req.body;
    const idempotencyKey = req.headers['idempotency-key'] || req.body.idempotency_key || null;

    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Invalid amount' });
    }

    // The Flutter client sends `amount` in the smallest currency unit (cents).
    // Use the value directly and avoid multiplying again.
    const paymentIntent = await createPaymentIntent({ amount, currency }, { idempotencyKey, orderId: order_id });

    return res.json({ clientSecret: paymentIntent.client_secret || paymentIntent.clientSecret || paymentIntent.client_secret });
  } catch (err) {
    console.error('create-payment-intent error', err);
    return res.status(500).json({ error: 'Internal error' });
  }
});

// Optional webhook endpoint. When STRIPE_WEBHOOK_SECRET is set, verify signatures.
app.post('/webhook', express.raw({ type: 'application/json' }), (req, res) => {
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;

  if (!webhookSecret) {
    // If no webhook secret provided, attempt to parse and log event body for development.
    try {
      const event = JSON.parse(req.body.toString());
      console.log('Webhook received (unverified):', event.type);
      // Respond with 200 so Stripe treats it as received in test setups.
      return res.json({ received: true });
    } catch (err) {
      console.error('Webhook parse error:', err);
      return res.status(400).send(`Webhook error: ${err.message}`);
    }
  }

  // If webhook secret provided, verify signature
  const sig = req.headers['stripe-signature'];
  if (!sig) {
    console.error('Missing stripe-signature header');
    return res.status(400).send('Missing stripe-signature header');
  }

  let event;
  try {
    event = stripe.webhooks.constructEvent(req.body, sig, webhookSecret);
  } catch (err) {
    console.error('Webhook signature verification failed:', err.message);
    return res.status(400).send(`Webhook Error: ${err.message}`);
  }

  console.log('Webhook verified event:', event.type);
  // Optionally handle events here (payment_intent.succeeded, charge.failed, etc.)

  res.json({ received: true });
});

const PORT = process.env.PORT || 4242;
app.listen(PORT, () => console.log(`Stripe stub server listening on ${PORT}`));
