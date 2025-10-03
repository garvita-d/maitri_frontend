import 'package:flutter/material.dart';

/// Microphone button with recording animation
/// Features: pulsing animation, visual feedback, accessible controls
///
/// UI only - actual audio recording logic handled by parent via callbacks
class MicButton extends StatefulWidget {
  /// Callback when recording should start
  final VoidCallback onPressed;

  /// Whether microphone is currently recording
  final bool isListening;

  /// Optional custom size
  final double size;

  const MicButton({
    super.key,
    required this.onPressed,
    this.isListening = false,
    this.size = 48,
  });

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    // Setup pulsing animation for recording state
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _opacityAnimation = Tween<double>(
      begin: 0.6,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    // Start animation if already listening
    if (widget.isListening) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MicButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Start/stop animation based on listening state
    if (widget.isListening && !oldWidget.isListening) {
      _animationController.repeat(reverse: true);
    } else if (!widget.isListening && oldWidget.isListening) {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer ripple effect (only visible when recording)
              if (widget.isListening)
                Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: widget.size + 20,
                    height: widget.size + 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withAlpha(
                        (150 * (1 - _opacityAnimation.value)).round(),
                      ),
                    ),
                  ),
                ),

              // Main button
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.isListening
                      ? Colors.red.shade600
                      : Colors.blue.shade600,
                  boxShadow: [
                    BoxShadow(
                      color: (widget.isListening ? Colors.red : Colors.blue)
                          .withAlpha((90).round()),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  widget.isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: widget.size * 0.5,
                  semanticLabel:
                      widget.isListening ? 'Stop recording' : 'Start recording',
                ),
              ),

              // Recording indicator dots (visual feedback)
              if (widget.isListening)
                Positioned(
                  bottom: 0,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: AnimatedOpacity(
                          opacity: _getIndicatorOpacity(index),
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  /// Get animated opacity for recording indicator dots
  double _getIndicatorOpacity(int index) {
    final progress = _animationController.value;
    final delay = index * 0.2;
    final adjustedProgress = (progress + delay) % 1.0;
    return adjustedProgress < 0.5 ? 1.0 : 0.3;
  }
}

// ============================================================================
// PERMISSIONS & PLATFORM NOTES
// ============================================================================
//
// MOBILE (iOS/Android) Permission Flow:
// 
// 1. First Time Usage:
//    - User taps mic button
//    - System shows native permission dialog
//    - App handles permission result (granted/denied/restricted)
//
// 2. Permission States:
//    - Granted: Proceed with recording
//    - Denied: Show dialog explaining why permission is needed
//    - Permanently Denied: Guide user to app settings
//
// 3. Implementation Example:
//    ```dart
//    import 'package:permission_handler/permission_handler.dart';
//    
//    Future<bool> requestMicrophonePermission() async {
//      final status = await Permission.microphone.request();
//      
//      if (status.isGranted) {
//        return true;
//      } else if (status.isPermanentlyDenied) {
//        // Show dialog to open app settings
//        await openAppSettings();
//      }
//      return false;
//    }
//    ```
//
// 4. Platform-Specific Setup:
//    iOS (Info.plist):
//      <key>NSMicrophoneUsageDescription</key>
//      <string>We need microphone access for voice input</string>
//      <key>NSSpeechRecognitionUsageDescription</key>
//      <string>We need speech recognition for voice commands</string>
//
//    Android (AndroidManifest.xml):
//      <uses-permission android:name="android.permission.RECORD_AUDIO" />
//      <uses-permission android:name="android.permission.INTERNET" />
//
// WEB Permission Flow:
//
// 1. User Interaction Required:
//    - Browser requires user gesture (click/tap) to enable microphone
//    - Cannot auto-start recording on page load
//    - Must call getUserMedia() in response to user action
//
// 2. Browser Permission Dialog:
//    - Browser shows permission prompt on first use
//    - User can allow/block for current session or permanently
//    - Permission state persisted per domain
//
// 3. HTTPS Requirement:
//    - Microphone access requires HTTPS (except localhost)
//    - getUserMedia() throws error on insecure contexts
//    - Test locally with 'flutter run -d chrome --web-hostname localhost'
//
// 4. Implementation Example:
//    ```dart
//    import 'dart:html' as html;
//    
//    Future<bool> requestWebMicrophonePermission() async {
//      try {
//        final stream = await html.window.navigator.mediaDevices!.getUserMedia({
//          'audio': true,
//        });
//        stream.getTracks().forEach((track) => track.stop());
//        return true;
//      } catch (e) {
//        // User denied or browser blocked
//        return false;
//      }
//    }
//    ```
//
// 5. Error Handling:
//    - NotAllowedError: User denied permission
//    - NotFoundError: No microphone device available
//    - NotReadableError: Device in use by another app
//    - SecurityError: HTTPS required or insecure context
//
// Best Practices:
// - Always explain why you need microphone access before requesting
// - Provide visual feedback during recording (this widget handles that)
// - Allow users to review and edit voice input before sending
// - Implement fallback to text input if permission denied
// - Cache permission state to avoid repeated prompts
// - Test on actual devices, not just simulators
//
// TODO: Add permission request logic in parent component
// TODO: Add visual indicator when permission is denied
// TODO: Add help tooltip explaining microphone usage
// TODO: Implement voice level visualization (waveform or bars)