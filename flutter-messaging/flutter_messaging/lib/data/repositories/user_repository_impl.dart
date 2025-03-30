import 'package:dartz/dartz.dart';

import '../../core/network/network_info.dart';
import '../../core/utils/failure.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/user_data_source.dart';

class UserRepositoryImpl implements UserRepository {
  final UserDataSource userDataSource;
  final NetworkInfo networkInfo;

  UserRepositoryImpl({
    required this.userDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> getUserProfile({
    required String userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await userDataSource.getUserProfile(userId: userId);
        return Right(user);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Stream<List<User>>>> getAllUsers() async {
    if (await networkInfo.isConnected) {
      try {
        final usersStream = userDataSource.getAllUsers();
        return Right(usersStream);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> updateUserStatus({
    required bool isOnline,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await userDataSource.updateUserStatus(isOnline: isOnline);
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, User>> updateUserProfile({
    String? name,
    String? photoUrl,
    String? status,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await userDataSource.updateUserProfile(
          name: name,
          photoUrl: photoUrl,
          status: status,
        );
        return Right(user);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Stream<bool>>> getUserOnlineStatus({
    required String userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final statusStream = userDataSource.getUserOnlineStatus(userId: userId);
        return Right(statusStream);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, Stream<bool>>> getUserTypingStatus({
    required String userId,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final typingStream = userDataSource.getUserTypingStatus(userId: userId);
        return Right(typingStream);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'No internet connection'));
    }
  }

  @override
  Future<Either<Failure, void>> setUserTypingStatus({
    required String receiverId,
    required bool isTyping,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        await userDataSource.setUserTypingStatus(
          receiverId: receiverId,
          isTyping: isTyping,
        );
        return const Right(null);
      } catch (e) {
        return Left(ServerFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'No internet connection'));
    }
  }
} 