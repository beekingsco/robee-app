import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/trailer.dart';
import '../services/mock_data.dart';
import '../services/supabase_service.dart';
import '../theme/robee_theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/slide_to_confirm.dart';

class TrailerSettingsScreen extends StatefulWidget {
  final String trailerId;

  const TrailerSettingsScreen({super.key, required this.trailerId});

  @override
  State<TrailerSettingsScreen> createState() => _TrailerSettingsScreenState();
}

class _TrailerSettingsScreenState extends State<TrailerSettingsScreen> {
  Trailer? _trailer;
  bool _loading = true;
  bool _saving = false;

  // Form controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _shareEmailCtrl;

  // Form state
  String _inspectionFrequency = 'daily';
  String _tempUnit = 'F';
  String _weightUnit = 'lbs';
  List<String> _sharedWith = [];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _shareEmailCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _shareEmailCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    Trailer? t;
    try {
      final svc = SupabaseService();
      if (svc.isSignedIn) {
        final trailers = await svc.getTrailers();
        final match = trailers.where((x) => x.id == widget.trailerId);
        if (match.isNotEmpty) t = match.first;
      }
    } catch (_) {}

    if (t == null) {
      final match = MockData.trailers.where((x) => x.id == widget.trailerId);
      t = match.isNotEmpty
          ? match.first
          : (MockData.trailers.isNotEmpty ? MockData.trailers.first : null);
    }

    if (t != null && mounted) {
      setState(() {
        _trailer = t;
        _nameCtrl.text = t!.name;
        _addressCtrl.text = t.address ?? '';
        _inspectionFrequency = t.inspectionFrequency;
        _tempUnit = t.tempUnit;
        _weightUnit = t.weightUnit;
        _sharedWith = List<String>.from(t.sharedWith);
        _loading = false;
      });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    if (_trailer == null) return;
    setState(() => _saving = true);
    try {
      final updated = _trailer!.copyWith(
        name: _nameCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        inspectionFrequency: _inspectionFrequency,
        tempUnit: _tempUnit,
        weightUnit: _weightUnit,
        sharedWith: _sharedWith,
      );
      final svc = SupabaseService();
      if (svc.isSignedIn) {
        await svc.updateTrailer(updated);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _addShareEmail() {
    final email = _shareEmailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) return;
    if (_sharedWith.contains(email)) return;
    setState(() {
      _sharedWith = [..._sharedWith, email];
      _shareEmailCtrl.clear();
    });
  }

  void _removeShareEmail(String email) {
    setState(() {
      _sharedWith = _sharedWith.where((e) => e != email).toList();
    });
  }

  void _archiveTrailer() async {
    if (_trailer == null) return;
    try {
      final svc = SupabaseService();
      if (svc.isSignedIn) {
        await svc.updateTrailer(_trailer!.copyWith(archived: true));
      }
      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error archiving: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RoBeeTheme.background,
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: RoBeeTheme.amber),
            )
          : SafeArea(
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: GlassCard(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => context.pop(),
                            child: const Icon(
                              Icons.arrow_back_ios_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Trailer Settings',
                              style: RoBeeTheme.headlineLarge,
                            ),
                          ),
                          if (_saving)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: RoBeeTheme.amber,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── General Settings ─────────────────────────────
                          _SectionHeader(label: 'GENERAL'),
                          const SizedBox(height: 10),
                          GlassCard(
                            child: Column(
                              children: [
                                _FormField(
                                  label: 'Trailer Name',
                                  controller: _nameCtrl,
                                  hint: 'e.g. Canton Demo',
                                ),
                                const SizedBox(height: 14),
                                _FormField(
                                  label: 'Address',
                                  controller: _addressCtrl,
                                  hint: 'e.g. 123 Honeybee Lane, Canton, GA',
                                ),
                                const SizedBox(height: 14),
                                _DropdownField<String>(
                                  label: 'Inspection Frequency',
                                  value: _inspectionFrequency,
                                  items: const ['daily', 'weekly', 'biweekly'],
                                  itemLabel: (v) =>
                                      v[0].toUpperCase() + v.substring(1),
                                  onChanged: (v) => setState(
                                      () => _inspectionFrequency = v!),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _DropdownField<String>(
                                        label: 'Temperature',
                                        value: _tempUnit,
                                        items: const ['F', 'C'],
                                        itemLabel: (v) => '°$v',
                                        onChanged: (v) =>
                                            setState(() => _tempUnit = v!),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _DropdownField<String>(
                                        label: 'Weight',
                                        value: _weightUnit,
                                        items: const ['lbs', 'kg'],
                                        itemLabel: (v) => v,
                                        onChanged: (v) =>
                                            setState(() => _weightUnit = v!),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Share Access ──────────────────────────────────
                          _SectionHeader(label: 'SHARE ACCESS'),
                          const SizedBox(height: 10),
                          GlassCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _shareEmailCtrl,
                                        keyboardType:
                                            TextInputType.emailAddress,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        decoration: const InputDecoration(
                                          hintText: 'Enter email address',
                                          contentPadding: EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    TextButton(
                                      onPressed: _addShareEmail,
                                      style: TextButton.styleFrom(
                                        foregroundColor: RoBeeTheme.amber,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                          side: const BorderSide(
                                              color: RoBeeTheme.amber),
                                        ),
                                      ),
                                      child: const Text(
                                        'Add',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_sharedWith.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  const Divider(
                                      color: RoBeeTheme.border,
                                      height: 1),
                                  const SizedBox(height: 8),
                                  ..._sharedWith.map(
                                    (email) => _SharedEmailRow(
                                      email: email,
                                      onRemove: () =>
                                          _removeShareEmail(email),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Save Button ───────────────────────────────────
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: RoBeeTheme.amber,
                                foregroundColor: RoBeeTheme.background,
                                minimumSize: const Size(0, 52),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Save Settings',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Danger Zone ───────────────────────────────────
                          _SectionHeader(label: 'DANGER ZONE'),
                          const SizedBox(height: 10),
                          GlassCard(
                            borderColor: RoBeeTheme.healthRed.withOpacity(0.3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Archive Trailer',
                                  style: TextStyle(
                                    color: RoBeeTheme.healthRed,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'This will hide the trailer from your dashboard. '
                                  'All data is preserved and can be restored.',
                                  style: RoBeeTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                                SlideToConfirm(
                                  label: 'SLIDE TO ARCHIVE',
                                  color: RoBeeTheme.healthRed,
                                  onConfirm: _archiveTrailer,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Supporting Widgets ─────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: RoBeeTheme.labelLarge.copyWith(letterSpacing: 2),
    );
  }
}

class _FormField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String hint;

  const _FormField({
    required this.label,
    required this.controller,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: RoBeeTheme.bodyMedium),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: RoBeeTheme.bodyMedium),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: RoBeeTheme.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: RoBeeTheme.border),
          ),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            dropdownColor: const Color(0xFF1A1714),
            underline: const SizedBox(),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            icon: const Icon(Icons.keyboard_arrow_down,
                color: RoBeeTheme.glassWhite60),
            items: items
                .map(
                  (item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(itemLabel(item)),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _SharedEmailRow extends StatelessWidget {
  final String email;
  final VoidCallback onRemove;

  const _SharedEmailRow({required this.email, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.person_outline,
              size: 16, color: RoBeeTheme.glassWhite60),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              email,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: RoBeeTheme.healthRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.close,
                  size: 14, color: RoBeeTheme.healthRed),
            ),
          ),
        ],
      ),
    );
  }
}
