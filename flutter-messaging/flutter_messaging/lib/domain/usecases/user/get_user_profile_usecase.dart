import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../core/utils/failure.dart';
import '../../../core/utils/usecase.dart';
import '../../entities/user.dart';
import '../../repositories/user_repository.dart';

class GetUserProfileUseCase implements UseCase<User, GetUserProfileParams> {
  final UserRepository repository;

  GetUserProfileUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(GetUserProfileParams params) async {
    return await repository.getUserProfile(userId: params.userId);
  }
}

class GetUserProfileParams extends Equatable {
  final String userId;

  const GetUserProfileParams({required this.userId});

  @override
  List<Object> get props => [userId];
} 