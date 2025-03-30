import 'package:equatable/equatable.dart';

enum MessageStatus { sent, delivered, read }

enum MessageType { text, image, audio, video }

class Message extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final MessageStatus status;
  final DateTime timestamp;
  final bool isDeleted;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.status,
    required this.timestamp,
    this.isDeleted = false,
  });

  @override
  List<Object?> get props => [
        id,
        senderId,
        receiverId,
        content,
        type,
        status,
        timestamp,
        isDeleted,
      ];
} 