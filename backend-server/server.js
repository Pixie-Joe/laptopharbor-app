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
require('dotenv').config();

const app = express();
app.use(cors());
app.use(express.json());

const stripeSecret = process.env.STRIPE_SECRET_KEY;
if (!stripeSecret) {
  console.error('STRIPE_SECRET_KEY not set in environment. Exiting.');
  process.exit(1);
}

const stripe = Stripe(stripeSecret);

app.post('/create-payment-intent', async (req, res) => {
  try {
    const { amount, currency = 'usd' } = req.body;
    if (!amount || amount <= 0) {
      return res.status(400).json({ error: 'Invalid amount' });
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: Math.round(amount * 100), // amount in cents
      currency,
      // For test mode you can set metadata or description
      metadata: { integration_check: 'accept_a_payment' },
    });

    return res.json({ clientSecret: paymentIntent.client_secret });
  } catch (err) {
    console.error('create-payment-intent error', err);
    return res.status(500).json({ error: 'Internal error' });
  }
});

const PORT = process.env.PORT || 4242;
app.listen(PORT, () => console.log(`Stripe stub server listening on ${PORT}`));
