// lib/services/chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_model.dart';
import '../models/message_model.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/helpers.dart';

class ChatService {
  ChatService._();
  static final ChatService instance = ChatService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Get or Create Chat ────────────────────────────
  Future<String> getOrCreateChat({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final chatId = AppHelpers.generateChatId(currentUserId, otherUserId);
    final ref = _db.collection(AppConstants.chatsCollection).doc(chatId);
    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        'members': [currentUserId, otherUserId],
        'lastMessage': '',
        'lastMessageType': 'text',
        'lastMessageSenderId': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': {currentUserId: 0, otherUserId: 0},
        'createdAt': FieldValue.serverTimestamp(),
        'isGroup': false,
        'groupName': '',
        'groupPhoto': '',
        'groupDescription': '',
        'admins': [],
      });
    }
    return chatId;
  }

  // ─── Send Message ──────────────────────────────────
  Future<void> sendMessage({
    required String chatId,
    required MessageModel message,
    required List<String> memberIds,
    required String currentUserId,
  }) async {
    final batch = _db.batch();

    // Add message
    final msgRef = _db
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .doc();

    batch.set(msgRef, message.toMap());

    // Update chat metadata + increment unread for others
    final chatRef = _db.collection(AppConstants.chatsCollection).doc(chatId);

    final unreadUpdate = <String, dynamic>{};
    for (final uid in memberIds) {
      if (uid != currentUserId) {
        unreadUpdate['unreadCount.$uid'] = FieldValue.increment(1);
      }
    }

    batch.update(chatRef, {
      'lastMessage': message.type == 'text'
          ? message.content
          : _getMediaLabel(message.type),
      'lastMessageType': message.type,
      'lastMessageSenderId': message.senderId,
      'lastMessageTime': FieldValue.serverTimestamp(),
      ...unreadUpdate,
    });

    await batch.commit();
  }

  // ─── Mark Messages as Read ─────────────────────────
  Future<void> markAsRead({
    required String chatId,
    required String userId,
  }) async {
    // Reset unread count
    await _db.collection(AppConstants.chatsCollection).doc(chatId).update({
      'unreadCount.$userId': 0,
    });

    // Mark unread messages as read
    final unread = await _db
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .where('isRead', isEqualTo: false)
        .where('senderId', isNotEqualTo: userId)
        .limit(50)
        .get();

    if (unread.docs.isEmpty) return;

    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readBy': FieldValue.arrayUnion([userId]),
      });
    }
    await batch.commit();
  }

  // ─── Delete Message ────────────────────────────────
  Future<void> deleteMessage({
    required String chatId,
    required String messageId,
    bool deleteForEveryone = false,
  }) async {
    final ref = _db
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .doc(messageId);

    if (deleteForEveryone) {
      await ref.update({
        'isDeleted': true,
        'content': '',
        'mediaUrl': null,
      });
    } else {
      await ref.delete();
    }
  }

  // ─── Edit Message ──────────────────────────────────
  Future<void> editMessage({
    required String chatId,
    required String messageId,
    required String newContent,
  }) async {
    await _db
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .doc(messageId)
        .update({'content': newContent, 'isEdited': true});
  }

  // ─── Stream Chats ──────────────────────────────────
  Stream<List<ChatModel>> streamChats(String userId) {
    return _db
        .collection(AppConstants.chatsCollection)
        .where('members', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ChatModel.fromDoc).toList());
  }

  // ─── Stream Messages ───────────────────────────────
  Stream<List<MessageModel>> streamMessages(String chatId) {
    return _db
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .orderBy('timestamp', descending: true)
        .limit(AppConstants.messagePageSize)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MessageModel.fromDoc(d, chatId)).toList());
  }

  // ─── Load More Messages (Pagination) ──────────────
  Future<List<MessageModel>> loadMoreMessages({
    required String chatId,
    required DocumentSnapshot lastDoc,
  }) async {
    final snap = await _db
        .collection(AppConstants.chatsCollection)
        .doc(chatId)
        .collection(AppConstants.messagesCollection)
        .orderBy('timestamp', descending: true)
        .startAfterDocument(lastDoc)
        .limit(AppConstants.messagePageSize)
        .get();
    return snap.docs.map((d) => MessageModel.fromDoc(d, chatId)).toList();
  }

  // ─── Update Typing Status ──────────────────────────
  Future<void> setTyping({
    required String chatId,
    required String userId,
    required bool isTyping,
  }) async {
    await _db.collection(AppConstants.chatsCollection).doc(chatId).update({
      'typing.$userId': isTyping,
    });
  }

  // ─── Create Group ──────────────────────────────────
  Future<String> createGroup({
    required String name,
    required String description,
    required List<String> memberIds,
    required String adminId,
    String photoUrl = '',
  }) async {
    final ref = _db.collection(AppConstants.chatsCollection).doc();
    await ref.set({
      'members': memberIds,
      'lastMessage': 'تم إنشاء المجموعة',
      'lastMessageType': 'text',
      'lastMessageSenderId': adminId,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'unreadCount': {for (final uid in memberIds) uid: 0},
      'createdAt': FieldValue.serverTimestamp(),
      'isGroup': true,
      'groupName': name,
      'groupPhoto': photoUrl,
      'groupDescription': description,
      'admins': [adminId],
    });
    return ref.id;
  }

  String _getMediaLabel(String type) {
    switch (type) {
      case 'image': return '📷 صورة';
      case 'video': return '🎥 فيديو';
      case 'file':  return '📎 ملف';
      case 'audio': return '🎵 رسالة صوتية';
      default:      return 'رسالة';
    }
  }
}
