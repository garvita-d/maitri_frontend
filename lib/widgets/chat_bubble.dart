import 'package:flutter/material.dart';
import '../providers/app_providers.dart';

/// Individual message bubble widget with sender-specific styling
/// Supports text messages, timestamps, and optional attachments
class ChatBubble extends StatelessWidget {
  final Message message;
  final bool isMine;
  const ChatBubble({super.key, required this.message, required this.isMine});

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
        child: Semantics(
          label: isMine ? 'Your message' : 'Assistant message',
          child: Text(
            message.content, // Make sure Message has a 'content' field
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// Assistant avatar with robot icon
class AssistantAvatar extends StatelessWidget {
  const AssistantAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.purple.shade700.withAlpha(204), // 0.8 * 255 = 204
      child: const Icon(
        Icons.smart_toy,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}

// User avatar with person icon
class UserAvatar extends StatelessWidget {
  const UserAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: Colors.blue.shade700.withAlpha(204), // 0.8 * 255 = 204
      child: const Icon(
        Icons.person,
        color: Colors.white,
        size: 16,
      ),
    );
  }
}
