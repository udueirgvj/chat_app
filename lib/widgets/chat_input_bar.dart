// lib/widgets/chat_input_bar.dart
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class ChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;
  final VoidCallback onImageCamera;
  final VoidCallback onImageGallery;
  final VoidCallback onFile;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.isSending,
    required this.onSend,
    required this.onImageCamera,
    required this.onImageGallery,
    required this.onFile,
  });

  @override
  State<ChatInputBar> createState() => _ChatInputBarState();
}

class _ChatInputBarState extends State<ChatInputBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(() {
      final has = widget.controller.text.trim().isNotEmpty;
      if (has != _hasText) setState(() => _hasText = has);
    });
  }

  void _showAttachMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.dividerDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _attachOption(
                    icon: Icons.camera_alt_outlined,
                    label: 'الكاميرا',
                    color: Colors.pink,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onImageCamera();
                    },
                  ),
                  _attachOption(
                    icon: Icons.photo_library_outlined,
                    label: 'الصور',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onImageGallery();
                    },
                  ),
                  _attachOption(
                    icon: Icons.insert_drive_file_outlined,
                    label: 'ملف',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      widget.onFile();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attachOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
                border: Border.all(color: color.withAlpha(80)),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 12)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceDark,
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Attach button
          IconButton(
            icon: const Icon(Icons.attach_file_rounded,
                color: Color(0xFF8797A7)),
            onPressed: widget.isSending ? null : _showAttachMenu,
          ),

          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: widget.controller,
                maxLines: null,
                textDirection: TextDirection.rtl,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'اكتب رسالة...',
                  hintStyle: TextStyle(color: Color(0xFF8797A7)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                ),
                onSubmitted: (_) {
                  if (_hasText) widget.onSend();
                },
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Send / Mic button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: anim,
              child: child,
            ),
            child: widget.isSending
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.primary),
                    ),
                  )
                : GestureDetector(
                    key: ValueKey(_hasText),
                    onTap: _hasText ? widget.onSend : null,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: const BoxDecoration(
                        color: AppTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _hasText
                            ? Icons.send_rounded
                            : Icons.mic_none_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
