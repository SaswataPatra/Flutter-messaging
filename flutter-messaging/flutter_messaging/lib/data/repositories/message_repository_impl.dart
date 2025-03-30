import 'package:dartz/dartz.dart';

import '../../core/network/network_info.dart';
import '../../core/utils/failure.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/message_data_source.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageDataSource messageDataSource;
  final NetworkInfo networkInfo;

  MessageRepositoryImpl({
    required this.messageDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Message>> sendMessage({
    required String receiverId,
    required String content,
    required MessageType type,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final message = await messageDataSource.sendMessage(
          receiverId: receiverId,
          content: content,
          type: type,
        );
        return Right(message);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Stream<List<Message>>>> getMessages({
    required String receiverId,
    int limit = 30,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final messagesStream = messageDataSource.getMessages(
          receiverId: receiverId,
          limit: limit,
        );
        return Right(messagesStream);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> updateMessageStatus({
    required String messageId,
    required MessageStatus status,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await messageDataSource.updateMessageStatus(
          messageId: messageId,
          status: status,
        );
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage({
    required String messageId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await messageDataSource.deleteMessage(messageId: messageId);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Stream<int>>> getUnreadMessageCount({
    required String userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final countStream = messageDataSource.getUnreadMessageCount(userId: userId);
        return Right(countStream);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> markAllMessagesAsRead({
    required String senderId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await messageDataSource.markAllMessagesAsRead(senderId: senderId);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'No internet connection'));
    }
  }
} 