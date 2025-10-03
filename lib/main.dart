import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Import your central router
import 'app_router.dart';
import 'providers/app_providers.dart';

/// Initialize Hive local storage
Future<void> initHive() async {
  await Hive.initFlutter();

  // Open boxes for app data
  await Hive.openBox('settings');
  await Hive.openBox('userPreferences');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initHive();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'maitri_frontend',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: themeMode,

      // ✅ Use AppRoutes.router from app_router.dart
      routerConfig: AppRoutes.router,
    );
  }
}
