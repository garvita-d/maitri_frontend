import 'package:flutter/material.dart';

class SidePanel extends StatelessWidget {
  final int historyCount;
  final VoidCallback onHistoryTap;
  final ValueChanged<bool> onVoiceToggle;
  final bool isVoice;
  final bool isExpanded;
  final VoidCallback? onToggle;

  const SidePanel({
    super.key,
    required this.historyCount,
    required this.onHistoryTap,
    required this.onVoiceToggle,
    required this.isVoice,
    this.isExpanded = true,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 600;
    final effectiveExpanded = isExpanded && !isNarrowScreen;
    final panelWidth = effectiveExpanded ? 240.0 : 60.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: panelWidth,
      decoration: BoxDecoration(
        color: Colors.black.withAlpha((135).round()),
        border: Border(
          right: BorderSide(
            color: Colors.white.withAlpha((22).round()),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onToggle != null && !isNarrowScreen)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: IconButton(
                icon: Icon(
                  effectiveExpanded ? Icons.chevron_left : Icons.chevron_right,
                  color: Colors.white.withAlpha((157).round()),
                ),
                tooltip: effectiveExpanded ? 'Collapse panel' : 'Expand panel',
                onPressed: onToggle,
              ),
            ),
          const SizedBox(height: 20),
          _PanelButton(
            icon: Icons.history,
            label: 'History',
            isExpanded: effectiveExpanded,
            onTap: onHistoryTap,
            badge: historyCount > 0 ? historyCount : null,
          ),
          const SizedBox(height: 16),
          _VoiceToggle(
            isVoice: isVoice,
            isExpanded: effectiveExpanded,
            onToggle: onVoiceToggle,
          ),
          const Spacer(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _PanelButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isExpanded;
  final VoidCallback onTap;
  final int? badge;

  const _PanelButton({
    required this.icon,
    required this.label,
    required this.isExpanded,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((11).round()),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withAlpha((22).round())),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      icon,
                      color: Colors.white.withAlpha((202).round()),
                      size: 24,
                      semanticLabel: label,
                    ),
                    if (badge != null && badge! > 0)
                      Positioned(
                        right: -8,
                        top: -8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red.shade600,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            badge! > 99 ? '99+' : badge.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withAlpha((202).round()),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VoiceToggle extends StatelessWidget {
  final bool isVoice;
  final bool isExpanded;
  final ValueChanged<bool> onToggle;

  const _VoiceToggle({
    required this.isVoice,
    required this.isExpanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((11).round()),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha((22).round())),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isExpanded) ...[
              Text(
                'Input Mode',
                style: TextStyle(
                  color: Colors.white.withAlpha((157).round()),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // FIX: Use Column instead of ToggleButtons when collapsed
            if (!isExpanded)
              // Collapsed: Single icon button
              Center(
                child: IconButton(
                  icon: Icon(
                    isVoice ? Icons.mic : Icons.keyboard,
                    color: isVoice
                        ? Colors.blue.shade400
                        : Colors.white.withAlpha((157).round()),
                    size: 24,
                  ),
                  onPressed: () => onToggle(!isVoice),
                  tooltip: isVoice ? 'Switch to text' : 'Switch to voice',
                ),
              )
            else
              // Expanded: Toggle buttons
              Center(
                child: ToggleButtons(
                  isSelected: [!isVoice, isVoice],
                  onPressed: (index) => onToggle(index == 1),
                  borderRadius: BorderRadius.circular(8),
                  selectedColor: Colors.white,
                  fillColor: Colors.blue.shade600.withAlpha((180).round()),
                  color: Colors.white.withAlpha((157).round()),
                  borderColor: Colors.white.withAlpha((67).round()),
                  selectedBorderColor: Colors.blue.shade600,
                  constraints: const BoxConstraints(
                    minWidth: 80,
                    minHeight: 40,
                  ),
                  children: const [
                    Tooltip(
                      message: 'Text mode',
                      child: Icon(Icons.keyboard, size: 20),
                    ),
                    Tooltip(
                      message: 'Voice mode',
                      child: Icon(Icons.mic, size: 20),
                    ),
                  ],
                ),
              ),

            if (isExpanded) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  isVoice ? 'Voice' : 'Text',
                  style: TextStyle(
                    color: Colors.white.withAlpha((135).round()),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
