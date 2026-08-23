Stripe PaymentIntent stub server

This folder contains a minimal Node/Express server that creates Stripe PaymentIntents in test mode.

Setup
1. Install dependencies:
   npm install

2. Create a .env file with your Stripe secret test key:
   STRIPE_SECRET_KEY=sk_test_...

3. Start the server:
   npm start

Endpoints
- POST /create-payment-intent
  body: { amount: number, currency?: string }
  returns: { clientSecret }

Security
- Do not commit your .env file or secret keys to source control.
- Use this server only for local development or as an example for building your own secure backend.
