// FILE: lib/providers/theme_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A StateProvider that stores the current ThemeMode
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  return ThemeMode.system; // default theme
});
