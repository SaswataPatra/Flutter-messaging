import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../core/utils/failure.dart';
import '../../../core/utils/usecase.dart';
import '../../entities/message.dart';
import '../../repositories/message_repository.dart';

class GetMessagesUseCase implements UseCase<Stream<List<Message>>, GetMessagesParams> {
  final MessageRepository repository;

  GetMessagesUseCase(this.repository);

  @override
  Future<Either<Failure, Stream<List<Message>>>> call(GetMessagesParams params) async {
    return await repository.getMessages(
      receiverId: params.receiverId,
      limit: params.limit,
    );
  }
}

class GetMessagesParams extends Equatable {
  final String receiverId;
  final int limit;

  const GetMessagesParams({
    required this.receiverId,
    this.limit = 30,
  });

  @override
  List<Object> get props => [receiverId, limit];
} 