// lib/models/chat_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatModel {
  final String id;
  final List<String> members;
  final String lastMessage;
  final String lastMessageType;
  final String lastMessageSenderId;
  final DateTime lastMessageTime;
  final Map<String, int> unreadCount;
  final DateTime createdAt;
  final bool isGroup;
  final String groupName;
  final String groupPhoto;
  final String groupDescription;
  final List<String> admins;

  const ChatModel({
    required this.id,
    required this.members,
    this.lastMessage = '',
    this.lastMessageType = 'text',
    this.lastMessageSenderId = '',
    required this.lastMessageTime,
    this.unreadCount = const {},
    required this.createdAt,
    this.isGroup = false,
    this.groupName = '',
    this.groupPhoto = '',
    this.groupDescription = '',
    this.admins = const [],
  });

  factory ChatModel.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return ChatModel(
      id: doc.id,
      members: List<String>.from(m['members'] as List? ?? []),
      lastMessage: m['lastMessage'] as String? ?? '',
      lastMessageType: m['lastMessageType'] as String? ?? 'text',
      lastMessageSenderId: m['lastMessageSenderId'] as String? ?? '',
      lastMessageTime:
          (m['lastMessageTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: Map<String, int>.from(m['unreadCount'] as Map? ?? {}),
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isGroup: m['isGroup'] as bool? ?? false,
      groupName: m['groupName'] as String? ?? '',
      groupPhoto: m['groupPhoto'] as String? ?? '',
      groupDescription: m['groupDescription'] as String? ?? '',
      admins: List<String>.from(m['admins'] as List? ?? []),
    );
  }

  Map<String, dynamic> toMap() => {
        'members': members,
        'lastMessage': lastMessage,
        'lastMessageType': lastMessageType,
        'lastMessageSenderId': lastMessageSenderId,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'unreadCount': unreadCount,
        'createdAt': FieldValue.serverTimestamp(),
        'isGroup': isGroup,
        'groupName': groupName,
        'groupPhoto': groupPhoto,
        'groupDescription': groupDescription,
        'admins': admins,
      };

  ChatModel copyWith({
    String? lastMessage,
    String? lastMessageType,
    String? lastMessageSenderId,
    DateTime? lastMessageTime,
    Map<String, int>? unreadCount,
  }) =>
      ChatModel(
        id: id,
        members: members,
        lastMessage: lastMessage ?? this.lastMessage,
        lastMessageType: lastMessageType ?? this.lastMessageType,
        lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
        lastMessageTime: lastMessageTime ?? this.lastMessageTime,
        unreadCount: unreadCount ?? this.unreadCount,
        createdAt: createdAt,
        isGroup: isGroup,
        groupName: groupName,
        groupPhoto: groupPhoto,
        groupDescription: groupDescription,
        admins: admins,
      );
}
