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
      lastMessage: json['last_message'] != null 
          ? Message.fromJson(json['last_message']) 
          : null,
    );
  }

  bool get isGroup => roomType == 'group';
  bool get isDirect => roomType == 'direct';
  
  String get displayName {
    if (isGroup) return name.isNotEmpty ? name : 'Group Chat';
    if (members.isNotEmpty) {
      return members.first.user.username;
    }
    return 'Chat';
  }

  @override
  List<Object?> get props => [
    id, name, description, roomType, avatar, isPrivate,
    maxMembers, createdAt, members, memberCount, lastMessage
  ];
}

class RoomMembership extends Equatable {
  final User user;
  final String role;
  final DateTime joinedAt;
  final bool isMuted;

  const RoomMembership({
    required this.user,
    this.role = 'member',
    required this.joinedAt,
    this.isMuted = false,
  });

  factory RoomMembership.fromJson(Map<String, dynamic> json) {
    return RoomMembership(
      user: User.fromJson(json['user']),
      role: json['role'] ?? 'member',
      joinedAt: DateTime.parse(json['joined_at']),
      isMuted: json['is_muted'] ?? false,
    );
  }

  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props => [user, role, joinedAt, isMuted];
}