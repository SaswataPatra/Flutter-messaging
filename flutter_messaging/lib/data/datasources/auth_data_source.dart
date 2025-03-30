import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/user_model.dart';

abstract class AuthDataSource {
  /// Sign up with email and password
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });

  /// Sign in with email and password
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign in anonymously
  Future<UserModel> signInAnonymously();

  /// Sign out
  Future<void> signOut();

  /// Get the current user
  Future<UserModel?> getCurrentUser();

  /// Check if a user is signed in
  Future<bool> isSignedIn();
}

class AuthDataSourceImpl implements AuthDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;

  AuthDataSourceImpl({required this.firebaseAuth});

  @override
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      
      if (user == null) {
        throw Exception('User creation failed');
      }

      // Update display name
      await user.updateDisplayName(name);
      
      // Create user model
      return UserModel(
        id: user.uid,
        name: name,
        email: user.email,
        isOnline: true,
        lastSeen: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      
      if (user == null) {
        throw Exception('Sign in failed');
      }
      
      return UserModel(
        id: user.uid,
        name: user.displayName ?? 'User',
        email: user.email,
        photoUrl: user.photoURL,
        isOnline: true,
        lastSeen: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signInAnonymously() async {
    try {
      final userCredential = await firebaseAuth.signInAnonymously();
      final user = userCredential.user;
      
      if (user == null) {
        throw Exception('Anonymous sign in failed');
      }
      
      return UserModel(
        id: user.uid,
        name: 'Anonymous User',
        isOnline: true,
        lastSeen: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Anonymous sign in failed: ${e.toString()}');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await firebaseAuth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = firebaseAuth.currentUser;
      
      if (user == null) {
        return null;
      }
      
      return UserModel(
        id: user.uid,
        name: user.displayName ?? 'User',
        email: user.email,
        photoUrl: user.photoURL,
        isOnline: true,
        lastSeen: DateTime.now(),
      );
    } catch (e) {
      throw Exception('Get current user failed: ${e.toString()}');
    }
  }

  @override
  Future<bool> isSignedIn() async {
    return firebaseAuth.currentUser != null;
  }
} 