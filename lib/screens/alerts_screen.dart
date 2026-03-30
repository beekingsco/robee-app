import 'package:flutter/material.dart';
import '../models/alert.dart';
import '../models/trailer.dart';
import '../services/mock_data.dart';
import '../services/supabase_service.dart';
import '../theme/robee_theme.dart';
import '../widgets/glass_card.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<RoBeeAlert> _alerts = [];
  List<Trailer> _trailers = [];
  String _filter = 'ALL';
  bool _loading = true;

  static const _filters = ['ALL', 'CRITICAL', 'WARNING', 'INFO', 'RESOLVED'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    List<RoBeeAlert> alerts = [];
    List<Trailer> trailers = [];
    try {
      final svc = SupabaseService();
      if (svc.isSignedIn) {
        alerts = await svc.getAlerts();
        trailers = await svc.getTrailers();
      }
    } catch (_) {}

    if (alerts.isEmpty) alerts = List.from(MockData.alerts);
    if (trailers.isEmpty) trailers = MockData.trailers;

    // Priority sort: CRITICAL -> WARNING -> INFO -> resolved
    alerts.sort((a, b) {
      if (a.isResolved != b.isResolved) return a.isResolved ? 1 : -1;
      const order = {'critical': 0, 'warning': 1, 'info': 2};
      return (order[a.severity] ?? 3).compareTo(order[b.severity] ?? 3);
    });

    if (mounted) {
      setState(() {
        _alerts = alerts;
        _trailers = trailers;
        _loading = false;
      });
    }
  }

  List<RoBeeAlert> get _filtered {
    switch (_filter) {
      case 'CRITICAL':
        return _alerts
            .where((a) => a.severity == 'critical' && !a.isResolved)
            .toList();
      case 'WARNING':
        return _alerts
            .where((a) => a.severity == 'warning' && !a.isResolved)
            .toList();
      case 'INFO':
        return _alerts
            .where((a) => a.severity == 'info' && !a.isResolved)
            .toList();
      case 'RESOLVED':
        return _alerts.where((a) => a.isResolved).toList();
      default:
        return _alerts;
    }
  }

  void _resolve(RoBeeAlert alert) {
    setState(() {
      final idx = _alerts.indexWhere((a) => a.id == alert.id);
      if (idx >= 0) {
        _alerts[idx] = alert.copyWith(
          isResolved: true,
          resolvedAt: DateTime.now(),
        );
      }
    });
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return RoBeeTheme.healthRed;
      case 'warning':
        return RoBeeTheme.healthYellow;
      default:
        return const Color(0xFF60A5FA);
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity) {
      case 'critical':
        return Icons.error_outline;
      case 'warning':
        return Icons.warning_amber_outlined;
      default:
        return Icons.info_outline;
    }
  }

  int get _unresolvedCount => _alerts.where((a) => !a.isResolved).length;

  int _countForFilter(String f) {
    switch (f) {
      case 'ALL':
        return _alerts.where((a) => !a.isResolved).length;
      case 'CRITICAL':
        return _alerts
            .where((a) => a.severity == 'critical' && !a.isResolved)
            .length;
      case 'WARNING':
        return _alerts
            .where((a) => a.severity == 'warning' && !a.isResolved)
            .length;
      case 'INFO':
        return _alerts
            .where((a) => a.severity == 'info' && !a.isResolved)
            .length;
      case 'RESOLVED':
        return _alerts.where((a) => a.isResolved).length;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoBeeTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  const Text('ALERTS', style: RoBeeTheme.displayMedium),
                  const Spacer(),
                  if (_unresolvedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: RoBeeTheme.healthRed.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: RoBeeTheme.healthRed.withOpacity(0.3)),
                      ),
                      child: Text(
                        '$_unresolvedCount ACTIVE',
                        style: RoBeeTheme.monoSmall.copyWith(
                          color: RoBeeTheme.healthRed,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Filter chips ──────────────────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _filters.map((f) {
                  final selected = _filter == f;
                  final count = _countForFilter(f);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 0),
                        decoration: BoxDecoration(
                          color: selected
                              ? RoBeeTheme.amber.withOpacity(0.15)
                              : RoBeeTheme.panel,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: selected
                                ? RoBeeTheme.amber.withOpacity(0.4)
                                : RoBeeTheme.border,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          count > 0 ? '$f ($count)' : f,
                          style: TextStyle(
                            color: selected
                                ? RoBeeTheme.amber
                                : RoBeeTheme.glassWhite60,
                            fontSize: 11,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),

            // ── Content ───────────────────────────────────────────────────────
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: RoBeeTheme.amber))
                  : _filtered.isEmpty
                      ? _EmptyState(filter: _filter)
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            ..._filtered.map((alert) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildDismissible(alert),
                                )),
                            const SizedBox(height: 20),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissible(RoBeeAlert alert) {
    if (alert.isResolved) {
      return Opacity(
        opacity: 0.45,
        child: _AlertCard(
          alert: alert,
          severityColor: _severityColor(alert.severity),
          severityIcon: _severityIcon(alert.severity),
        ),
      );
    }

    return Dismissible(
      key: Key(alert.id),
      direction: DismissDirection.startToEnd,
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: RoBeeTheme.healthGreen.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: RoBeeTheme.healthGreen.withOpacity(0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline,
                color: RoBeeTheme.healthGreen, size: 20),
            const SizedBox(width: 8),
            Text(
              'RESOLVE',
              style: TextStyle(
                color: RoBeeTheme.healthGreen,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
      confirmDismiss: (_) async {
        _resolve(alert);
        return false;
      },
      child: _AlertCard(
        alert: alert,
        severityColor: _severityColor(alert.severity),
        severityIcon: _severityIcon(alert.severity),
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 48,
            color: RoBeeTheme.glassWhite20,
          ),
          const SizedBox(height: 20),
          Text(
            'NO ACTIVE ALERTS',
            style: RoBeeTheme.monoLarge.copyWith(
              fontSize: 16,
              color: RoBeeTheme.glassWhite60,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            filter == 'RESOLVED'
                ? 'NO RESOLVED ALERTS'
                : 'ALL SYSTEMS NOMINAL',
            style: RoBeeTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}

// ── Alert Card ────────────────────────────────────────────────────────────────

class _AlertCard extends StatelessWidget {
  final RoBeeAlert alert;
  final Color severityColor;
  final IconData severityIcon;

  const _AlertCard({
    required this.alert,
    required this.severityColor,
    required this.severityIcon,
  });

  String _fmtTimestamp(DateTime dt) {
    final y = dt.year.toString();
    final mo = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$y-$mo-$d $h:$m';
  }

  @override
  Widget build(BuildContext context) {
    final c = severityColor;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1A17),
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: c, width: 3),
          top: BorderSide(color: RoBeeTheme.border, width: 1),
          right: BorderSide(color: RoBeeTheme.border, width: 1),
          bottom: BorderSide(color: RoBeeTheme.border, width: 1),
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: c.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(severityIcon, color: c, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + severity badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: c.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border:
                            Border.all(color: c.withOpacity(0.3)),
                      ),
                      child: Text(
                        alert.severity.toUpperCase(),
                        style: TextStyle(
                          color: c,
                          fontSize: 9,
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  alert.message,
                  style: RoBeeTheme.bodyMedium.copyWith(fontSize: 12),
                ),
                const SizedBox(height: 8),
                // Timestamp row
                Row(
                  children: [
                    const Icon(Icons.access_time_outlined,
                        size: 11, color: RoBeeTheme.glassWhite60),
                    const SizedBox(width: 4),
                    Text(
                      _fmtTimestamp(alert.createdAt),
                      style: RoBeeTheme.monoSmall.copyWith(
                          fontSize: 10, letterSpacing: 0.5),
                    ),
                    if (alert.isResolved) ...[
                      const Spacer(),
                      const Icon(Icons.check_circle_outline,
                          size: 11, color: RoBeeTheme.healthGreen),
                      const SizedBox(width: 3),
                      Text(
                        'RESOLVED',
                        style: RoBeeTheme.monoSmall.copyWith(
                          color: RoBeeTheme.healthGreen,
                          fontSize: 10,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
