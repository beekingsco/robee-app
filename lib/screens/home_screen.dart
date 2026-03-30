import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/trailer.dart';
import '../models/alert.dart';
import '../services/mock_data.dart';
import '../services/supabase_service.dart';
import '../theme/robee_theme.dart';
import '../widgets/trailer_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Trailer> _trailers = [];
  List<RoBeeAlert> _unresolvedAlerts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final svc = SupabaseService();
      if (svc.isSignedIn) {
        final t = await svc.getTrailers();
        final a = await svc.getAlerts();
        if (mounted) {
          setState(() {
            _trailers = t.isEmpty ? MockData.trailers : t;
            _unresolvedAlerts = a.where((x) => !x.isResolved).toList();
            _loading = false;
          });
          return;
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _trailers = MockData.trailers;
        _unresolvedAlerts = MockData.unresolvedAlerts;
        _loading = false;
      });
    }
  }

  String _dateStr() {
    final now = DateTime.now();
    const months = [
      '',
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    return '${days[now.weekday - 1]}, ${months[now.month]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoBeeTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: RoBeeTheme.amber,
          backgroundColor: RoBeeTheme.panel,
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Header row ──────────────────────────────────────
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _dateStr(),
                                  style: RoBeeTheme.labelLarge.copyWith(
                                    color: RoBeeTheme.amber,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'My Apiaries',
                                  style: RoBeeTheme.displayMedium,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Row(
                            children: [
                              // Add trailer
                              GestureDetector(
                                onTap: () =>
                                    context.push('/register-trailer'),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color:
                                        RoBeeTheme.amber.withOpacity(0.12),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    border: Border.all(
                                      color:
                                          RoBeeTheme.amber.withOpacity(0.35),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.add_rounded,
                                          color: RoBeeTheme.amber, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Add Trailer',
                                        style:
                                            RoBeeTheme.labelLarge.copyWith(
                                          color: RoBeeTheme.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Alerts banner ───────────────────────────────────
                      if (_unresolvedAlerts.isNotEmpty) ...[
                        _AlertsBanner(
                          alerts: _unresolvedAlerts,
                          onTap: () => context.push('/alerts'),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // ── Section label ───────────────────────────────────
                      Row(
                        children: [
                          Text(
                            'MY TRAILERS',
                            style: RoBeeTheme.labelLarge,
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: RoBeeTheme.amber.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${_trailers.length}',
                              style: RoBeeTheme.monoSmall.copyWith(
                                color: RoBeeTheme.amber,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),

              // ── Trailer list ─────────────────────────────────────────────
              if (_loading)
                const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: RoBeeTheme.amber),
                  ),
                )
              else if (_trailers.isEmpty)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.hive_rounded,
                          color: RoBeeTheme.glassWhite60.withOpacity(0.4),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        const Text('No trailers yet',
                            style: RoBeeTheme.headlineMedium),
                        const SizedBox(height: 8),
                        const Text('Add your first trailer to get started.',
                            style: RoBeeTheme.bodyMedium),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () =>
                              context.push('/register-trailer'),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Trailer'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TrailerCard(
                          trailer: _trailers[i],
                          alerts: _unresolvedAlerts
                              .where(
                                  (a) => a.trailerId == _trailers[i].id)
                              .toList(),
                          onTap: () =>
                              context.push('/trailers/${_trailers[i].id}'),
                          onSettingsTap: () => context.push(
                              '/trailers/${_trailers[i].id}/settings'),
                        ),
                      ),
                      childCount: _trailers.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Alerts Banner ─────────────────────────────────────────────────────────────
class _AlertsBanner extends StatelessWidget {
  final List<RoBeeAlert> alerts;
  final VoidCallback onTap;

  const _AlertsBanner({required this.alerts, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasCritical = alerts.any((a) => a.severity == 'critical');
    final criticalCount =
        alerts.where((a) => a.severity == 'critical').length;
    final c = hasCritical ? RoBeeTheme.healthRed : RoBeeTheme.healthYellow;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: RoBeeTheme.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Icon(
              hasCritical
                  ? Icons.warning_rounded
                  : Icons.info_outline_rounded,
              color: c,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasCritical
                    ? '$criticalCount critical alert${criticalCount > 1 ? 's' : ''} need attention'
                    : '${alerts.length} active alert${alerts.length > 1 ? 's' : ''}',
                style: TextStyle(
                  color: c,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  '${alerts.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.chevron_right, color: c, size: 16),
          ],
        ),
      ),
    );
  }
}
