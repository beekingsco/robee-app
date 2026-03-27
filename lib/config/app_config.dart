/// AppConfig — centralised environment configuration for RoBee app.
/// Replace placeholder values with real keys before deploying.
library app_config;

class AppConfig {
  AppConfig._();

  // ── Supabase ────────────────────────────────────────────────────────────────
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://your-project.supabase.co',
  );
  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'your-anon-key',
  );

  // ── Stripe ──────────────────────────────────────────────────────────────────
  static const stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_placeholder',
  );
  /// Amount in cents for the refundable deposit
  static const depositAmountCents = 10000; // $100 USD
  static const depositCurrency = 'usd';
  static const depositProductSku = 'ROBEE-RESERVE-001';
  static const depositProductName = 'RoBee Reserve Deposit';

  // ── Robot Arm WebSocket ──────────────────────────────────────────────────────
  static const defaultArmWsUrl = 'ws://robee.local:8765/arm';
  static const wsReconnectDelayMs = 3000;
  static const wsMaxReconnectAttempts = 10;

  // ── App Identity ────────────────────────────────────────────────────────────
  static const appName = 'RoBee Reserve';
  static const appVersion = '0.1.0';
  static const supportEmail = 'support@robeego.com';
  static const reserveUrl = 'https://fantasticbees.com/robee-reserve';

  // ── Feature flags ────────────────────────────────────────────────────────────
  static const enableArmControl = bool.fromEnvironment('ENABLE_ARM', defaultValue: false);
  static const enableMockArm = bool.fromEnvironment('MOCK_ARM', defaultValue: true);
}
