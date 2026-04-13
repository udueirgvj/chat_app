// lib/widgets/chat_list_tile.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/helpers.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class ChatListTile extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;

  const ChatListTile({
    super.key,
    required this.chat,
    required this.currentUserId,
  });

  String get _otherUserId => chat.members
      .firstWhere((id) => id != currentUserId, orElse: () => '');

  @override
  Widget build(BuildContext context) {
    final unread = chat.unreadCount[currentUserId] ?? 0;

    if (chat.isGroup) {
      return _buildTile(
        context: context,
        name: chat.groupName,
        photoUrl: chat.groupPhoto,
        unread: unread,
        otherUserId: '',
      );
    }

    return StreamBuilder<UserModel?>(
      stream: AuthService.instance.streamUser(_otherUserId),
      builder: (context, snap) {
        final other = snap.data;
        return _buildTile(
          context: context,
          name: other?.name ?? '...',
          photoUrl: other?.photoUrl ?? '',
          isOnline: other?.isOnline ?? false,
          unread: unread,
          otherUserId: _otherUserId,
          otherUser: other,
        );
      },
    );
  }

  Widget _buildTile({
    required BuildContext context,
    required String name,
    required String photoUrl,
    required int unread,
    required String otherUserId,
    bool isOnline = false,
    UserModel? otherUser,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppTheme.primary,
            backgroundImage: photoUrl.isNotEmpty
                ? NetworkImage(photoUrl)
                : null,
            child: photoUrl.isEmpty
                ? Text(
                    AppHelpers.getInitials(name),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16),
                  )
                : null,
          ),
          if (isOnline)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: Colors.greenAccent,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: AppTheme.scaffoldDark, width: 2),
                ),
              ),
            ),
        ],
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: TextStyle(
                color: Colors.white,
                fontWeight:
                    unread > 0 ? FontWeight.w700 : FontWeight.w500,
                fontSize: 15,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            AppHelpers.formatMessageTime(chat.lastMessageTime),
            style: TextStyle(
              color: unread > 0
                  ? AppTheme.primary
                  : const Color(0xFF8797A7),
              fontSize: 11,
              fontWeight:
                  unread > 0 ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          if (chat.lastMessageSenderId == currentUserId) ...[
            Icon(
              Icons.done_all,
              size: 14,
              color: chat.lastMessageType == 'text'
                  ? const Color(0xFF8797A7)
                  : AppTheme.primary,
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              _lastMsgPreview(),
              style: TextStyle(
                color: unread > 0
                    ? const Color(0xFFCCCCCC)
                    : const Color(0xFF8797A7),
                fontSize: 13,
                fontWeight:
                    unread > 0 ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (unread > 0)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(
                  horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                unread > 99 ? '99+' : '$unread',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
      onTap: () => context.push('/chat/${chat.id}', extra: {
        'otherUserId': otherUserId,
        'otherUserName': name,
        'otherUserPhoto': photoUrl,
        'isGroup': chat.isGroup,
      }),
    );
  }

  String _lastMsgPreview() {
    if (chat.lastMessage.isEmpty) return 'ابدأ المحادثة...';
    switch (chat.lastMessageType) {
      case 'image': return '📷 صورة';
      case 'video': return '🎥 فيديو';
      case 'file':  return '📎 ملف';
      case 'audio': return '🎵 رسالة صوتية';
      default:      return chat.lastMessage;
    }
  }
}
