import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../app_router.dart';
import 'mic_button.dart';

class MainNavBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  const MainNavBar({super.key});

  @override
  ConsumerState<MainNavBar> createState() => _MainNavBarState();

  @override
  Size get preferredSize => const Size.fromHeight(64);
}

class _MainNavBarState extends ConsumerState<MainNavBar> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    debugPrint('Search query: $query');
    // TODO: Implement search functionality
    // You can use this to filter journal entries or chat history
    setState(() {});
  }

  void _handleProfileTap() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _ProfileModal(),
    );
  }

  void _handleSettingsTap() {
    // Navigate to Settings tab using the proper route
    AppRoutes.goToSettings(context);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return AppBar(
      elevation: 0,
      backgroundColor: isDark
          ? Colors.black.withOpacity(0.5)
          : Colors.white.withOpacity(0.9),
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 64,
      title: Row(
        children: [
          InkWell(
            onTap: () => AppRoutes.goToChat(context),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                'MAITRI',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              constraints: BoxConstraints(
                maxWidth: _isSearchExpanded ? 500 : 300,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _handleSearch,
                onTap: () => setState(() => _isSearchExpanded = true),
                onSubmitted: (query) {
                  setState(() => _isSearchExpanded = false);
                  _handleSearch(query);
                },
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search conversations...',
                  hintStyle: TextStyle(
                    color:
                        isDark ? Colors.white.withOpacity(0.4) : Colors.black45,
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color:
                        isDark ? Colors.white.withOpacity(0.6) : Colors.black54,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: isDark
                                ? Colors.white.withOpacity(0.6)
                                : Colors.black54,
                            size: 18,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.grey.shade100,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        MicButton(
          onPressed: () {
            debugPrint('Quick mic action triggered');
            // TODO: Implement voice recording functionality
          },
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: Icon(
            Icons.settings_outlined,
            color: isDark ? Colors.white.withOpacity(0.8) : Colors.black87,
          ),
          onPressed: _handleSettingsTap,
          tooltip: 'Settings',
          splashRadius: 24,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 8, right: 16),
          child: InkWell(
            onTap: _handleProfileTap,
            borderRadius: BorderRadius.circular(20),
            child: CircleAvatar(
              radius: 20,
              backgroundColor:
                  isDark ? Colors.blue.shade700 : Colors.blue.shade300,
              child: authState == AuthState.authenticated
                  ? const Icon(Icons.person, color: Colors.white, size: 20)
                  : const Icon(Icons.person_outline,
                      color: Colors.white, size: 20),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProfileModal extends ConsumerWidget {
  const _ProfileModal();

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 12),
            Text('Help & Support'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Welcome to MAITRI - Your Mental Wellness Companion',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              _HelpItem(
                icon: Icons.chat_bubble_outline,
                title: 'Chat',
                description:
                    'Have a conversation with your AI companion for emotional support and guidance.',
              ),
              const SizedBox(height: 12),
              _HelpItem(
                icon: Icons.dashboard_outlined,
                title: 'Dashboard',
                description:
                    'View your mood trends, recent sessions, and quick actions.',
              ),
              const SizedBox(height: 12),
              _HelpItem(
                icon: Icons.book_outlined,
                title: 'Journal',
                description:
                    'Keep track of your thoughts, feelings, and progress over time.',
              ),
              const SizedBox(height: 12),
              _HelpItem(
                icon: Icons.settings_outlined,
                title: 'Settings',
                description:
                    'Customize your experience, manage privacy, and adjust preferences.',
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Need more help?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '• Email: support@maitri.com\n'
                '• Available 24/7 for your support\n'
                '• Crisis helpline: 1-800-273-8255',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.shade600,
              child: const Icon(Icons.person, size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              authState == AuthState.authenticated ? 'User Account' : 'Guest',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              authState == AuthState.authenticated
                  ? 'Signed in'
                  : 'Browsing as guest',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                AppRoutes.goToSettings(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                _showHelpDialog(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About MAITRI'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(context);
                showAboutDialog(
                  context: context,
                  applicationName: 'MAITRI',
                  applicationVersion: '1.0.0',
                  applicationIcon:
                      const Icon(Icons.favorite, size: 48, color: Colors.blue),
                  children: [
                    const Text(
                      'Your personal mental wellness companion. '
                      'MAITRI is here to support you on your journey to better mental health.',
                    ),
                  ],
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Confirm Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true && context.mounted) {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go(AppRoutes.kAuth);
                  }
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
