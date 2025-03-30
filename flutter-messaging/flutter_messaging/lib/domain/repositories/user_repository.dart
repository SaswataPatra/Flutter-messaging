import 'package:dartz/dartz.dart';

import '../../core/utils/failure.dart';
import '../entities/user.dart';

abstract class UserRepository {
  // Get user profile by ID
  Future<Either<Failure, User>> getUserProfile({
    required String userId,
  });
  
  // Get all users (for contacts)
  Future<Either<Failure, Stream<List<User>>>> getAllUsers();
  
  // Update user status (online/offline)
  Future<Either<Failure, void>> updateUserStatus({
    required bool isOnline,
  });
  
  // Update user profile information
  Future<Either<Failure, User>> updateUserProfile({
    String? name,
    String? photoUrl,
    String? status,
  });
  
  // Get user online status stream
  Future<Either<Failure, Stream<bool>>> getUserOnlineStatus({
    required String userId,
  });
  
  // Get user typing status
  Future<Either<Failure, Stream<bool>>> getUserTypingStatus({
    required String userId,
  });
  
  // Set user typing status
  Future<Either<Failure, void>> setUserTypingStatus({
    required String receiverId,
    required bool isTyping,
  });
} 