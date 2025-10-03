import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Providers
import '../providers/app_providers.dart';

/// Journal screen for writing and managing personal entries
/// Features: Rich text input, save functionality, entry history
class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<JournalEntry> _entries = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Load journal entries from Hive storage
  Future<void> _loadEntries() async {
    final box = Hive.box('settings');
    final entriesData = box.get('journalEntries', defaultValue: []) as List;

    setState(() {
      _entries = entriesData
          .map((e) => JournalEntry.fromMap(Map<String, dynamic>.from(e)))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  /// Save new journal entry
  Future<void> _saveEntry() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please write something first')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final entry = JournalEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title.isEmpty ? 'Untitled Entry' : title,
        content: content,
        createdAt: DateTime.now(),
        wordCount: content.split(RegExp(r'\s+')).length,
      );

      // Save to Hive
      final box = Hive.box('settings');
      final entries = [..._entries, entry];
      await box.put(
        'journalEntries',
        entries.map((e) => e.toMap()).toList(),
      );

      // Update UI
      setState(() {
        _entries = entries..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      });

      // Clear inputs
      _titleController.clear();
      _contentController.clear();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Journal entry saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving entry: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save entry'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  /// Delete journal entry
  Future<void> _deleteEntry(String id) async {
    try {
      final box = Hive.box('settings');
      final updatedEntries = _entries.where((e) => e.id != id).toList();

      await box.put(
        'journalEntries',
        updatedEntries.map((e) => e.toMap()).toList(),
      );

      setState(() => _entries = updatedEntries);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Entry deleted')),
        );
      }
    } catch (e) {
      debugPrint('Error deleting entry: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Writing area (left side)
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'Journal',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Express your thoughts and feelings',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withAlpha((157).round()),
                      ),
                ),
                const SizedBox(height: 24),

                // Title input
                TextField(
                  controller: _titleController,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Entry title (optional)',
                    hintStyle: TextStyle(
                      color: Colors.white.withAlpha((90).round()),
                    ),
                    border: InputBorder.none,
                  ),
                ),
                const Divider(color: Colors.white24),
                const SizedBox(height: 16),

                // Content input
                Expanded(
                  child: TextField(
                    controller: _contentController,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.6,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Start writing...',
                      hintStyle: TextStyle(
                        color: Colors.white.withAlpha((90).round()),
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isSaving ? null : _saveEntry,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Save Entry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        _titleController.clear();
                        _contentController.clear();
                      },
                      icon: const Icon(Icons.clear),
                      label: const Text('Clear'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(
                            color: Colors.white.withAlpha((67).round())),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Divider
        Container(
          width: 1,
          color: Colors.white.withAlpha((22).round()),
        ),

        // Entries list (right side)
        Expanded(
          flex: 2,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Past Entries',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 16),

                // Entries list
                Expanded(
                  child: _entries.isEmpty
                      ? Center(
                          child: Text(
                            'No entries yet',
                            style: TextStyle(
                              color: Colors.white.withAlpha((112).round()),
                              fontSize: 16,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: _entries.length,
                          itemBuilder: (context, index) {
                            final entry = _entries[index];
                            return _JournalEntryCard(
                              entry: entry,
                              onDelete: () => _deleteEntry(entry.id),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// JOURNAL ENTRY CARD
// ============================================================================

class _JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final VoidCallback onDelete;

  const _JournalEntryCard({
    required this.entry,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((11).round()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withAlpha((25).round()),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.red.shade400,
                  onPressed: () {
                    // Confirm deletion
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Entry'),
                        content: const Text(
                          'Are you sure you want to delete this entry?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onDelete();
                            },
                            child: const Text(
                              'Delete',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              entry.content,
              style: TextStyle(
                color: Colors.white.withAlpha((112).round()),
                fontSize: 14,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: Colors.white.withAlpha((112).round()),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(entry.createdAt),
                  style: TextStyle(
                    color: Colors.white.withAlpha((112).round()),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.text_fields,
                  size: 12,
                  color: Colors.white.withAlpha((112).round()),
                ),
                const SizedBox(width: 4),
                Text(
                  '${entry.wordCount} words',
                  style: TextStyle(
                    color: Colors.white.withAlpha((112).round()),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';

    return '${date.month}/${date.day}/${date.year}';
  }
}

// ============================================================================
// JOURNAL ENTRY MODEL
// ============================================================================

class JournalEntry {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final int wordCount;

  JournalEntry({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.wordCount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'wordCount': wordCount,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      createdAt: DateTime.parse(map['createdAt'] as String),
      wordCount: map['wordCount'] as int,
    );
  }
}

// ============================================================================
// TODO: FUTURE ENHANCEMENTS
// ============================================================================
//
// Rich Text Editing:
// - Add markdown support for formatting
// - Implement text styling toolbar (bold, italic, lists)
// - Add image/photo attachments
// - Support
