// lib/screens/chat/chat_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mime/mime.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/helpers.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/chat_input_bar.dart';
import '../../widgets/reply_preview.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserPhoto;
  final bool isGroup;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserPhoto,
    this.isGroup = false,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver {
  final _scrollController = ScrollController();
  final _inputCtrl = TextEditingController();
  final _imagePicker = ImagePicker();

  late final String _myId;
  UserModel? _otherUser;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _myId = AuthService.instance.currentUser!.uid;
    _markRead();
    if (!widget.isGroup) _listenOtherUser();
  }

  void _listenOtherUser() {
    AuthService.instance.streamUser(widget.otherUserId).listen((u) {
      if (mounted) setState(() => _otherUser = u);
    });
  }

  void _markRead() {
    ChatService.instance.markAsRead(chatId: widget.chatId, userId: _myId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    _inputCtrl.dispose();
    super.dispose();
  }

  // ─── Send Text ──────────────────────────────────────
  Future<void> _sendText() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    _inputCtrl.clear();
    await context.read<ChatProvider>().sendText(
          chatId: widget.chatId,
          content: text,
          memberIds: [_myId, widget.otherUserId],
        );
    _scrollToBottom();
  }

  // ─── Pick Image ─────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    final file = await _imagePicker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1280,
    );
    if (file == null || !mounted) return;
    await context.read<ChatProvider>().sendImage(
          chatId: widget.chatId,
          file: File(file.path),
          memberIds: [_myId, widget.otherUserId],
        );
    _scrollToBottom();
  }

  // ─── Pick File ──────────────────────────────────────
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final path = result.files.first.path;
    if (path == null) return;
    final mime = lookupMimeType(path) ?? 'application/octet-stream';
    await context.read<ChatProvider>().sendFile(
          chatId: widget.chatId,
          file: File(path),
          mimeType: mime,
          memberIds: [_myId, widget.otherUserId],
        );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── Message Long-Press ─────────────────────────────
  void _showMessageOptions(MessageModel msg) {
    final isMine = msg.senderId == _myId;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply, color: AppTheme.primary),
              title: const Text('رد'),
              onTap: () {
                Navigator.pop(context);
                context.read<ChatProvider>().setReplyTo(msg);
              },
            ),
            if (msg.type == 'text')
              ListTile(
                leading: const Icon(Icons.copy, color: Colors.white70),
                title: const Text('نسخ'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(ClipboardData(text: msg.content));
                  AppHelpers.showSnackBar(context, 'تم النسخ');
                },
              ),
            if (isMine)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('حذف', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _deleteDialog(msg);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _deleteDialog(MessageModel msg) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('حذف الرسالة'),
        content: const Text('كيف تريد الحذف؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChatProvider>().deleteMessage(
                    chatId: widget.chatId,
                    messageId: msg.id,
                    deleteForEveryone: false,
                  );
            },
            child: const Text('حذف لديّ'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<ChatProvider>().deleteMessage(
                    chatId: widget.chatId,
                    messageId: msg.id,
                    deleteForEveryone: true,
                  );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف للجميع'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final displayName = widget.isGroup
        ? widget.otherUserName
        : (_otherUser?.name ?? widget.otherUserName);
    final photoUrl = widget.isGroup
        ? widget.otherUserPhoto
        : (_otherUser?.photoUrl ?? widget.otherUserPhoto);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primary,
              backgroundImage: photoUrl.isNotEmpty
                  ? NetworkImage(photoUrl)
                  : null,
              child: photoUrl.isEmpty
                  ? Text(
                      AppHelpers.getInitials(displayName),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (!widget.isGroup && _otherUser != null)
                    Text(
                      _otherUser!.isOnline
                          ? 'متصل الآن'
                          : AppHelpers.timeAgo(_otherUser!.lastSeen),
                      style: TextStyle(
                        fontSize: 11,
                        color: _otherUser!.isOnline
                            ? Colors.greenAccent
                            : const Color(0xFF8797A7),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call_outlined),   onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert),       onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Upload progress bar
          if (chatProvider.isSending && chatProvider.uploadProgress > 0)
            LinearProgressIndicator(
              value: chatProvider.uploadProgress,
              backgroundColor: AppTheme.cardDark,
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
            ),

          // Messages list
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: ChatService.instance.streamMessages(widget.chatId),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final msgs = snap.data ?? [];
                if (msgs.isEmpty) {
                  return const Center(
                    child: Text(
                      'ابدأ المحادثة الآن 👋',
                      style: TextStyle(color: Color(0xFF8797A7), fontSize: 15),
                    ),
                  );
                }
                _markRead();
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 12),
                  itemCount: msgs.length,
                  itemBuilder: (_, i) {
                    final msg = msgs[i];
                    final showDate = i == msgs.length - 1 ||
                        !_sameDay(msgs[i].timestamp,
                            msgs[i + 1].timestamp);
                    return Column(
                      children: [
                        if (showDate) _buildDateSeparator(msg.timestamp),
                        MessageBubble(
                          message: msg,
                          isMe: msg.senderId == _myId,
                          onLongPress: () => _showMessageOptions(msg),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Reply preview
          if (chatProvider.replyTo != null)
            ReplyPreview(
              message: chatProvider.replyTo!,
              onCancel: () => context.read<ChatProvider>().setReplyTo(null),
            ),

          // Input bar
          ChatInputBar(
            controller: _inputCtrl,
            isSending: chatProvider.isSending,
            onSend: _sendText,
            onImageCamera: () => _pickImage(ImageSource.camera),
            onImageGallery: () => _pickImage(ImageSource.gallery),
            onFile: _pickFile,
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Widget _buildDateSeparator(DateTime dt) {
    final now = DateTime.now();
    String label;
    if (_sameDay(dt, now)) {
      label = 'اليوم';
    } else if (_sameDay(dt, now.subtract(const Duration(days: 1)))) {
      label = 'أمس';
    } else {
      label = AppHelpers.formatMessageTime(dt);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: const TextStyle(
                color: Color(0xFF8797A7), fontSize: 12),
          ),
        ),
      ),
    );
  }
}
