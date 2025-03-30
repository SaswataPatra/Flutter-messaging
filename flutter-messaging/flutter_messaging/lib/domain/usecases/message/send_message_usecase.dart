import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../core/utils/failure.dart';
import '../../../core/utils/usecase.dart';
import '../../entities/message.dart';
import '../../repositories/message_repository.dart';

class SendMessageUseCase implements UseCase<Message, SendMessageParams> {
  final MessageRepository repository;

  SendMessageUseCase(this.repository);

  @override
  Future<Either<Failure, Message>> call(SendMessageParams params) async {
    return await repository.sendMessage(
      receiverId: params.receiverId,
      content: params.content,
      type: params.type,
    );
  }
}

class SendMessageParams extends Equatable {
  final String receiverId;
  final String content;
  final MessageType type;

  const SendMessageParams({
    required this.receiverId,
    required this.content,
    required this.type,
  });

  @override
  List<Object> get props => [receiverId, content, type];
} 