import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../widgets/mic_button.dart';
import '../services/audio_service.dart';
import '../services/camera_service.dart';
import 'package:camera/camera.dart';

/// Full-featured chat interface with message list and input controls
/// Features: scrollable messages, text/voice/camera input, real-time updates
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  bool _isListening = false;
  bool _isCameraActive = false;
  bool _isSending = false;

  // 👇 Added for emotion detection
  String _mood = "Unknown";
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    CameraService.stopPreview(); // 👈 ensure camera is stopped
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    if (_scrollController.hasClients) {
      if (animate) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    }
  }

  Future<void> _handleSend() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      _messageController.clear();
      await ref.read(chatProvider.notifier).sendMessage(text);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      debugPrint('Error sending message: $e');
    } finally {
      setState(() => _isSending = false);
    }
  }

  Future<void> _handleMicPress() async {
    if (_isListening) {
      await AudioService.stopListening();
      setState(() => _isListening = false);
    } else {
      setState(() => _isListening = true);
      try {
        await AudioService.startListening(
          onResult: (String recognizedText) {
            _messageController.text = recognizedText;
            setState(() {});
          },
          onError: (String error) {
            debugPrint('Speech recognition error: $error');
            setState(() => _isListening = false);
          },
        );
      } catch (e) {
        debugPrint('Failed to start listening: $e');
        setState(() => _isListening = false);
      }
    }
  }

  /// Handle camera toggle for visual input + emotion detection
  Future<void> _handleCameraToggle() async {
    if (_isCameraActive) {
      // Stop camera
      await CameraService.stopPreview();
      setState(() {
        _isCameraActive = false;
        _mood = "Unknown";
      });
    } else {
      final started = await CameraService.startPreview(
        onError: (msg) => debugPrint("Camera error: $msg"),
      );
      if (started) {
        setState(() => _isCameraActive = true);
        _startDetectLoop();
      }
    }
  }

  /// Start continuous emotion detection
  Future<void> _startDetectLoop() async {
    if (_isDetecting) return;
    _isDetecting = true;

    while (mounted && CameraService.isActive) {
      final mood = await CameraService.captureAndAnalyzeEmotion();
      if (!mounted) break;
      setState(() => _mood = mood ?? "Unknown");
      await Future.delayed(const Duration(seconds: 3));
    }

    _isDetecting = false;
  }

  void _handleKeyboardVisibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    if (keyboardVisible) {
      _handleKeyboardVisibility();
    }

    return Column(
      children: [
        // Message list
        Expanded(
          child: messages.isEmpty
              ? _EmptyState()
              : ListView.builder(
                  controller: _scrollController,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ChatBubble(
                      key: ValueKey(message.id),
                      message: message,
                      isMine: message.isUser,
                    );
                  },
                ),
        ),

        // 👇 Camera preview overlay + mood display
        if (_isCameraActive)
          SizedBox(
            height: 220,
            child: Stack(
              children: [
                CameraService.controller?.value.isInitialized == true
                    ? CameraPreview(CameraService.controller!)
                    : const Center(child: CircularProgressIndicator()),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _handleCameraToggle,
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "Mood: $_mood",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Input area
        _MessageInputBar(
          controller: _messageController,
          focusNode: _messageFocusNode,
          isListening: _isListening,
          isCameraActive: _isCameraActive,
          isSending: _isSending,
          onSend: _handleSend,
          onMicPress: _handleMicPress,
          onCameraToggle: _handleCameraToggle,
        ),
      ],
    );
  }
}

// ============================================================================
// MESSAGE INPUT BAR
// ============================================================================

class _MessageInputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isListening;
  final bool isCameraActive;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onMicPress;
  final VoidCallback onCameraToggle;

  const _MessageInputBar({
    required this.controller,
    required this.focusNode,
    required this.isListening,
    required this.isCameraActive,
    required this.isSending,
    required this.onSend,
    required this.onMicPress,
    required this.onCameraToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((67).round()),
        border: Border(
          top: BorderSide(
            color: Colors.white.withAlpha((22).round()),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Camera toggle button
            IconButton(
              icon: Icon(
                isCameraActive ? Icons.videocam : Icons.videocam_outlined,
                color: isCameraActive
                    ? Colors.blue.shade400
                    : Colors.white.withAlpha((157).round()),
              ),
              onPressed: onCameraToggle,
              tooltip: isCameraActive ? 'Stop camera' : 'Start camera',
            ),

            const SizedBox(width: 8),

            // Text input field
            Expanded(
              child: Semantics(
                label: 'Message input field',
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  maxLines: 5,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText:
                        isListening ? 'Listening...' : 'Type a message...',
                    hintStyle: TextStyle(
                      color: Colors.white.withAlpha((90).round()),
                    ),
                    filled: true,
                    fillColor: Colors.white.withAlpha((11).round()),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Microphone button
            MicButton(
              isListening: isListening,
              onPressed: onMicPress,
            ),

            const SizedBox(width: 8),

            // Send button
            CircleAvatar(
              radius: 24,
              backgroundColor: controller.text.trim().isNotEmpty && !isSending
                  ? Colors.blue.shade600
                  : Colors.grey.shade700,
              child: IconButton(
                icon: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                onPressed: controller.text.trim().isNotEmpty && !isSending
                    ? onSend
                    : null,
                tooltip: 'Send message',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// EMPTY STATE
// ============================================================================

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.white.withAlpha((67).round()),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: TextStyle(
              color: Colors.white.withAlpha((200).round()),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation below',
            style: TextStyle(
              color: Colors.white.withAlpha((90).round()),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// PERFORMANCE & EDGE CASE NOTES
// ============================================================================
//
// Keyboard Handling:
// - Monitor MediaQuery.of(context).viewInsets.bottom for keyboard state
// - Auto-scroll to bottom when keyboard appears
// - Maintain scroll position when keyboard dismisses
// - Use SafeArea to prevent input being hidden
//
// Scroll Behavior:
// - Auto-scroll to bottom on new messages
// - Preserve scroll position when user scrolls up (don't force scroll)
// - Use animateTo() for smooth scrolling
// - Check hasClients before scrolling to avoid errors
//
// ListView.builder Performance:
// - Uses ValueKey(message.id) for efficient widget recycling
// - Only renders visible items + small buffer
// - Supports thousands of messages without lag
// - Consider using reverse: true for chat-style scrolling
//
// Edge Cases Handled:
// - Empty message prevention (trim check)
// - Send button disabled while sending
// - Microphone permission failures
// - Camera not available
// - Network errors on send
// - Rapid consecutive sends
//
// TODO: Additional optimizations
// - Implement pagination for large chat histories
// - Add pull-to-refresh for loading older messages
// - Cache rendered bubbles for smoother scrolling
// - Implement message read receipts
// - Add typing indicators
// - Support message editing/deletion
// - Handle attachment uploads with progress
/// FILE: lib/widgets/chat_bubble.dart

class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  const ChatBubble({Key? key, required this.message, required this.isMine})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMine ? Colors.blue : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          message.content,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
