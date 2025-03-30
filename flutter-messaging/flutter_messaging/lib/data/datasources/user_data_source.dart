import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/user_model.dart';

abstract class UserDataSource {
  // Get user profile by ID
  Future<UserModel> getUserProfile({required String userId});
  
  // Get all users (for contacts)
  Stream<List<UserModel>> getAllUsers();
  
  // Update user status (online/offline)
  Future<void> updateUserStatus({required bool isOnline});
  
  // Update user profile information
  Future<UserModel> updateUserProfile({
    String? name,
    String? photoUrl,
    String? status,
  });
  
  // Get user online status stream
  Stream<bool> getUserOnlineStatus({required String userId});
  
  // Get user typing status
  Stream<bool> getUserTypingStatus({required String userId});
  
  // Set user typing status
  Future<void> setUserTypingStatus({
    required String receiverId,
    required bool isTyping,
  });
}

class UserDataSourceImpl implements UserDataSource {
  final FirebaseFirestore firestore;
  final firebase_auth.FirebaseAuth firebaseAuth;
  
  UserDataSourceImpl({
    required this.firestore,
    required this.firebaseAuth,
  });
  
  @override
  Future<UserModel> getUserProfile({required String userId}) async {
    try {
      final docSnapshot = await firestore.collection('users').doc(userId).get();
      
      if (!docSnapshot.exists) {
        throw Exception('User not found');
      }
      
      return UserModel.fromJson({
        'id': docSnapshot.id,
        ...docSnapshot.data()!,
      });
    } catch (e) {
      throw Exception('Failed to get user profile: ${e.toString()}');
    }
  }
  
  @override
  Stream<List<UserModel>> getAllUsers() {
    try {
      final currentUserId = firebaseAuth.currentUser?.uid;
      
      if (currentUserId == null) {
        throw Exception('User not signed in');
      }
      
      return firestore
          .collection('users')
          .where('id', isNotEqualTo: currentUserId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return UserModel.fromJson({
            'id': doc.id,
            ...doc.data(),
          });
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to get all users: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updateUserStatus({required bool isOnline}) async {
    try {
      final currentUserId = firebaseAuth.currentUser?.uid;
      
      if (currentUserId == null) {
        throw Exception('User not signed in');
      }
      
      await firestore.collection('users').doc(currentUserId).update({
        'isOnline': isOnline,
        'lastSeen': DateTime.now().millisecondsSinceEpoch,
      });
    } catch (e) {
      throw Exception('Failed to update user status: ${e.toString()}');
    }
  }
  
  @override
  Future<UserModel> updateUserProfile({
    String? name,
    String? photoUrl,
    String? status,
  }) async {
    try {
      final currentUser = firebaseAuth.currentUser;
      
      if (currentUser == null) {
        throw Exception('User not signed in');
      }
      
      final updateData = <String, dynamic>{};
      
      if (name != null) {
        updateData['name'] = name;
        await currentUser.updateDisplayName(name);
      }
      
      if (photoUrl != null) {
        updateData['photoUrl'] = photoUrl;
        await currentUser.updatePhotoURL(photoUrl);
      }
      
      if (status != null) {
        updateData['status'] = status;
      }
      
      if (updateData.isNotEmpty) {
        await firestore.collection('users').doc(currentUser.uid).update(updateData);
      }
      
      final updatedUser = await getUserProfile(userId: currentUser.uid);
      return updatedUser;
    } catch (e) {
      throw Exception('Failed to update user profile: ${e.toString()}');
    }
  }
  
  @override
  Stream<bool> getUserOnlineStatus({required String userId}) {
    try {
      return firestore
          .collection('users')
          .doc(userId)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) {
          return false;
        }
        return snapshot.data()?['isOnline'] ?? false;
      });
    } catch (e) {
      throw Exception('Failed to get user online status: ${e.toString()}');
    }
  }
  
  @override
  Stream<bool> getUserTypingStatus({required String userId}) {
    try {
      final currentUserId = firebaseAuth.currentUser?.uid;
      
      if (currentUserId == null) {
        throw Exception('User not signed in');
      }
      
      final chatId = _getChatId(currentUserId, userId);
      
      return firestore
          .collection('typing_status')
          .doc(chatId)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) {
          return false;
        }
        return snapshot.data()?[userId] ?? false;
      });
    } catch (e) {
      throw Exception('Failed to get user typing status: ${e.toString()}');
    }
  }
  
  @override
  Future<void> setUserTypingStatus({
    required String receiverId,
    required bool isTyping,
  }) async {
    try {
      final currentUserId = firebaseAuth.currentUser?.uid;
      
      if (currentUserId == null) {
        throw Exception('User not signed in');
      }
      
      final chatId = _getChatId(currentUserId, receiverId);
      
      await firestore.collection('typing_status').doc(chatId).set({
        currentUserId: isTyping,
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to set user typing status: ${e.toString()}');
    }
  }
  
  // Helper method to generate a unique chat ID
  String _getChatId(String userId1, String userId2) {
    // Sort the user IDs to ensure consistency
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }
} 