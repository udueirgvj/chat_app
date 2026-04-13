// lib/widgets/message_bubble.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/helpers.dart';
import '../models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final VoidCallback onLongPress;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) return _deletedBubble();

    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            top: 2,
            bottom: 2,
            left: isMe ? 60 : 6,
            right: isMe ? 6 : 60,
          ),
          child: Column(
            crossAxisAlignment:
                isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (message.replyTo != null) _replyPreview(),
              _bubbleContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bubbleContent(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isMe ? AppTheme.sent : AppTheme.received,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        child: _messageContent(),
      ),
    );
  }

  Widget _messageContent() {
    switch (message.type) {
      case 'image':
        return _imageContent();
      case 'file':
        return _fileContent();
      case 'audio':
        return _audioContent();
      default:
        return _textContent();
    }
  }

  Widget _textContent() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isMe ? Colors.white : const Color(0xFFE0E0E0),
                fontSize: 15,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            _timeRow(),
          ],
        ),
      );

  Widget _imageContent() => Stack(
        children: [
          CachedNetworkImage(
            imageUrl: message.mediaUrl ?? '',
            width: 220,
            height: 200,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              width: 220,
              height: 200,
              color: AppTheme.cardDark,
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (_, __, ___) => Container(
              width: 220,
              height: 200,
              color: AppTheme.cardDark,
              child: const Icon(Icons.broken_image, color: Colors.white54),
            ),
          ),
          Positioned(
            bottom: 6,
            right: 8,
            child: _timeRow(dark: true),
          ),
        ],
      );

  Widget _fileContent() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.insert_drive_file,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? 'ملف',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    message.fileSize != null
                        ? AppHelpers.formatFileSize(message.fileSize!)
                        : '',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 11),
                  ),
                  _timeRow(),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _audioContent() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle_fill, color: Colors.white, size: 38),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('رسالة صوتية',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
                Text(
                  message.audioDuration != null
                      ? AppHelpers.formatDuration(message.audioDuration!)
                      : '',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11),
                ),
                _timeRow(),
              ],
            ),
          ],
        ),
      );

  Widget _deletedBubble() => Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: EdgeInsets.only(
            top: 2,
            bottom: 2,
            left: isMe ? 60 : 6,
            right: isMe ? 6 : 60,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.dividerDark),
          ),
          child: const Text(
            '🚫 تم حذف هذه الرسالة',
            style: TextStyle(
                color: Color(0xFF8797A7),
                fontSize: 13,
                fontStyle: FontStyle.italic),
          ),
        ),
      );

  Widget _replyPreview() => Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(40),
          borderRadius: BorderRadius.circular(10),
          border: Border(
            right: BorderSide(
              color: isMe ? Colors.white60 : AppTheme.primary,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.replyTo!.senderName,
              style: TextStyle(
                color: isMe ? Colors.white70 : AppTheme.accent,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              message.replyTo!.content.isNotEmpty
                  ? message.replyTo!.content
                  : _getMediaLabel(message.replyTo!.type),
              style: const TextStyle(color: Colors.white54, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );

  Widget _timeRow({bool dark = false}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            AppHelpers.formatMessageTime(message.timestamp),
            style: TextStyle(
              color: dark ? Colors.white70 : Colors.white60,
              fontSize: 10,
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 3),
            Icon(
              message.isRead ? Icons.done_all : Icons.done,
              size: 14,
              color: message.isRead
                  ? (dark ? Colors.white : Colors.lightBlueAccent)
                  : Colors.white54,
            ),
          ],
          if (message.isEdited) ...[
            const SizedBox(width: 4),
            Text(
              'معدّل',
              style: TextStyle(
                color: dark ? Colors.white54 : Colors.white38,
                fontSize: 10,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      );

  String _getMediaLabel(String type) {
    switch (type) {
      case 'image': return '📷 صورة';
      case 'video': return '🎥 فيديو';
      case 'file':  return '📎 ملف';
      case 'audio': return '🎵 صوت';
      default:      return '';
    }
  }
}
