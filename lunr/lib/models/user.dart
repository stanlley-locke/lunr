import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String username;
  final String? avatar;
  final String bio;
  final String statusMessage;
  final bool onlineStatus;
  final String? lastSeen;
  final bool isVerified;
  final bool showLastSeen;
  final bool showReadReceipts;
  final bool showProfilePhoto;

  const User({
    required this.id,
    required this.username,
    this.avatar,
    this.bio = '',
    this.statusMessage = '',
    required this.onlineStatus,
    this.lastSeen,
    this.isVerified = false,
    this.showLastSeen = true,
    this.showReadReceipts = true,
    this.showProfilePhoto = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      avatar: json['avatar'],
      bio: json['bio'] ?? '',
      statusMessage: json['status_message'] ?? '',
      onlineStatus: json['online_status'] ?? false,
      lastSeen: json['last_seen'],
      isVerified: json['is_verified'] ?? false,
      showLastSeen: json['show_last_seen'] ?? true,
      showReadReceipts: json['show_read_receipts'] ?? true,
      showProfilePhoto: json['show_profile_photo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar': avatar,
      'bio': bio,
      'status_message': statusMessage,
      'online_status': onlineStatus,
      'last_seen': lastSeen,
      'is_verified': isVerified,
      'show_last_seen': showLastSeen,
      'show_read_receipts': showReadReceipts,
      'show_profile_photo': showProfilePhoto,
    };
  }

  User copyWith({
    int? id,
    String? username,
    String? avatar,
    String? bio,
    String? statusMessage,
    bool? onlineStatus,
    String? lastSeen,
    bool? isVerified,
    bool? showLastSeen,
    bool? showReadReceipts,
    bool? showProfilePhoto,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      bio: bio ?? this.bio,
      statusMessage: statusMessage ?? this.statusMessage,
      onlineStatus: onlineStatus ?? this.onlineStatus,
      lastSeen: lastSeen ?? this.lastSeen,
      isVerified: isVerified ?? this.isVerified,
      showLastSeen: showLastSeen ?? this.showLastSeen,
      showReadReceipts: showReadReceipts ?? this.showReadReceipts,
      showProfilePhoto: showProfilePhoto ?? this.showProfilePhoto,
    );
  }

  @override
  List<Object?> get props => [
    id, username, avatar, bio, statusMessage, onlineStatus, 
    lastSeen, isVerified, showLastSeen, showReadReceipts, showProfilePhoto
  ];
}