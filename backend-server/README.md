Stripe PaymentIntent stub server

This folder contains a minimal Node/Express server that creates Stripe PaymentIntents in test mode. It's intended for local development and testing with the Flutter client.

Quick start
1. Install dependencies:
   npm install

2. Copy the example env file and set your test secret key:
   cp .env.example .env
   # Edit .env and set STRIPE_SECRET_KEY=sk_test_...

3. Start the server:
   npm start

Default behaviour
- Server listens on the PORT in .env (default 4242).
- POST /create-payment-intent expects a JSON body: { amount: number, currency?: string }
  - amount is in the smallest currency unit (e.g., cents for USD) if you use the provided client example.
  - Returns: { clientSecret }

Testing from the Flutter app
- On Android emulator use http://10.0.2.2:4242/create-payment-intent to reach the host machine.
- On iOS simulator use http://localhost:4242/create-payment-intent.
- Ensure your Flutter app is launched with the publishable key set as a Dart define, e.g.:
  flutter run --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_...

Using Stripe CLI to test webhooks (optional)
1. Install Stripe CLI: https://stripe.com/docs/stripe-cli
2. Log in and forward events to your local server (replace PORT if different):
   stripe listen --forward-to localhost:4242/webhook
3. The CLI prints a webhook signing secret; if you want to verify signatures set STRIPE_WEBHOOK_SECRET in your .env.
4. When testing a payment, you can trigger events with:
   stripe trigger payment_intent.succeeded

Security notes
- NEVER commit your STRIPE_SECRET_KEY or .env to source control.
- This stub is for development only. For production, implement strong server-side verification, idempotency, secure storage of keys, and webhook signature verification.

Troubleshooting
- If the Flutter client reports a CORS or network error when calling /create-payment-intent, confirm the server is running and reachable from the device/emulator. Use curl or Postman to exercise the endpoint directly.
- If PaymentSheet fails to initialize, check that the backend returned a clientSecret and that the publishable key provided to the app matches your test account.

Example curl call
  curl -X POST http://localhost:4242/create-payment-intent -H "Content-Type: application/json" -d '{"amount": 1999, "currency":"usd"}'

If you want, I can also add a small npm script to run stripe CLI listen automatically (non-sensitive), or add a minimal webhook endpoint to server.js that optionally verifies events if STRIPE_WEBHOOK_SECRET is set.
