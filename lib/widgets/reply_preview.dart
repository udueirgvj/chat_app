// lib/widgets/reply_preview.dart
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/message_model.dart';

class ReplyPreview extends StatelessWidget {
  final MessageModel message;
  final VoidCallback onCancel;

  const ReplyPreview({
    super.key,
    required this.message,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surfaceDark,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 36,
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message.senderName,
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _previewText(),
                  style: const TextStyle(
                    color: Color(0xFF8797A7),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF8797A7), size: 20),
            onPressed: onCancel,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  String _previewText() {
    switch (message.type) {
      case 'image': return '📷 صورة';
      case 'video': return '🎥 فيديو';
      case 'file':  return '📎 ${message.fileName ?? "ملف"}';
      case 'audio': return '🎵 رسالة صوتية';
      default:      return message.content;
    }
  }
}
