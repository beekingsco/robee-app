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
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];
    return '${days[now.weekday - 1]}, ${months[now.month]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoBeeTheme.background,
      body: Stack(
        children: [
          // Full-bleed background image with gradient overlay
          Positioned.fill(
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x990C0A09),
                  Color(0xFF0C0A09),
                ],
                stops: [0.0, 0.45, 0.75],
              ).createShader(bounds),
              blendMode: BlendMode.darken,
              child: Image.network(
                'https://images.unsplash.com/photo-1587593810167-a84920ea0781?q=80&w=2070',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1A1208),
                ),
              ),
            ),
          ),
          // Additional dark gradient at bottom
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    RoBeeTheme.background,
                  ],
                  stops: [0.0, 0.4, 0.85],
                ),
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: RoBeeTheme.amber,
              backgroundColor: const Color(0xFF1A1714),
              onRefresh: _load,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row
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
                                        letterSpacing: 1,
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
                                  // Add trailer button
                                  GestureDetector(
                                    onTap: () => context.push('/register-trailer'),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: RoBeeTheme.amber.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: RoBeeTheme.amber.withOpacity(0.4),
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
                                            style: RoBeeTheme.labelLarge.copyWith(
                                              color: RoBeeTheme.amber,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () => context.push('/settings'),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: RoBeeTheme.glassWhite5,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                            color: RoBeeTheme.glassWhite10),
                                      ),
                                      child: const Icon(Icons.settings_outlined,
                                          color: RoBeeTheme.glassWhite60,
                                          size: 18),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Alerts banner
                          if (_unresolvedAlerts.isNotEmpty)
                            _AlertsBanner(
                              alerts: _unresolvedAlerts,
                              onTap: () => context.push('/alerts'),
                            ),

                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                'MY TRAILERS',
                                style: RoBeeTheme.labelLarge.copyWith(
                                    letterSpacing: 2),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: RoBeeTheme.amber.withOpacity(0.15),
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

                  // Trailer list
                  if (_loading)
                    const SliverFillRemaining(
                      child: Center(
                        child: CircularProgressIndicator(
                          color: RoBeeTheme.amber,
                        ),
                      ),
                    )
                  else if (_trailers.isEmpty)
                    SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.hive_rounded,
                                color: RoBeeTheme.glassWhite60.withOpacity(0.5),
                                size: 48),
                            const SizedBox(height: 16),
                            const Text('No trailers yet',
                                style: RoBeeTheme.headlineMedium),
                            const SizedBox(height: 8),
                            const Text(
                                'Add your first trailer to get started.',
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
                            padding: const EdgeInsets.only(bottom: 14),
                            child: TrailerCard(
                              trailer: _trailers[i],
                              alerts: _unresolvedAlerts
                                  .where((a) =>
                                      a.trailerId == _trailers[i].id)
                                  .toList(),
                              onTap: () => context
                                  .push('/trailers/${_trailers[i].id}'),
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
        ],
      ),
    );
  }
}

class _AlertsBanner extends StatelessWidget {
  final List<RoBeeAlert> alerts;
  final VoidCallback onTap;

  const _AlertsBanner({required this.alerts, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasCritical = alerts.any((a) => a.severity == 'critical');
    final criticalCount = alerts.where((a) => a.severity == 'critical').length;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: hasCritical
              ? RoBeeTheme.healthRed.withOpacity(0.1)
              : RoBeeTheme.healthYellow.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasCritical
                ? RoBeeTheme.healthRed.withOpacity(0.35)
                : RoBeeTheme.healthYellow.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              hasCritical ? Icons.warning_rounded : Icons.info_outline_rounded,
              color: hasCritical ? RoBeeTheme.healthRed : RoBeeTheme.healthYellow,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasCritical
                    ? '$criticalCount critical alert${criticalCount > 1 ? 's' : ''} need attention'
                    : '${alerts.length} active alert${alerts.length > 1 ? 's' : ''}',
                style: TextStyle(
                  color: hasCritical
                      ? RoBeeTheme.healthRed
                      : RoBeeTheme.healthYellow,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            // Badge
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: hasCritical
                    ? RoBeeTheme.healthRed
                    : RoBeeTheme.healthYellow,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${alerts.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right,
              color: hasCritical ? RoBeeTheme.healthRed : RoBeeTheme.healthYellow,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
