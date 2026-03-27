import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../config/app_config.dart';
import 'package:logger/logger.dart';

/// Deposit screen — initiates the \$100 Stripe Checkout flow.
///
/// Flow:
/// 1. Create a reserve record in Supabase (status = pending)
/// 2. Call backend /api/create-checkout-session → returns { url, session_id }
/// 3. Update reserve with session_id (status = awaiting_payment)
/// 4. Open Stripe checkout URL in WebView / browser
/// 5. Webhook on server updates status to 'paid'
class DepositScreen extends StatefulWidget {
  const DepositScreen({super.key});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  static final _log = Logger(printer: SimplePrinter());
  final _svc = SupabaseService();
  bool _loading = false;
  String? _error;
  bool _done = false;

  Future<void> _startDeposit() async {
    setState(() { _loading = true; _error = null; });

    try {
      // 1. Create reserve record
      final reserve = await _svc.createReserve(
        productSku: AppConfig.depositProductSku,
        productName: AppConfig.depositProductName,
        depositAmountCents: AppConfig.depositAmountCents,
      );

      if (reserve == null) throw Exception('Failed to create reserve');

      // 2. TODO: Call your backend to create a Stripe checkout session.
      //    Replace the placeholder below with a real API call:
      //
      //    final resp = await _network.post('/api/checkout', body: {
      //      'reserve_id': reserve.id,
      //      'amount': AppConfig.depositAmountCents,
      //      'currency': AppConfig.depositCurrency,
      //      'success_url': 'https://robeego.com/reserve/success',
      //      'cancel_url': 'https://robeego.com/reserve/cancel',
      //    });
      //    final checkoutUrl = resp['url'] as String;
      //    final sessionId = resp['session_id'] as String;
      //
      //    For now we simulate:
      const checkoutUrl = 'https://buy.stripe.com/placeholder';
      const sessionId = 'cs_test_placeholder';

      // 3. Update reserve with Stripe session
      await _svc.attachStripeSession(
        reserveId: reserve.id,
        sessionId: sessionId,
        checkoutUrl: checkoutUrl,
        expiresAt: DateTime.now().add(const Duration(hours: 24)),
      );

      // 4. Open Stripe checkout
      //    In production: use url_launcher or a WebView
      //    await launchUrl(Uri.parse(checkoutUrl));

      _log.i('Deposit flow started: reserve=${reserve.id} session=$sessionId');
      setState(() { _done = true; });
    } catch (e) {
      _log.e('Deposit error: $e');
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (_done) return _SuccessView(onContinue: () => context.go('/home'));

    return Scaffold(
      appBar: AppBar(title: const Text('Reserve Your RoBee')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.hive_rounded, size: 80, color: cs.primary),
                    const SizedBox(height: 24),
                    Text('RoBee Reserve',
                        style: Theme.of(context).textTheme.headlineMedium,
                        textAlign: TextAlign.center),
                    const SizedBox(height: 16),

                    // Value props
                    ...[
                      ('🐝', 'First production run unit'),
                      ('🔒', '\$100 fully refundable deposit'),
                      ('📦', 'Spring 2026 delivery'),
                      ('⚡', 'Priority support & early access'),
                    ].map((e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Text(e.$1, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Text(e.$2,
                              style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                    )),
                  ],
                ),
              ),

              // Error
              if (_error != null) ...[
                Text(_error!,
                    style: TextStyle(color: cs.error),
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
              ],

              // Price badge
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Refundable Deposit',
                              style: Theme.of(context).textTheme.labelMedium),
                          Text('\$100 USD',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(color: cs.primary)),
                        ],
                      ),
                    ),
                    Icon(Icons.verified_outlined, color: cs.primary, size: 32),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              FilledButton.icon(
                onPressed: _loading ? null : _startDeposit,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.lock_outlined),
                label: Text(_loading ? 'Processing…' : 'Pay \$100 Deposit via Stripe'),
              ),
              const SizedBox(height: 12),
              Text(
                'Powered by Stripe. Fully refundable if RoBee doesn\'t ship.',
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  final VoidCallback onContinue;
  const _SuccessView({required this.onContinue});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.check_circle_rounded, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              Text("You're on the list!",
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                'Complete your \$100 deposit via the Stripe link. '
                'We\'ll email you your confirmation.',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 40),
              FilledButton(
                onPressed: onContinue,
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
