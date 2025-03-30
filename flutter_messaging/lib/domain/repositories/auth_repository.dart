import 'package:dartz/dartz.dart';

import '../../core/utils/failure.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  // Sign up with email and password
  Future<Either<Failure, User>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });
  
  // Sign in with email and password
  Future<Either<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  });
  
  // Sign in anonymously
  Future<Either<Failure, User>> signInAnonymously();
  
  // Sign out
  Future<Either<Failure, void>> signOut();
  
  // Get the current user
  Future<Either<Failure, User?>> getCurrentUser();
  
  // Check if a user is signed in
  Future<bool> isSignedIn();
} 