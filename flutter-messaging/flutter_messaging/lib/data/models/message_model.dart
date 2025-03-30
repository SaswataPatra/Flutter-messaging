import '../../domain/entities/message.dart';

class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.senderId,
    required super.receiverId,
    required super.content,
    required super.type,
    required super.status,
    required super.timestamp,
    super.isDeleted,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      content: json['content'],
      type: MessageType.values.byName(json['type']),
      status: MessageStatus.values.byName(json['status']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      isDeleted: json['isDeleted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.name,
      'status': status.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isDeleted': isDeleted,
    };
  }

  factory MessageModel.fromEntity(Message message) {
    return MessageModel(
      id: message.id,
      senderId: message.senderId,
      receiverId: message.receiverId,
      content: message.content,
      type: message.type,
      status: message.status,
      timestamp: message.timestamp,
      isDeleted: message.isDeleted,
    );
  }
} 