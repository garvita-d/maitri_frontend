import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:convert';

// Providers
import '../providers/app_providers.dart';

// Services
import '../app_router.dart';
import 'package:go_router/go_router.dart';

/// Settings screen for app configuration and data management
/// Features: Theme toggle, data export, account management, about info
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final authState = ref.watch(authProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Settings',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customize your experience',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withAlpha((157).round()),
                ),
          ),
          const SizedBox(height: 32),

          // Appearance
          _SettingsSection(
            title: 'Appearance',
            icon: Icons.palette,
            children: [
              _ThemeToggle(currentMode: themeMode),
            ],
          ),
          const SizedBox(height: 24),

          // Data & Privacy
          _SettingsSection(
            title: 'Data & Privacy',
            icon: Icons.security,
            children: [
              _ExportDataButton(),
              const SizedBox(height: 12),
              _ClearDataButton(),
            ],
          ),
          const SizedBox(height: 24),

          // Account
          if (authState == AuthState.authenticated)
            _SettingsSection(
              title: 'Account',
              icon: Icons.person,
              children: [
                _LogoutButton(),
              ],
            ),
          const SizedBox(height: 24),

          // About
          _AboutSection(),
        ],
      ),
    );
  }
}

// ============================================================================
// SETTINGS SECTION WRAPPER
// ============================================================================

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((11).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha((22).round()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.blue.shade400, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

// ============================================================================
// THEME TOGGLE
// ============================================================================

class _ThemeToggle extends ConsumerWidget {
  final ThemeMode currentMode;

  const _ThemeToggle({required this.currentMode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        const Text(
          'Theme',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const Spacer(),
        SegmentedButton<ThemeMode>(
          segments: const [
            ButtonSegment(
              value: ThemeMode.light,
              icon: Icon(Icons.light_mode, size: 18),
              label: Text('Light'),
            ),
            ButtonSegment(
              value: ThemeMode.dark,
              icon: Icon(Icons.dark_mode, size: 18),
              label: Text('Dark'),
            ),
            ButtonSegment(
              value: ThemeMode.system,
              icon: Icon(Icons.brightness_auto, size: 18),
              label: Text('Auto'),
            ),
          ],
          selected: {currentMode},
          onSelectionChanged: (Set<ThemeMode> newSelection) {
            ref.read(themeModeProvider.notifier).setTheme(newSelection.first);
          },
        ),
      ],
    );
  }
}

// ============================================================================
// EXPORT DATA BUTTON
// ============================================================================

class _ExportDataButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _exportData(context, ref),
      icon: const Icon(Icons.download),
      label: const Text('Export Data'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withAlpha((67).round())),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      // Gather all data from Hive
      final box = Hive.box('settings');

      final exportData = {
        'exportDate': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'settings': box.toMap(),
        'chatMessages': ref.read(chatProvider).map((m) => m.toMap()).toList(),
        'sessions':
            ref.read(sessionHistoryProvider).map((s) => s.toMap()).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);

      // TODO: IMPLEMENTATION - Write to file system
      //
      // Mobile (iOS/Android):
      // import 'package:path_provider/path_provider.dart';
      // import 'dart:io';
      //
      // final directory = await getApplicationDocumentsDirectory();
      // final file = File('${directory.path}/maitri_export_${DateTime.now().millisecondsSinceEpoch}.json');
      // await file.writeAsString(jsonString);
      //
      // // Share file
      // import 'package:share_plus/share_plus.dart';
      // await Share.shareXFiles([XFile(file.path)], text: 'MAITRI Data Export');

      // TODO: WEB IMPLEMENTATION - Download file
      //
      // import 'dart:html' as html;
      //
      // final bytes = utf8.encode(jsonString);
      // final blob = html.Blob([bytes]);
      // final url = html.Url.createObjectUrlFromBlob(blob);
      // final anchor = html.AnchorElement(href: url)
      //   ..setAttribute('download', 'maitri_export_${DateTime.now().millisecondsSinceEpoch}.json')
      //   ..click();
      // html.Url.revokeObjectUrl(url);

      // TODO: CSV Export Option
      // - Convert journal entries to CSV format
      // - One row per entry with: date, title, content, word_count
      // - Escape quotes and newlines properly
      // - Example: '"2024-01-15","My Entry","Content here",150'

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data export feature coming soon'),
          duration: Duration(seconds: 2),
        ),
      );

      debugPrint('Export data (${jsonString.length} bytes):\n$jsonString');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }
}

// ============================================================================
// CLEAR DATA BUTTON
// ============================================================================

class _ClearDataButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => _confirmClearData(context, ref),
      icon: const Icon(Icons.delete_outline, color: Colors.red),
      label: const Text('Clear All Data'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.red,
        side: const BorderSide(color: Colors.red),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  Future<void> _confirmClearData(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your conversations, journal entries, and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await _clearAllData(context, ref);
    }
  }

  Future<void> _clearAllData(BuildContext context, WidgetRef ref) async {
    try {
      // Clear all Hive boxes
      await Hive.box('settings').clear();
      await Hive.box('userPreferences').clear();

      // Clear provider states
      await ref.read(chatProvider.notifier).clear();
      await ref.read(sessionHistoryProvider.notifier).clearAll();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error clearing data: $e')),
      );
    }
  }
}

