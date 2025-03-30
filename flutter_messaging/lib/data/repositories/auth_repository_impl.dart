import 'package:dartz/dartz.dart';

import '../../core/network/network_info.dart';
import '../../core/utils/failure.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_data_source.dart';
import '../models/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource authDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.authDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await authDataSource.signUpWithEmail(
          email: email,
          password: password,
          name: name,
        );
        return Right(user);
      } catch (e) {
        return Left(AuthFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await authDataSource.signInWithEmail(
          email: email,
          password: password,
        );
        return Right(user);
      } catch (e) {
        return Left(AuthFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, User>> signInAnonymously() async {
    if (await networkInfo.isConnected) {
      try {
        final user = await authDataSource.signInAnonymously();
        return Right(user);
      } catch (e) {
        return Left(AuthFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await authDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    try {
      final UserModel? user = await authDataSource.getCurrentUser();
      return Right(user);
    } catch (e) {
      return Left(AuthFailure(message: e.toString()));
    }
  }

  @override
  Future<bool> isSignedIn() async {
    return await authDataSource.isSignedIn();
  }
} 