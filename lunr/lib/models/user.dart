import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int id;
  final String username;
  final bool onlineStatus;
  final String? lastSeen;

  const User({
    required this.id,
    required this.username,
    required this.onlineStatus,
    this.lastSeen,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      onlineStatus: json['online_status'],
      lastSeen: json['last_seen'],
    );
  }

  @override
  List<Object?> get props => [id, username, onlineStatus, lastSeen];
}