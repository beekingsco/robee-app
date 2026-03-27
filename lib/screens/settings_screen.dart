import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

/// Settings screen — connection config + user preferences.
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
      _armUrlCtrl.text = prefs.getString(_keyArmUrl) ?? AppConfig.defaultArmWsUrl;
      _mockArmEnabled = prefs.getBool(_keyMockArm) ?? true;
      _loading = false;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyArmUrl, _armUrlCtrl.text.trim());
    await prefs.setBool(_keyMockArm, _mockArmEnabled);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Settings saved')));
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
    final cs = Theme.of(context).colorScheme;

    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile section
          _SectionHeader('Account'),
          ListTile(
            leading: CircleAvatar(
              backgroundColor: cs.primaryContainer,
              child: Text(
                (user?.userMetadata?['full_name'] as String? ?? 'U')[0].toUpperCase(),
                style: TextStyle(color: cs.primary),
              ),
            ),
            title: Text(user?.userMetadata?['full_name'] as String? ?? 'Beekeeper'),
            subtitle: Text(user?.email ?? ''),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {}, // TODO: edit profile
          ),
          const Divider(),

          // Arm connection
          _SectionHeader('Robot Arm Connection'),
          SwitchListTile(
            title: const Text('Mock Mode'),
            subtitle: const Text('Use simulated arm data (no hardware needed)'),
            value: _mockArmEnabled,
            onChanged: (v) => setState(() => _mockArmEnabled = v),
          ),
          if (!_mockArmEnabled) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                controller: _armUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Arm WebSocket URL',
                  hintText: 'ws://robee.local:8765/arm',
                  prefixIcon: Icon(Icons.wifi),
                ),
                keyboardType: TextInputType.url,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: FilledButton.tonal(
              onPressed: _savePrefs,
              child: const Text('Save Connection Settings'),
            ),
          ),
          const Divider(height: 32),

          // App info
          _SectionHeader('About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            trailing: Text(AppConfig.appVersion,
                style: Theme.of(context).textTheme.bodySmall),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: const Text('Website'),
            subtitle: Text(AppConfig.reserveUrl),
            onTap: () {}, // TODO: url_launcher
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text('Support'),
            subtitle: Text(AppConfig.supportEmail),
            onTap: () {},
          ),
          const Divider(height: 32),

          // Sign out
          ListTile(
            leading: Icon(Icons.logout, color: cs.error),
            title: Text('Sign Out', style: TextStyle(color: cs.error)),
            onTap: _signOut,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
