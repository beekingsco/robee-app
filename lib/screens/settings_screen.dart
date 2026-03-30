import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';
import '../theme/robee_theme.dart';
import '../widgets/glass_card.dart';

/// Settings screen — Tesla instrument panel style.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _armUrlCtrl = TextEditingController();
  bool _mockArmEnabled = true;
  bool _loading = true;

  static const _keyArmUrl = 'pref_arm_ws_url';
  static const _keyMockArm = 'pref_mock_arm';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _armUrlCtrl.text =
          prefs.getString(_keyArmUrl) ?? AppConfig.defaultArmWsUrl;
      _mockArmEnabled = prefs.getBool(_keyMockArm) ?? true;
      _loading = false;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyArmUrl, _armUrlCtrl.text.trim());
    await prefs.setBool(_keyMockArm, _mockArmEnabled);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'SETTINGS SAVED',
            style: RoBeeTheme.monoSmall.copyWith(
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
          backgroundColor: RoBeeTheme.panel,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: RoBeeTheme.amber, width: 1),
          ),
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) context.go('/login');
  }

  @override
  void dispose() {
    _armUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (_loading) {
      return const Scaffold(
        backgroundColor: RoBeeTheme.background,
        body: Center(
          child: CircularProgressIndicator(color: RoBeeTheme.amber),
        ),
      );
    }

    return Scaffold(
      backgroundColor: RoBeeTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const Icon(
                      Icons.arrow_back_ios_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('SETTINGS', style: RoBeeTheme.displayMedium),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Body ───────────────────────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // ── ACCOUNT section ──────────────────────────────────────
                  _SectionHeader('ACCOUNT'),
                  const SizedBox(height: 8),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _ProfileRow(user: user),
                        const Divider(
                            height: 1, color: RoBeeTheme.border),
                        _SettingsTile(
                          icon: Icons.logout_outlined,
                          label: 'SIGN OUT',
                          labelColor: RoBeeTheme.healthRed,
                          onTap: _signOut,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── ARM CONNECTION section ────────────────────────────────
                  _SectionHeader('ARM CONNECTION'),
                  const SizedBox(height: 8),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        // Mock mode toggle
                        _ToggleTile(
                          icon: Icons.memory_outlined,
                          label: 'MOCK MODE',
                          subtitle: 'SIMULATED ARM — NO HARDWARE REQUIRED',
                          value: _mockArmEnabled,
                          onChanged: (v) =>
                              setState(() => _mockArmEnabled = v),
                        ),
                        if (!_mockArmEnabled) ...[
                          const Divider(
                              height: 1, color: RoBeeTheme.border),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                            child: _WsUrlField(controller: _armUrlCtrl),
                          ),
                        ],
                        const Divider(height: 1, color: RoBeeTheme.border),
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton(
                              onPressed: _savePrefs,
                              child: const Text(
                                'SAVE CONNECTION SETTINGS',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── ABOUT section ─────────────────────────────────────────
                  _SectionHeader('ABOUT'),
                  const SizedBox(height: 8),
                  GlassCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _InfoTile(
                          icon: Icons.apps_outlined,
                          label: 'APP VERSION',
                          value: AppConfig.appVersion,
                        ),
                        const Divider(height: 1, color: RoBeeTheme.border),
                        _InfoTile(
                          icon: Icons.language_outlined,
                          label: 'WEBSITE',
                          value: AppConfig.reserveUrl,
                        ),
                        const Divider(height: 1, color: RoBeeTheme.border),
                        _InfoTile(
                          icon: Icons.mail_outline,
                          label: 'SUPPORT',
                          value: AppConfig.supportEmail,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Version footer ────────────────────────────────────────
                  Center(
                    child: Text(
                      'ROBEE v${AppConfig.appVersion}',
                      style: RoBeeTheme.monoSmall.copyWith(
                        fontSize: 10,
                        color: RoBeeTheme.glassWhite60.withOpacity(0.4),
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: RoBeeTheme.labelLarge.copyWith(
            color: RoBeeTheme.amber,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 24,
          height: 2,
          color: RoBeeTheme.amber,
        ),
      ],
    );
  }
}

// ── Profile Row ───────────────────────────────────────────────────────────────

class _ProfileRow extends StatelessWidget {
  final dynamic user;
  const _ProfileRow({this.user});

  @override
  Widget build(BuildContext context) {
    final name = (user?.userMetadata?['full_name'] as String?)
        ?? 'BEEKEEPER';
    final email = user?.email ?? '--';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'B';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: RoBeeTheme.amber.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(
                  color: RoBeeTheme.amber.withOpacity(0.3)),
            ),
            child: Center(
              child: Text(
                initial,
                style: const TextStyle(
                  color: RoBeeTheme.amber,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: RoBeeTheme.monoSmall.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Toggle Tile ───────────────────────────────────────────────────────────────

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: RoBeeTheme.glassWhite60, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: RoBeeTheme.labelSmall.copyWith(fontSize: 9),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: RoBeeTheme.amber,
            activeTrackColor: RoBeeTheme.amber.withOpacity(0.3),
            inactiveThumbColor: RoBeeTheme.glassWhite60,
            inactiveTrackColor: RoBeeTheme.border,
          ),
        ],
      ),
    );
  }
}

// ── Settings Tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? labelColor;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.labelColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon,
                color: labelColor ?? RoBeeTheme.glassWhite60,
                size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: labelColor ?? Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_outlined,
                color: RoBeeTheme.glassWhite60, size: 18),
          ],
        ),
      ),
    );
  }
}

// ── Info Tile ─────────────────────────────────────────────────────────────────

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: RoBeeTheme.glassWhite60, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Text(
            value,
            style: RoBeeTheme.monoSmall.copyWith(
              fontSize: 11,
              color: RoBeeTheme.glassWhite60,
            ),
          ),
        ],
      ),
    );
  }
}

// ── WS URL field ──────────────────────────────────────────────────────────────

class _WsUrlField extends StatelessWidget {
  final TextEditingController controller;
  const _WsUrlField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: RoBeeTheme.monoSmall.copyWith(
        color: Colors.white,
        fontSize: 12,
      ),
      decoration: InputDecoration(
        labelText: 'ARM WEBSOCKET URL',
        hintText: 'ws://robee.local:8765/arm',
        prefixIcon: const Icon(Icons.wifi_outlined, size: 18),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        labelStyle: RoBeeTheme.labelSmall,
        hintStyle: RoBeeTheme.monoSmall,
      ),
      keyboardType: TextInputType.url,
    );
  }
}
