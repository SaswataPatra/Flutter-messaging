import 'package:dartz/dartz.dart';

import '../../core/utils/failure.dart';
import '../entities/message.dart';

abstract class MessageRepository {
  // Send a message
  Future<Either<Failure, Message>> sendMessage({
    required String receiverId,
    required String content,
    required MessageType type,
  });
  
  // Get messages between current user and receiver
  Future<Either<Failure, Stream<List<Message>>>> getMessages({
    required String receiverId,
    int limit = 30,
  });
  
  // Update message status
  Future<Either<Failure, void>> updateMessageStatus({
    required String messageId,
    required MessageStatus status,
  });
  
  // Delete a message
  Future<Either<Failure, void>> deleteMessage({
    required String messageId,
  });
  
  // Get unread message count
  Future<Either<Failure, Stream<int>>> getUnreadMessageCount({
    required String userId,
  });
  
  // Mark all messages as read
  Future<Either<Failure, void>> markAllMessagesAsRead({
    required String senderId,
  });
} 