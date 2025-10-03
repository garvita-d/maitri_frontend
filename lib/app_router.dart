/// FILE: lib/app_router.dart

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Screens
import 'screens/auth_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';

class AppRoutes {
  AppRoutes._();

  static const String kAuth = '/auth';
  static const String kSignup = '/signup';
  static const String kHome = '/home';

  /// Bottom nav tabs indices
  static const int tabChat = 0;
  static const int tabDashboard = 1;
  static const int tabJournal = 2;
  static const int tabSettings = 3;

  static final GoRouter router = GoRouter(
    initialLocation: kAuth,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: kAuth,
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: kSignup,
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: kHome,
        name: 'home',
        builder: (context, state) {
          final tab =
              int.tryParse(state.uri.queryParameters['tab'] ?? '0') ?? 0;
          return HomeScreen(initialTabIndex: tab);
        },
      ),
    ],
  );

  /// Helper functions to navigate to tabs
  static void goToChat(BuildContext context) =>
      context.go('$kHome?tab=$tabChat');

  static void goToDashboard(BuildContext context) =>
      context.go('$kHome?tab=$tabDashboard');

  static void goToJournal(BuildContext context) =>
      context.go('$kHome?tab=$tabJournal');

  static void goToSettings(BuildContext context) =>
      context.go('$kHome?tab=$tabSettings');
}
