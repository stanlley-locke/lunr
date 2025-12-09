import 'package:equatable/equatable.dart';
import 'user.dart';
import 'message.dart';

class ChatRoom extends Equatable {
  final String id;
  final String name;
  final String description;
  final String roomType;
  final String? avatar;
  final bool isPrivate;
  final int maxMembers;
  final DateTime createdAt;
  final List<RoomMembership> members;

  // Helper to check if the current user has archived this chat
  // Requires passing current userId because ChatRoom doesn't know "who" is viewing it
  bool isArchivedFor(int userId) {
    if (members.isEmpty) return false;
    try {
      final membership = members.firstWhere((m) => m.user.id == userId);
      return membership.isArchived;
    } catch (e) {
      return false;
    }
  }

  final int memberCount;
  final int unreadCount;
  final Message? lastMessage;

  const ChatRoom({
    required this.id,
    this.name = '',
    this.description = '',
    this.roomType = 'direct',
    this.avatar,
    this.isPrivate = false,
    this.maxMembers = 100,
    required this.createdAt,
    this.members = const [],
    this.memberCount = 0,
    this.unreadCount = 0,
    this.lastMessage,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      roomType: json['room_type'] ?? 'direct',
      avatar: json['avatar'],
      isPrivate: json['is_private'] ?? false,
      maxMembers: json['max_members'] ?? 100,
      createdAt: DateTime.parse(json['created_at']),
      members: (json['members'] as List?)
          ?.map((m) => RoomMembership.fromJson(m))
          .toList() ?? [],
      memberCount: json['member_count'] ?? 0,
      unreadCount: json['unread_count'] ?? 0,
      lastMessage: json['last_message'] != null 
          ? Message.fromJson(json['last_message']) 
          : null,
    );
  }

  bool get isGroup => roomType == 'group';
  bool get isDirect => roomType == 'direct';
  
  // Deprecated: use getDisplayName
  String get displayName {
    if (isGroup) return name.isNotEmpty ? name : 'Group Chat';
    if (members.isNotEmpty) {
      return members.first.user.username;
    }
    return 'Chat';
  }

  String getDisplayName(int currentUserId) {
    if (isGroup) return name.isNotEmpty ? name : 'Group Chat';
    
    // For direct chat, find the OTHER user
    if (members.isNotEmpty) {
      final otherMember = members.firstWhere(
        (m) => m.user.id != currentUserId,
        orElse: () => members.first,
      );
      return otherMember.user.username;
    }
    return 'Chat';
  }

  @override
  List<Object?> get props => [
    id, name, description, roomType, avatar, isPrivate,
    maxMembers, createdAt, members, memberCount, unreadCount, lastMessage
  ];
}

class RoomMembership extends Equatable {
  final User user;
  final String role;
  final DateTime joinedAt;
  final bool isMuted;
  final bool isArchived;

  const RoomMembership({
    required this.user,
    this.role = 'member',
    required this.joinedAt,
    this.isMuted = false,
    this.isArchived = false,
  });

  factory RoomMembership.fromJson(Map<String, dynamic> json) {
    return RoomMembership(
      user: User.fromJson(json['user']),
      role: json['role'] ?? 'member',
      joinedAt: DateTime.parse(json['joined_at']),
      isMuted: json['is_muted'] ?? false,
      isArchived: json['is_archived'] ?? false,
    );
  }

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
      'is_muted': isMuted,
    };
  }


  @override
  List<Object?> get props => [user, role, joinedAt, isMuted];
}