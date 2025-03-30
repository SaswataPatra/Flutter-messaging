import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../core/utils/failure.dart';
import '../../../core/utils/usecase.dart';
import '../../repositories/user_repository.dart';

class UpdateUserStatusUseCase implements UseCase<void, UpdateUserStatusParams> {
  final UserRepository repository;

  UpdateUserStatusUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateUserStatusParams params) async {
    return await repository.updateUserStatus(isOnline: params.isOnline);
  }
}

class UpdateUserStatusParams extends Equatable {
  final bool isOnline;

  const UpdateUserStatusParams({required this.isOnline});

  @override
  List<Object> get props => [isOnline];
} 