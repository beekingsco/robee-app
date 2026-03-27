# RoBee Reserve — Flutter App

Mobile app for the RoBee robotic hive assistant. Handles customer reserve/deposit flow, live camera inspection, and robot arm remote control.

## Quick Start

### Prerequisites
- Flutter SDK ≥ 3.19.0 (`flutter --version`)
- Dart ≥ 3.3.0
- Xcode 15+ (iOS) or Android Studio / SDK 34+ (Android)

### 1. Install dependencies
```bash
flutter pub get
```

### 2. Set environment variables

Copy and fill in `.env` (never commit this):
```bash
cp .env.example .env
```

Or pass via `--dart-define` when running:
```bash
flutter run \
  --dart-define=SUPABASE_URL=https://xxx.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJ... \
  --dart-define=STRIPE_PUBLISHABLE_KEY=pk_live_... \
  --dart-define=MOCK_ARM=true
```

### 3. Run
```bash
# Debug on connected device
flutter run

# iOS simulator
flutter run -d "iPhone 15"

# Android emulator
flutter run -d emulator-5554
```

### 4. Build release
```bash
# iOS
flutter build ios --release

# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release
```

---

## Project Structure

```
lib/
├── main.dart                   # App entry point, theme, Supabase + Stripe init
├── config/
│   ├── app_config.dart         # Environment constants, feature flags
│   └── router.dart             # GoRouter route definitions
├── models/
│   ├── profile.dart            # User profile (mirrors Axon schema)
│   ├── reserve.dart            # Reserve record (mirrors Axon schema)
│   └── arm_telemetry.dart      # Telemetry + ArmCommand models
├── services/
│   ├── camera_service.dart     # Camera preview, capture, recording
│   ├── arm_driver_stub.dart    # WebSocket arm driver + mock mode (10 Hz)
│   ├── network_service.dart    # Dio HTTP client + WS helpers
│   └── supabase_service.dart   # Auth, profiles, reserves, realtime
└── screens/
    ├── splash_screen.dart      # Auth redirect
    ├── home_screen.dart        # Dashboard
    ├── camera_screen.dart      # Full-screen camera with controls
    ├── arm_control_screen.dart # Live telemetry + command buttons
    ├── settings_screen.dart    # Connection config + user prefs
    └── reserve/
        ├── reserve_screen.dart # Reserve history
        └── deposit_screen.dart # $100 Stripe deposit flow
```

---

## Services

### CameraService
- `init()` — discovers cameras and initialises the controller
- `takePicture()` → `File?` — JPEG still capture
- `startRecording()` / `stopRecording()` → `File?` — MP4 video
- `toggleCamera()` — flip front/back
- `setFlash(FlashMode)` — control flash/torch
- `setZoom(double)` — zoom level

### ArmDriverStub
- Connects via WebSocket to the arm controller (or mock mode locally)
- Emits `ArmTelemetry` on `telemetryStream` at ~10 Hz
- `home()`, `stop()`, `setGripper(pct)`, `sendCommand(ArmCommand)`
- Auto-reconnects up to 10 times on disconnect

### NetworkService
- Dio client with logging + retry-on-5xx interceptors
- `get/post/patch` helpers
- `openWebSocket(url)` — returns raw `WebSocketChannel`
- Connectivity monitoring via `connectivityStream`

### SupabaseService
- `signUp / signIn / signOut / resetPassword`
- `getProfile() / updateProfile()`
- `getMyReserves() / createReserve() / attachStripeSession()`
- `subscribeToReserves()` / `subscribeTelemetry()` — realtime listeners

---

## Deposit Flow (TODO to complete)

1. User taps **Reserve for $100** → `DepositScreen`
2. App calls `SupabaseService.createReserve()` → row in `reserves` table
3. App calls backend `POST /api/create-checkout-session` (implement in Supabase Edge Function or separate server)
4. Backend creates Stripe Checkout Session, returns `{ url, session_id, expires_at }`
5. App calls `SupabaseService.attachStripeSession()` → updates reserve
6. App opens `checkoutUrl` via `url_launcher` or embedded WebView
7. Stripe redirects to `robee://payment-return?session_id=...`
8. Stripe webhook on backend sets `reserve.status = 'paid'`, updates `profile.deposit_status`
9. Realtime subscription notifies app → shows success UI

**Supabase Edge Function needed:** `functions/create-checkout-session/index.ts`

---

## Environment Variables

| Variable | Description |
|---|---|
| `SUPABASE_URL` | Your Supabase project URL |
| `SUPABASE_ANON_KEY` | Supabase anon public key |
| `STRIPE_PUBLISHABLE_KEY` | Stripe publishable key (pk_live_... or pk_test_...) |
| `MOCK_ARM` | `true` to use simulated arm, `false` for real WebSocket |
| `ENABLE_ARM` | `true` to show arm control UI |

---

## Next Steps (Volt Sprint Backlog)

- [ ] Implement `url_launcher` for Stripe checkout redirect
- [ ] Supabase Edge Function: `create-checkout-session`
- [ ] Supabase Edge Function: `stripe-webhook` (marks reserve paid)
- [ ] Arm 3D visualiser widget (joints → FK preview)
- [ ] Telemetry history chart (fl_chart)
- [ ] Push notifications (FCM + APNs) for deposit confirmation
- [ ] Onboarding flow (first-launch tour)
- [ ] Profile photo upload to Supabase Storage
- [ ] Unit tests for services
- [ ] CI/CD (GitHub Actions → TestFlight + Play Internal)
