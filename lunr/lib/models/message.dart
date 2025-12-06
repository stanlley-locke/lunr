import 'package:equatable/equatable.dart';
import 'user.dart';

class Message extends Equatable {
  final int id;
  final int senderId;
  final String content;
  final DateTime timestamp;
  final bool isRead;

  const Message({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    required this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      senderId: json['sender'],
      content: json['content'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['is_read'],
    );
  }

  @override
  List<Object?> get props => [id, senderId, content, timestamp, isRead];
}