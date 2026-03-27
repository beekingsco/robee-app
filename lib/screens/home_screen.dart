import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Home screen — dashboard with camera and arm control quick-launch.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hive_rounded, color: cs.primary, size: 28),
            const SizedBox(width: 8),
            const Text('RoBee'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              Text(
                'Hello, ${user?.userMetadata?['full_name'] ?? 'Beekeeper'} 👋',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Your RoBee is ready.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),

              // Status card
              _StatusCard(),
              const SizedBox(height: 20),

              // Quick actions grid
              Text('Quick Actions',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              _QuickActionsGrid(),
              const SizedBox(height: 20),

              // Reserve CTA (shown if no active deposit)
              _ReserveCTA(),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('RoBee Status',
                      style: Theme.of(context).textTheme.labelLarge),
                  Text('Not connected — tap Arm Control to connect',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          )),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [
        _ActionCard(
          icon: Icons.videocam_rounded,
          label: 'Camera',
          subtitle: 'Live view & capture',
          onTap: () => context.push('/home/camera'),
        ),
        _ActionCard(
          icon: Icons.precision_manufacturing_rounded,
          label: 'Arm Control',
          subtitle: 'Move & command',
          onTap: () => context.push('/home/arm'),
        ),
        _ActionCard(
          icon: Icons.bookmark_added_rounded,
          label: 'My Reserve',
          subtitle: 'Deposit status',
          onTap: () => context.push('/reserve'),
        ),
        _ActionCard(
          icon: Icons.analytics_outlined,
          label: 'Telemetry',
          subtitle: 'Sensor data',
          onTap: () {}, // TODO: telemetry screen
        ),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: cs.primary, size: 32),
              const Spacer(),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              Text(subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      )),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReserveCTA extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Secure your RoBee',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 4),
                  Text('\$100 fully refundable deposit',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () => context.push('/reserve/deposit'),
              child: const Text('Reserve'),
            ),
          ],
        ),
      ),
    );
  }
}
