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
  
  // Backwards compatibility for code that doesn't have userId yet
  // This might return a suboptimal name for direct chats
  String get displayName {
    if (isGroup) return name.isNotEmpty ? name : 'Group Chat';
    if (members.isNotEmpty) {
      // Just pick the first other member? Or just the first member?
      // Without userId, we can't know who is "other".
      // We'll return the name of the first member.
      return members.first.user.username;
    }
    return 'Chat';
  }

  String getDisplayName(int currentUserId) {
    if (isGroup) {
      return name.isNotEmpty ? name : 'Group Chat';
    } else {
      final otherMember = members.firstWhere(
        (m) => m.user.id != currentUserId,
        orElse: () => members.isNotEmpty ? members.first : RoomMembership(
          user: User(id: 0, username: 'Unknown', onlineStatus: false),
          role: 'member',
          joinedAt: DateTime.now(),
        ),
      );
      return otherMember.user.username;
    }
  }

  String? getAvatarUrl(int currentUserId) {
    if (isGroup) {
      return avatar;
    } else {
      final otherMember = members.firstWhere(
        (m) => m.user.id != currentUserId,
        orElse: () => members.isNotEmpty ? members.first : RoomMembership(
          user: User(id: 0, username: 'Unknown', onlineStatus: false),
          role: 'member',
          joinedAt: DateTime.now(),
        ),
      );
      return otherMember.user.avatar;
    }
  }

  bool isArchivedFor(int userId) {
    if (members.isEmpty) return false;
    try {
      final membership = members.firstWhere((m) => m.user.id == userId);
      return membership.isArchived;
    } catch (e) {
      return false;
    }
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

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'role': role,
      'joined_at': joinedAt.toIso8601String(),
      'is_muted': isMuted,
      'is_archived': isArchived,
    };
  }

  @override
  List<Object?> get props => [user, role, joinedAt, isMuted, isArchived];
}