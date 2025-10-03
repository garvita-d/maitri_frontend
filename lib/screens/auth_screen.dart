import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../widgets/video_background.dart';
import '../providers/auth_provider.dart';
import '../widgets/side_panel.dart';
import '../app_router.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPanelExpanded = false;
  bool _isVoiceMode = false;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );

      if (mounted) {
        context.go(AppRoutes.kHome);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleContinueAsGuest() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authProvider.notifier).loginAsGuest();
      if (mounted) context.go(AppRoutes.kHome);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: VideoBackground.auth(
        child: Stack(
          children: [
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Welcome to MAITRI',
                          style: Theme.of(context)
                              .textTheme
                              .displayMedium
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your AI companion for mental wellness',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Colors.white.withAlpha((157).round()),
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),

                        // Email field
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Email required' : null,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(
                                color: Colors.white.withAlpha((157).round())),
                            prefixIcon:
                                const Icon(Icons.email, color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white.withAlpha((22).round()),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Password required' : null,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(
                                color: Colors.white.withAlpha((157).round())),
                            prefixIcon:
                                const Icon(Icons.lock, color: Colors.white70),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                setState(
                                    () => _obscurePassword = !_obscurePassword);
                              },
                            ),
                            filled: true,
                            fillColor: Colors.white.withAlpha((22).round()),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sign In button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignIn,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Sign In',
                                    style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Sign Up button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => context.go(AppRoutes.kSignup),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                  color: Colors.white.withAlpha((112).round())),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Create Account',
                                style: TextStyle(fontSize: 16)),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Guest button
                        TextButton(
                          onPressed: _isLoading ? null : _handleContinueAsGuest,
                          child: Text(
                            'Continue as Guest',
                            style: TextStyle(
                                color: Colors.white.withAlpha((157).round())),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SidePanel(
              historyCount: 0,
              onHistoryTap: () {},
              onVoiceToggle: (v) => setState(() => _isVoiceMode = v),
              isVoice: _isVoiceMode,
              isExpanded: _isPanelExpanded,
              onToggle: () =>
                  setState(() => _isPanelExpanded = !_isPanelExpanded),
            ),
          ],
        ),
      ),
    );
  }
}
