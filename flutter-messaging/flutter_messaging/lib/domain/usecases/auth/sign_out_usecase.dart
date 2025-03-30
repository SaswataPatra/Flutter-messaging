import 'package:dartz/dartz.dart';

import '../../../core/utils/failure.dart';
import '../../../core/utils/usecase.dart';
import '../../repositories/auth_repository.dart';

class SignOutUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;

  SignOutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.signOut();
  }
} 