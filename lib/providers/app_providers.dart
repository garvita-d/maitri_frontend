import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
export 'auth_provider.dart';

// -----------------------------------------------------------------
// Global provider to control HomeScreen bottom tab (0..3)
// -----------------------------------------------------------------
final bottomTabProvider = StateProvider<int>((ref) => 0);

// ============================================================================
// THEME MODE PROVIDER
// ============================================================================
final themeModeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>(
  (ref) => ThemeNotifier(),
);

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.system) {
    _loadThemeFromStorage();
  }

  Future<void> _loadThemeFromStorage() async {
    final box = Hive.box('settings');
    final savedTheme = box.get('themeMode', defaultValue: 'system');
    state = _themeModeFromString(savedTheme);
  }

  Future<void> toggleTheme() async {
    final newTheme = switch (state) {
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
      ThemeMode.system => ThemeMode.light,
    };

    state = newTheme;
    final box = Hive.box('settings');
    await box.put('themeMode', newTheme.name);
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final box = Hive.box('settings');
    await box.put('themeMode', mode.name);
  }

  ThemeMode _themeModeFromString(String value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}

// ============================================================================
// AUTHENTICATION PROVIDER
// ============================================================================
enum AuthState { unauthenticated, authenticated, loading }

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState.unauthenticated) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    state = AuthState.loading;
    final box = Hive.box('settings');
    final isAuthenticated = box.get('isAuthenticated', defaultValue: false);
    await Future.delayed(const Duration(milliseconds: 500));
    state =
        isAuthenticated ? AuthState.authenticated : AuthState.unauthenticated;
  }

  Future<void> login(String username, String password) async {
    state = AuthState.loading;
    await Future.delayed(const Duration(seconds: 1));
    final box = Hive.box('settings');
    await box.put('isAuthenticated', true);
    await box.put('username', username);
    state = AuthState.authenticated;
  }

  Future<void> logout() async {
    final box = Hive.box('settings');
    await box.put('isAuthenticated', false);
    await box.delete('username');
    state = AuthState.unauthenticated;
  }
}

// ============================================================================
// GLOBAL SEARCH PROVIDER (used in MainNavBar)
// ============================================================================
final globalSearchProvider =
    StateNotifierProvider<GlobalSearchNotifier, List<String>>((ref) {
  return GlobalSearchNotifier();
});

class GlobalSearchNotifier extends StateNotifier<List<String>> {
  GlobalSearchNotifier() : super([]);

  void search(String query) {
    // TODO: Replace with real DB/Firestore search
    state = ["Found '$query' in Chat", "Found '$query' in Journal"];
  }
}

// ============================================================================
// USER PROVIDER (stub for now, replace with real Firebase user later)
// ============================================================================
class AppUser {
  final String name;
  final String email;

  AppUser({required this.name, required this.email});
}

final userProvider = Provider<AppUser?>((ref) {
  // TODO: Replace with actual Firebase/Auth user
  return AppUser(name: "Garvita Dalmia", email: "garvita@example.com");
});

// ============================================================================
// CHAT PROVIDER
// ============================================================================
class Message {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'content': content,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
      };

  factory Message.fromMap(Map<String, dynamic> map) => Message(
        id: map['id'] as String,
        content: map['content'] as String,
        isUser: map['isUser'] as bool,
        timestamp: DateTime.parse(map['timestamp'] as String),
      );
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<Message>>(
  (ref) => ChatNotifier(),
);

class ChatNotifier extends StateNotifier<List<Message>> {
  ChatNotifier() : super([]) {
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final box = Hive.box('settings');
    final messagesData = box.get('currentChat', defaultValue: []) as List;
    state = messagesData
        .map((e) => Message.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> addMessage(Message message) async {
    state = [...state, message];
    await _persistMessages();
  }

  Future<void> sendMessage(String content) async {
    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
    await addMessage(userMessage);

    await Future.delayed(const Duration(seconds: 1));
    final aiMessage = Message(
      id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
      content: 'This is a mock response to: "$content"',
      isUser: false,
      timestamp: DateTime.now(),
    );
    await addMessage(aiMessage);
  }

  Future<void> clear() async {
    state = [];
    await _persistMessages();
  }

  Future<void> _persistMessages() async {
    final box = Hive.box('settings');
    await box.put('currentChat', state.map((m) => m.toMap()).toList());
  }
}

// ============================================================================
// SESSION HISTORY PROVIDER
// ============================================================================
class SessionItem {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastModified;
  final int messageCount;

  SessionItem({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastModified,
    required this.messageCount,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
        'lastModified': lastModified.toIso8601String(),
        'messageCount': messageCount,
      };

  factory SessionItem.fromMap(Map<String, dynamic> map) => SessionItem(
        id: map['id'] as String,
        title: map['title'] as String,
        createdAt: DateTime.parse(map['createdAt'] as String),
        lastModified: DateTime.parse(map['lastModified'] as String),
        messageCount: map['messageCount'] as int,
      );
}

final sessionHistoryProvider =
    StateNotifierProvider<SessionHistoryNotifier, List<SessionItem>>(
  (ref) => SessionHistoryNotifier(),
);

class SessionHistoryNotifier extends StateNotifier<List<SessionItem>> {
  SessionHistoryNotifier() : super([]) {
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    final box = Hive.box('settings');
    final sessionsData = box.get('sessionHistory', defaultValue: []) as List;
    state = sessionsData
        .map((e) => SessionItem.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> addSession(SessionItem session) async {
    state = [session, ...state];
    await _persistSessions();
  }

  Future<void> updateSession(SessionItem updatedSession) async {
    state = state
        .map((s) => s.id == updatedSession.id ? updatedSession : s)
        .toList();
    await _persistSessions();
  }

  Future<void> deleteSession(String sessionId) async {
    state = state.where((s) => s.id != sessionId).toList();
    await _persistSessions();
  }

  Future<void> clearAll() async {
    state = [];
    await _persistSessions();
  }

  Future<void> _persistSessions() async {
    final box = Hive.box('settings');
    await box.put('sessionHistory', state.map((s) => s.toMap()).toList());
  }
}

// ============================================================================
// HELPER: Initialize Hive
// ============================================================================
Future<void> initHive() async {
  await Hive.initFlutter();
  await Hive.openBox('settings');
  await Hive.openBox('userPreferences');
}
