// lib/providers/chat_provider.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/storage_service.dart';
import '../core/constants/app_constants.dart';

class ChatProvider extends ChangeNotifier {
  final _uuid = const Uuid();
  bool _isSending = false;
  double _uploadProgress = 0;
  MessageModel? _replyTo;

  bool   get isSending      => _isSending;
  double get uploadProgress => _uploadProgress;
  MessageModel? get replyTo => _replyTo;

  void setReplyTo(MessageModel? msg) {
    _replyTo = msg;
    notifyListeners();
  }

  // ─── Send Text ─────────────────────────────────────
  Future<void> sendText({
    required String chatId,
    required String content,
    required List<String> memberIds,
  }) async {
    final me = AuthService.instance.currentUser!;
    final msg = MessageModel(
      id: _uuid.v4(),
      chatId: chatId,
      senderId: me.uid,
      senderName: me.displayName ?? '',
      content: content.trim(),
      type: AppConstants.msgText,
      timestamp: DateTime.now(),
      replyTo: _replyTo != null
          ? ReplyData(
              messageId: _replyTo!.id,
              senderId: _replyTo!.senderId,
              senderName: _replyTo!.senderName,
              content: _replyTo!.content,
              type: _replyTo!.type,
            )
          : null,
    );
    _replyTo = null;
    notifyListeners();
    await ChatService.instance.sendMessage(
      chatId: chatId,
      message: msg,
      memberIds: memberIds,
      currentUserId: me.uid,
    );
  }

  // ─── Send Image ────────────────────────────────────
  Future<void> sendImage({
    required String chatId,
    required File file,
    required List<String> memberIds,
  }) async {
    _isSending = true;
    notifyListeners();
    try {
      final me = AuthService.instance.currentUser!;
      final url = await StorageService.instance.uploadChatImage(
        chatId: chatId,
        file: file,
      );
      final msg = MessageModel(
        id: _uuid.v4(),
        chatId: chatId,
        senderId: me.uid,
        senderName: me.displayName ?? '',
        content: '📷 صورة',
        type: AppConstants.msgImage,
        mediaUrl: url,
        timestamp: DateTime.now(),
      );
      await ChatService.instance.sendMessage(
        chatId: chatId,
        message: msg,
        memberIds: memberIds,
        currentUserId: me.uid,
      );
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // ─── Send File ─────────────────────────────────────
  Future<void> sendFile({
    required String chatId,
    required File file,
    required String mimeType,
    required List<String> memberIds,
  }) async {
    _isSending = true;
    _uploadProgress = 0;
    notifyListeners();
    try {
      final me = AuthService.instance.currentUser!;
      final result = await StorageService.instance.uploadChatFile(
        chatId: chatId,
        file: file,
        mimeType: mimeType,
        onProgress: (p) {
          _uploadProgress = p;
          notifyListeners();
        },
      );
      final msg = MessageModel(
        id: _uuid.v4(),
        chatId: chatId,
        senderId: me.uid,
        senderName: me.displayName ?? '',
        content: result['fileName'] as String,
        type: AppConstants.msgFile,
        mediaUrl: result['url'] as String,
        fileName: result['fileName'] as String,
        fileSize: result['fileSize'] as int,
        timestamp: DateTime.now(),
      );
      await ChatService.instance.sendMessage(
        chatId: chatId,
        message: msg,
        memberIds: memberIds,
        currentUserId: me.uid,
      );
    } finally {
      _isSending = false;
      _uploadProgress = 0;
      notifyListeners();
    }
  }

  // ─── Send Audio ────────────────────────────────────
  Future<void> sendAudio({
    required String chatId,
    required File file,
    required int duration,
    required List<String> memberIds,
  }) async {
    _isSending = true;
    notifyListeners();
    try {
      final me = AuthService.instance.currentUser!;
      final url = await StorageService.instance.uploadAudioMessage(
        chatId: chatId,
        file: file,
      );
      final msg = MessageModel(
        id: _uuid.v4(),
        chatId: chatId,
        senderId: me.uid,
        senderName: me.displayName ?? '',
        content: '🎵 رسالة صوتية',
        type: AppConstants.msgAudio,
        mediaUrl: url,
        audioDuration: duration,
        timestamp: DateTime.now(),
      );
      await ChatService.instance.sendMessage(
        chatId: chatId,
        message: msg,
        memberIds: memberIds,
        currentUserId: me.uid,
      );
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  // ─── Delete Message ────────────────────────────────
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    bool deleteForEveryone = false,
  }) async {
    await ChatService.instance.deleteMessage(
      chatId: chatId,
      messageId: messageId,
      deleteForEveryone: deleteForEveryone,
    );
  }
}