// ============================================================================
// LOGOUT BUTTON
// ============================================================================

class _LogoutButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () async {
        await ref.read(authProvider.notifier).logout();
        if (context.mounted) {
          context.go(AppRoutes.kAuth);
        }
      },
      icon: const Icon(Icons.logout),
      label: const Text('Logout'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }
}

// ============================================================================
// ABOUT SECTION
// ============================================================================

class _AboutSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha((11).round()),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha((11).round()),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade400, size: 24),
              const SizedBox(width: 12),
              Text(
                'About',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // App version
          _InfoRow(
            label: 'Version',
            value: '1.0.0',
          ),
          const SizedBox(height: 12),

          // Offline mode
          _InfoRow(
            label: 'Mode',
            value: 'Offline-First',
            subtitle: 'All data stored locally on your device',
          ),
          const SizedBox(height: 12),

          // Privacy
          _InfoRow(
            label: 'Privacy',
            value: 'Your data never leaves your device',
            subtitle: 'End-to-end encrypted storage',
          ),
          const SizedBox(height: 16),

          // Links
          TextButton.icon(
            onPressed: () {
              // TODO: Open privacy policy
            },
            icon: const Icon(Icons.privacy_tip_outlined, size: 16),
            label: const Text('Privacy Policy'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue.shade400,
            ),
          ),
          TextButton.icon(
            onPressed: () {
              // TODO: Open help documentation
            },
            icon: const Icon(Icons.help_outline, size: 16),
            label: const Text('Help & Documentation'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;

  const _InfoRow({
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withAlpha((135).round()),
                fontSize: 14,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              color: Colors.white.withAlpha((45).round()),
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

// ============================================================================
// ENTERPRISE DISTRIBUTION & MDM NOTES
// ============================================================================
//
// TODO: Enterprise Distribution Hooks
//
// 1. Mobile Device Management (MDM) Integration:
//    - iOS: Configure App Configuration via MDM
//      * Support managed app configuration dictionary
//      * Read config from UserDefaults standard domain
//      * Example: VPN settings, server URLs, feature flags
//    
//    - Android: Android Enterprise (formerly Android for Work)
//      * Support managed configuration via RestrictionsManager
//      * Read restrictions bundle
//      * Handle configuration changes dynamically
//
// 2. Configuration Keys to Support:
//    ```dart
//    class MDMConfig {
//      static const String serverUrl = 'com.maitri.server_url';
//      static const String orgId = 'com.maitri.org_id';
//      static const String ssoEnabled = 'com.maitri.sso_enabled';
//      static const String featureFlags = 'com.maitri.features';
//    }
//    ```
//
// 3. Reading MDM Configuration:
//    iOS:
//    ```dart
//    final defaults = UserDefaults.standard;
//    final serverUrl = defaults.string(forKey: MDMConfig.serverUrl);
//    ```
//    
//    Android:
//    ```dart
//    final restrictions = RestrictionsManager(context);
//    final config = restrictions.applicationRestrictions;
//    final serverUrl = config.getString(MDMConfig.serverUrl);
//    ```
//
// 4. App Store Distribution:
//    - iOS: Apple Business Manager / Volume Purchase Program
//      * Register app with Apple Business Manager
//      * Support managed app distribution
//      * Handle license management
//    
//    - Android: Google Play Managed Configurations
//      * Define managed configurations XML
//      * Test with Test DPC app
//      * Support private enterprise distribution
//
// 5. Security Requirements:
//    - Certificate pinning for enterprise APIs
//    - Force app updates via MDM
//    - Remote wipe capability
//    - Audit logging for compliance
//    - Data loss prevention (DLP) policies
//
// 6. Feature Flags for Enterprise:
//    ```dart
//    class EnterpriseFeatures {
//      static bool get cloudSyncEnabled => _mdmConfig['cloud_sync'] ?? false;
//      static bool get ssoRequired => _mdmConfig['sso_required'] ?? false;
//      static bool get offlineOnlyMode => _mdmConfig['offline_only'] ?? true;
//    }
//    ```
//
// 7. Implementation Example:
//    ```dart
//    class MDMService {
//      static Future<Map<String, dynamic>> getConfiguration() async {
//        if (Platform.isIOS) {
//          // Read from UserDefaults
//          return _readIOSConfig();
//        } else if (Platform.isAndroid) {
//          // Read from RestrictionsManager
//          return _readAndroidConfig();
//        }
//        return {};
//      }
//    }
//    ```
//
// TODO: Implement MDM configuration reader service
// TODO: Add enterprise SSO integration
// TODO: Support custom branding via MDM
// TODO: Add compliance reporting
// TODO: Implement remote configuration updates