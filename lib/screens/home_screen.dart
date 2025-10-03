import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Widgets
import '../widgets/main_navbar.dart';
import '../widgets/side_panel.dart';
import '../widgets/space_background.dart';

// Screens
import 'chat_screen.dart';
import 'dashboard_screen.dart';
import 'journal_screen.dart';
import 'settings_screen.dart';

// Providers
import '../providers/app_providers.dart';
import '../app_router.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const HomeScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late int _currentIndex;
  bool _isSidePanelExpanded = true;
  bool _isVoiceMode = false;

  final List<Widget> _screens = const [
    ChatScreen(),
    DashboardScreen(),
    JournalScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }

  /// Call this to switch tabs from buttons inside HomeScreen
  void openTab(int tabIndex) {
    if (_currentIndex == tabIndex) return;
    setState(() => _currentIndex = tabIndex);
  }

  void _onTabChanged(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
    _updateRouteForTab(index);
  }

  void _updateRouteForTab(int index) {
    // Don't update route if already on the same tab to avoid unnecessary rebuilds
    if (_currentIndex == index) return;

    switch (index) {
      case AppRoutes.tabChat:
        AppRoutes.goToChat(context);
        break;
      case AppRoutes.tabDashboard:
        AppRoutes.goToDashboard(context);
        break;
      case AppRoutes.tabJournal:
        AppRoutes.goToJournal(context);
        break;
      case AppRoutes.tabSettings:
        AppRoutes.goToSettings(context);
        break;
    }
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update tab when initialTabIndex changes (e.g., from route change)
    if (widget.initialTabIndex != oldWidget.initialTabIndex) {
      setState(() => _currentIndex = widget.initialTabIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sessionHistory = ref.watch(sessionHistoryProvider);

    return Scaffold(
      appBar: const MainNavBar(),
      body: SpaceBackground.particles(
        child: Row(
          children: [
            SidePanel(
              historyCount: sessionHistory.length,
              onHistoryTap: () {},
              onVoiceToggle: (v) => setState(() => _isVoiceMode = v),
              isVoice: _isVoiceMode,
              isExpanded: _isSidePanelExpanded,
              onToggle: () =>
                  setState(() => _isSidePanelExpanded = !_isSidePanelExpanded),
            ),
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: _screens,
              ),
            ),
          ],
        ),
      ),

      // =========================
      // Bottom nav for ALL devices (mobile, tablet, and desktop/Chrome)
      // =========================
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(67),
          border: Border(
            top: BorderSide(
              color: Colors.white.withAlpha(22),
              width: 1,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabChanged,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: Colors.blue.shade400,
          unselectedItemColor: Colors.white.withAlpha(135),
          selectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline),
              activeIcon: Icon(Icons.chat_bubble),
              label: 'Chat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.book_outlined),
              activeIcon: Icon(Icons.book),
              label: 'Journal',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}
