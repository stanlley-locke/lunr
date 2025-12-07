import 'package:equatable/equatable.dart';
import 'user.dart';

class Message extends Equatable {
  final String id;
  final User sender;
  final String roomId;
  final String content;
  final String messageType;
  final String? fileUrl;
  final int? fileSize;
  final String? thumbnailUrl;
  final Map<String, dynamic>? replyTo;
  final DateTime timestamp;
  final DateTime? editedAt;
  final Map<String, List<String>> reactions;
  final List<Map<String, dynamic>> readBy;

  const Message({
    required this.id,
    required this.sender,
    required this.roomId,
    required this.content,
    this.messageType = 'text',
    this.fileUrl,
    this.fileSize,
    this.thumbnailUrl,
    this.replyTo,
    required this.timestamp,
    this.editedAt,
    this.reactions = const {},
    this.readBy = const [],
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      sender: User.fromJson(json['sender']),
      roomId: json['room'],
      content: json['content'],
      messageType: json['message_type'] ?? 'text',
      fileUrl: json['file_url'],
      fileSize: json['file_size'],
      thumbnailUrl: json['thumbnail_url'],
      replyTo: json['reply_to'],
      timestamp: DateTime.parse(json['timestamp']),
      editedAt: json['edited_at'] != null ? DateTime.parse(json['edited_at']) : null,
      reactions: Map<String, List<String>>.from(
        (json['reactions'] ?? {}).map((k, v) => MapEntry(k, List<String>.from(v)))
      ),
      readBy: List<Map<String, dynamic>>.from(json['read_by'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender.toJson(),
      'room': roomId,
      'content': content,
      'message_type': messageType,
      'file_url': fileUrl,
      'file_size': fileSize,
      'thumbnail_url': thumbnailUrl,
      'reply_to': replyTo,
      'timestamp': timestamp.toIso8601String(),
      'edited_at': editedAt?.toIso8601String(),
      'reactions': reactions,
      'read_by': readBy,
    };
  }

  bool get isEdited => editedAt != null;
  bool get hasReactions => reactions.isNotEmpty;
  bool get hasFile => fileUrl != null && fileUrl!.isNotEmpty;
  bool get isReply => replyTo != null;

  @override
  List<Object?> get props => [
    id, sender, roomId, content, messageType, fileUrl, fileSize,
    thumbnailUrl, replyTo, timestamp, editedAt, reactions, readBy
  ];
}