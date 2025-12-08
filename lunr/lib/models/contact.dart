import 'user.dart';

class Contact {
  final int id;
  final User user;
  final String alias;
  final DateTime createdAt;

  Contact({
    required this.id,
    required this.user,
    required this.alias,
    required this.createdAt,
  });

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'],
      user: User.fromJson(json['contact_user']), // Backend sends 'contact_user' object
      alias: json['alias'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
  
  // For local DB
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': user.id,
      'username': user.username,
      'alias': alias,
      'avatar': user.avatar,
      'bio': user.bio,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'],
      user: User(
        id: map['user_id'],
        username: map['username'],
        avatar: map['avatar'],
        bio: map['bio'] ?? '',
        onlineStatus: false, // Default
      ),
      alias: map['alias'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}
