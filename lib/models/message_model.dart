// lib/models/message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ReplyData {
  final String messageId;
  final String senderId;
  final String senderName;
  final String content;
  final String type;

  const ReplyData({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
  });

  factory ReplyData.fromMap(Map<String, dynamic> m) => ReplyData(
        messageId: m['messageId'] as String? ?? '',
        senderId: m['senderId'] as String? ?? '',
        senderName: m['senderName'] as String? ?? '',
        content: m['content'] as String? ?? '',
        type: m['type'] as String? ?? 'text',
      );

  Map<String, dynamic> toMap() => {
        'messageId': messageId,
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'type': type,
      };
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String senderName;
  final String content;
  final String type; // text | image | video | file | audio
  final String? mediaUrl;
  final String? fileName;
  final int? fileSize;
  final int? audioDuration; // seconds
  final String? thumbnailUrl;
  final bool isRead;
  final List<String> readBy;
  final DateTime timestamp;
  final bool isDeleted;
  final ReplyData? replyTo;
  final bool isEdited;

  const MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.type,
    this.mediaUrl,
    this.fileName,
    this.fileSize,
    this.audioDuration,
    this.thumbnailUrl,
    this.isRead = false,
    this.readBy = const [],
    required this.timestamp,
    this.isDeleted = false,
    this.replyTo,
    this.isEdited = false,
  });

  factory MessageModel.fromDoc(DocumentSnapshot doc, String chatId) {
    final m = doc.data() as Map<String, dynamic>;
    return MessageModel(
      id: doc.id,
      chatId: chatId,
      senderId: m['senderId'] as String? ?? '',
      senderName: m['senderName'] as String? ?? '',
      content: m['content'] as String? ?? '',
      type: m['type'] as String? ?? 'text',
      mediaUrl: m['mediaUrl'] as String?,
      fileName: m['fileName'] as String?,
      fileSize: m['fileSize'] as int?,
      audioDuration: m['audioDuration'] as int?,
      thumbnailUrl: m['thumbnailUrl'] as String?,
      isRead: m['isRead'] as bool? ?? false,
      readBy: List<String>.from(m['readBy'] as List? ?? []),
      timestamp: (m['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isDeleted: m['isDeleted'] as bool? ?? false,
      replyTo: m['replyTo'] != null
          ? ReplyData.fromMap(m['replyTo'] as Map<String, dynamic>)
          : null,
      isEdited: m['isEdited'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'senderId': senderId,
        'senderName': senderName,
        'content': content,
        'type': type,
        if (mediaUrl != null) 'mediaUrl': mediaUrl,
        if (fileName != null) 'fileName': fileName,
        if (fileSize != null) 'fileSize': fileSize,
        if (audioDuration != null) 'audioDuration': audioDuration,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        'isRead': isRead,
        'readBy': readBy,
        'timestamp': FieldValue.serverTimestamp(),
        'isDeleted': isDeleted,
        if (replyTo != null) 'replyTo': replyTo!.toMap(),
        'isEdited': isEdited,
      };
}
