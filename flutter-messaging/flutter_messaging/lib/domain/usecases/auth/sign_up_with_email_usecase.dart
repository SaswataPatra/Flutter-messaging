import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../core/utils/failure.dart';
import '../../../core/utils/usecase.dart';
import '../../entities/user.dart';
import '../../repositories/auth_repository.dart';

class SignUpWithEmailUseCase implements UseCase<User, SignUpWithEmailParams> {
  final AuthRepository repository;

  SignUpWithEmailUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(SignUpWithEmailParams params) async {
    return await repository.signUpWithEmail(
      email: params.email,
      password: params.password,
      name: params.name,
    );
  }
}

class SignUpWithEmailParams extends Equatable {
  final String email;
  final String password;
  final String name;

  const SignUpWithEmailParams({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object> get props => [email, password, name];
} 