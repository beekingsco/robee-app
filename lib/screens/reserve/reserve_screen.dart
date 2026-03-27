import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import '../../models/reserve.dart';

/// Shows the user's reserve history and status.
class ReserveScreen extends StatefulWidget {
  const ReserveScreen({super.key});

  @override
  State<ReserveScreen> createState() => _ReserveScreenState();
}

class _ReserveScreenState extends State<ReserveScreen> {
  final _svc = SupabaseService();
  List<Reserve>? _reserves;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await _svc.getMyReserves();
      setState(() { _reserves = r; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('My Reserve')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _reserves == null || _reserves!.isEmpty
                  ? _EmptyState(onReserve: () => context.push('/reserve/deposit'))
                  : _ReserveList(reserves: _reserves!),
      floatingActionButton: (_reserves?.isEmpty ?? true) ? null :
        FloatingActionButton.extended(
          onPressed: () => context.push('/reserve/deposit'),
          label: const Text('Add Reserve'),
          icon: const Icon(Icons.add),
        ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onReserve;
  const _EmptyState({required this.onReserve});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hive_outlined, size: 80, color: cs.outlineVariant),
            const SizedBox(height: 24),
            Text('No reserves yet',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Secure your spot in the first RoBee production run '
              'with a \$100 fully refundable deposit.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onReserve,
              icon: const Icon(Icons.lock_outlined),
              label: const Text('Reserve for \$100'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReserveList extends StatelessWidget {
  final List<Reserve> reserves;
  const _ReserveList({required this.reserves});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: reserves.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _ReserveCard(reserve: reserves[i]),
    );
  }
}

class _ReserveCard extends StatelessWidget {
  final Reserve reserve;
  const _ReserveCard({required this.reserve});

  Color _statusColor(BuildContext context, ReserveStatus s) {
    final cs = Theme.of(context).colorScheme;
    switch (s) {
      case ReserveStatus.paid: return Colors.green;
      case ReserveStatus.awaitingPayment: return Colors.orange;
      case ReserveStatus.cancelled:
      case ReserveStatus.refunded: return cs.error;
      case ReserveStatus.fulfilled: return cs.primary;
      default: return cs.outlineVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(reserve.productName,
                      style: Theme.of(context).textTheme.titleSmall),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(context, reserve.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    reserve.status.value.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: _statusColor(context, reserve.status),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Deposit: \$${reserve.depositAmountDollars.toStringAsFixed(0)} ${reserve.currency.toUpperCase()}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Reserved: ${_fmt(reserve.createdAt)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
