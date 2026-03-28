import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  String _filter = 'All';
  bool _loading = true;

  static const _filters = ['All', 'Critical', 'Warning', 'Info', 'Resolved'];

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
      case 'Critical':
        return _alerts
            .where((a) => a.severity == 'critical' && !a.isResolved)
            .toList();
      case 'Warning':
        return _alerts
            .where((a) => a.severity == 'warning' && !a.isResolved)
            .toList();
      case 'Info':
        return _alerts
            .where((a) => a.severity == 'info' && !a.isResolved)
            .toList();
      case 'Resolved':
        return _alerts.where((a) => a.isResolved).toList();
      default:
        return _alerts;
    }
  }

  Map<String, List<RoBeeAlert>> get _grouped {
    final groups = <String, List<RoBeeAlert>>{};
    // Sort: unresolved first, then resolved
    final sorted = [..._filtered];
    sorted.sort((a, b) {
      if (a.isResolved != b.isResolved) {
        return a.isResolved ? 1 : -1;
      }
      // Critical first within group
      const severityOrder = {'critical': 0, 'warning': 1, 'info': 2};
      return (severityOrder[a.severity] ?? 3)
          .compareTo(severityOrder[b.severity] ?? 3);
    });

    for (final alert in sorted) {
      final trailer = _trailers.firstWhere(
        (t) => t.id == alert.trailerId,
        orElse: () => Trailer(id: alert.trailerId, name: 'Unknown Trailer'),
      );
      groups.putIfAbsent(trailer.name, () => []).add(alert);
    }
    return groups;
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
        return const Color(0xFF60A5FA); // info blue
    }
  }

  IconData _severityIcon(String severity) {
    switch (severity) {
      case 'critical':
        return Icons.error_rounded; // octagon-ish
      case 'warning':
        return Icons.warning_amber_rounded; // triangle
      default:
        return Icons.info_rounded; // circle info
    }
  }

  int get _unresolvedCount => _alerts.where((a) => !a.isResolved).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoBeeTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(Icons.arrow_back_ios_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Text('ALERTS', style: RoBeeTheme.displayMedium),
                  const Spacer(),
                  if (_unresolvedCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: RoBeeTheme.healthRed.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: RoBeeTheme.healthRed.withOpacity(0.3)),
                      ),
                      child: Text(
                        '$_unresolvedCount active',
                        style: RoBeeTheme.monoSmall.copyWith(
                          color: RoBeeTheme.healthRed,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Filter chips
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
                    child: FilterChip(
                      label: Text(count > 0 ? '$f ($count)' : f),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: RoBeeTheme.amber.withOpacity(0.2),
                      checkmarkColor: RoBeeTheme.amber,
                      labelStyle: TextStyle(
                        color: selected ? RoBeeTheme.amber : Colors.white,
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      side: BorderSide(
                        color: selected
                            ? RoBeeTheme.amber.withOpacity(0.4)
                            : RoBeeTheme.glassWhite10,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),

            // Alerts list
            Expanded(
              child: _loading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: RoBeeTheme.amber))
                  : _grouped.isEmpty
                      ? _EmptyState(filter: _filter)
                      : ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          children: [
                            ..._grouped.entries.expand((entry) {
                              return [
                                // Section header
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    children: [
                                      Text(
                                        entry.key.toUpperCase(),
                                        style: RoBeeTheme.labelLarge.copyWith(
                                          color: Colors.white,
                                          letterSpacing: 2,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 1,
                                        height: 12,
                                        color: RoBeeTheme.glassWhite20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${entry.value.length} alert${entry.value.length > 1 ? 's' : ''}',
                                        style: RoBeeTheme.labelSmall,
                                      ),
                                    ],
                                  ),
                                ),
                                ...entry.value.map((alert) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 8),
                                      child: _buildDismissible(alert),
                                    )),
                              ];
                            }),
                            const SizedBox(height: 20),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  int _countForFilter(String f) {
    switch (f) {
      case 'All':
        return _alerts.where((a) => !a.isResolved).length;
      case 'Critical':
        return _alerts
            .where((a) => a.severity == 'critical' && !a.isResolved)
            .length;
      case 'Warning':
        return _alerts
            .where((a) => a.severity == 'warning' && !a.isResolved)
            .length;
      case 'Info':
        return _alerts
            .where((a) => a.severity == 'info' && !a.isResolved)
            .length;
      case 'Resolved':
        return _alerts.where((a) => a.isResolved).length;
      default:
        return 0;
    }
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
          color: RoBeeTheme.healthGreen.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: RoBeeTheme.healthGreen, size: 22),
            const SizedBox(width: 8),
            Text(
              'Resolve',
              style: TextStyle(
                color: RoBeeTheme.healthGreen,
                fontSize: 13,
                fontWeight: FontWeight.w600,
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

class _EmptyState extends StatelessWidget {
  final String filter;
  const _EmptyState({required this.filter});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🌿', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            filter == 'Resolved' ? 'No resolved alerts' : 'No alerts 🌿',
            style: RoBeeTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            filter == 'All'
                ? 'All your hives are healthy'
                : 'No ${filter.toLowerCase()} alerts',
            style: RoBeeTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final RoBeeAlert alert;
  final Color severityColor;
  final IconData severityIcon;

  const _AlertCard({
    required this.alert,
    required this.severityColor,
    required this.severityIcon,
  });

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    }
    return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
  }

  @override
  Widget build(BuildContext context) {
    final c = severityColor;
    return GlassCard(
      borderColor: c.withOpacity(0.25),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Severity icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: c.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(severityIcon, color: c, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        alert.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: c.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        alert.severity.toUpperCase(),
                        style: TextStyle(
                          color: c,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
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
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded,
                        size: 11, color: RoBeeTheme.glassWhite60),
                    const SizedBox(width: 4),
                    Text(
                      _timeAgo(alert.createdAt),
                      style:
                          RoBeeTheme.labelSmall.copyWith(fontSize: 10),
                    ),
                    if (alert.isResolved) ...[
                      const Spacer(),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 11, color: RoBeeTheme.healthGreen),
                          const SizedBox(width: 3),
                          Text(
                            'Resolved',
                            style: RoBeeTheme.labelSmall.copyWith(
                              color: RoBeeTheme.healthGreen,
                              fontSize: 10,
                            ),
                          ),
                        ],
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
