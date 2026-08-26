# LaptopHarbor

LaptopHarbor is a Flutter e-commerce MVP for browsing laptops, saving favorites, managing a cart, checking out, and tracking orders. The app is built to work as a local prototype and includes a Stripe-ready payment flow with a local backend stub for development.

## Features included

- User signup, login, and password reset flow
- Secure local session storage using Flutter Secure Storage
- PBKDF2-based password hashing for local MVP auth
- Product catalog with category, brand, and price filtering
- Wishlist and cart persistence across app restarts
- Guest cart/wishlist migration to an authenticated user
- Address management for shipping
- Checkout flow with Stripe-ready PaymentIntent scaffolding and fallback payment stub
- Order placement and order history
- Local SQLite database storage for app entities
- CI workflow for Flutter analysis and tests

## Tech stack

- Flutter
- SQLite via sqflite
- Shared/local persistence
- Stripe test-mode client/backend scaffolding
- Node.js Express payment server for local testing

## Requirements

- Flutter SDK 3.10+ recommended
- Android Studio / Xcode for mobile emulators
- Node.js 18+ for the local Stripe test backend
- A Stripe test publishable key for payment UI testing

## Quick start

1. Clone the project
   ```bash
   git clone <your-repo-url>
   cd project-mvp-analysis-report
   ```

2. Install Flutter dependencies
   ```bash
   flutter pub get
   ```

3. Start the Flutter app
   ```bash
   flutter run --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_your_key_here
   ```

   If you do not provide a Stripe publishable key, the app will still launch and fall back to the stubbed payment flow.

## Local Stripe payment server

The project includes a local backend server for payment intent creation.

1. Open the backend folder
   ```bash
   cd backend-server
   ```

2. Install server dependencies
   ```bash
   npm install
   ```

3. Copy the sample env file and add your test secret key (optional)
   ```bash
   copy .env.example .env
   ```
   Then edit `.env` and set if you have them:
   ```env
   STRIPE_SECRET_KEY=sk_test_your_key_here    # optional for local stub mode
   STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret  # optional for verified webhooks
   PORT=4242
   ```

4. Start the local payment server
   ```bash
   npm start
   ```

5. Run the Flutter app using the corresponding publishable key
   ```bash
   flutter run --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_your_key_here --dart-define=API_BASE_URL=http://10.0.2.2:4242
   ```

Network notes

- Android emulator: use `10.0.2.2` to reach the host machine (e.g., `http://10.0.2.2:4242`).
- iOS simulator / local web: use `http://localhost:4242`.

Webhook & verification (important)

- For local development the server supports two modes:
  - Unverified (stub) mode: leave `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` unset. The server will return a stubbed PaymentIntent and will accept unverified webhook JSON POSTs for local testing and smoke tests.
  - Verified (Stripe) mode: set `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET`. In this mode the server must verify webhook signatures using Stripe's `stripe-signature` header.

- Technical detail: webhook signature verification requires the server to receive the raw HTTP body (a Buffer). The server now uses a route-specific approach: JSON parsing is applied to all routes except `/webhook`, which receives the raw body so `stripe.webhooks.constructEvent` can verify signatures. This means:
  - Do NOT add global body-parsing middleware that consumes the request body before `/webhook` when deploying a verified server.
  - When testing locally with `STRIPE_WEBHOOK_SECRET` set, use a tunneling tool (ngrok or similar) so Stripe can reach your dev server, or use Stripe CLI to forward webhooks.

Running smoke tests (local)

- A simple smoke test has been added to validate create-intent + webhook reconciliation. To run it locally:
  1. Start the server (no secrets required to run the stub):
     ```bash
     npm start
     ```
  2. In another terminal run:
     ```bash
     node smoke-test-webhook.js
     ```
  The script will create an intent, post a simulated `payment_intent.succeeded` webhook, and verify the server's idempotency store was updated to mark the order as paid.

Notes about production hardening

- The file-backed `idempotency.json` store is intended only for local dev and smoke tests. For production, replace it with a durable datastore (SQLite, Postgres, etc.) and add TTL/cleanup policies.
- Move authentication to a server-side flow and use secure server-issued tokens (JWT with refresh or server session) in production.

Recent change (what was just committed)

- Commit: d5a1702 — "backend-server: handle webhook raw body and reconcile payment intents"
  - Attach `order_id` to PaymentIntent metadata so webhooks can reconcile orders.
  - Add `reconcilePaymentIntent` helper to mark idempotency entries as paid on `payment_intent.succeeded`.
  - Use route-specific raw parsing for `/webhook` to allow signature verification while keeping JSON parsing for other routes.
  - Add `smoke-test-webhook.js` to validate create-intent + webhook reconciliation.

If you want these README changes modified (formatting, additional CI run examples, or a dedicated `backend-server/README.md`), say so and I'll update accordingly.

## How to use the app

### Sign up and log in

- Open the app and sign up with a name, email, and password.
- Passwords are hashed locally with PBKDF2 before being stored in SQLite.
- The app stores the active session securely in encrypted local storage.

### Browse products

- View products on the home screen.
- Filter by category, brand, price, and specs.
- Save items to the wishlist.

### Cart and checkout

- Add items to the cart from product cards or detail pages.
- Adjust quantities or remove items from the cart screen.
- Proceed to checkout, select or edit the shipping address, and complete the order.
- Orders are saved to SQLite and appear in the order history section.

### Address management

- Add, edit, and delete saved shipping addresses.
- Mark an address as default when needed.

### Notifications and order tracking

- After placing an order, a success notification is shown.
- Recent order data can be reviewed in the order history screen.

### Payment flow

- If a Stripe publishable key is configured, the client attempts a PaymentSheet flow using the local server.
- If payment setup fails or the key is absent, the app falls back to the local stubbed payment flow so the checkout experience still runs in development mode.

## Useful project files

- `lib/main.dart` — app bootstrap and Stripe key initialization
- `lib/backend/db/db_helper.dart` — SQLite schema and database setup
- `lib/backend/services/user_service.dart` — auth, session, and password reset logic
- `lib/backend/storage/session_manager.dart` — secure session persistence
- `lib/backend/services/payment_service.dart` — payment stub logic
- `backend-server/server.js` — local Stripe PaymentIntent backend
- `.github/workflows/flutter-ci.yml` — CI pipeline for Flutter analysis and tests
- `RELEASE_CHECKLIST.md` — release and signing guidance

## Validation

Run the existing validation commands locally:

```bash
flutter analyze
flutter test
```

## Important note

This app is intentionally scoped as an MVP. For a production deployment, you should add server-side auth, stronger production secrets management, secure webhook verification, and real Stripe live-mode setup.
