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

3. Copy the sample env file and add your test secret key
   ```bash
   copy .env.example .env
   ```
   Then edit `.env` and set:
   ```env
   STRIPE_SECRET_KEY=sk_test_your_key_here
   PORT=4242
   ```

4. Start the local payment server
   ```bash
   npm start
   ```

5. Run the Flutter app using the corresponding publishable key
   ```bash
   flutter run --dart-define=STRIPE_PUBLISHABLE_KEY=pk_test_your_key_here
   ```

The app calls the local server at `http://10.0.2.2:4242/create-payment-intent` on Android emulators, and `http://localhost:4242/create-payment-intent` on a local web or iOS simulator setup.

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
