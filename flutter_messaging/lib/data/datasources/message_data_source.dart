import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:uuid/uuid.dart';

import '../../domain/entities/message.dart';
import '../models/message_model.dart';

abstract class MessageDataSource {
  // Send a message
  Future<MessageModel> sendMessage({
    required String receiverId,
    required String content,
    required MessageType type,
  });
  
  // Get messages between current user and receiver
  Stream<List<MessageModel>> getMessages({
    required String receiverId,
    int limit = 30,
  });
  
  // Update message status
  Future<void> updateMessageStatus({
    required String messageId,
    required MessageStatus status,
  });
  
  // Delete a message
  Future<void> deleteMessage({
    required String messageId,
  });
  
  // Get unread message count
  Stream<int> getUnreadMessageCount({
    required String userId,
  });
  
  // Mark all messages as read
  Future<void> markAllMessagesAsRead({
    required String senderId,
  });
}

class MessageDataSourceImpl implements MessageDataSource {
  final FirebaseFirestore firestore;
  final firebase_auth.FirebaseAuth firebaseAuth;
  final Uuid _uuid = const Uuid();
  
  MessageDataSourceImpl({
    required this.firestore,
    required this.firebaseAuth,
  });
  
  @override
  Future<MessageModel> sendMessage({
    required String receiverId,
    required String content,
    required MessageType type,
  }) async {
    try {
      final currentUserId = firebaseAuth.currentUser?.uid;
      
      if (currentUserId == null) {
        throw Exception('User not signed in');
      }
      
      final timestamp = DateTime.now();
      final messageId = _uuid.v4();
      final chatId = _getChatId(currentUserId, receiverId);
      
      final message = MessageModel(
        id: messageId,
        senderId: currentUserId,
        receiverId: receiverId,
        content: content,
        type: type,
        status: MessageStatus.sent,
        timestamp: timestamp,
        isDeleted: false,
      );
      
      final messageData = message.toJson();
      
      // Add message to messages collection
      await firestore.collection('messages').doc(messageId).set(messageData);
      
      // Add message reference to chat collection
      await firestore.collection('chats').doc(chatId).collection('messages').doc(messageId).set(messageData);
      
      // Update last message in chat
      await firestore.collection('chats').doc(chatId).set({
        'lastMessage': content,
        'lastMessageTimestamp': timestamp.millisecondsSinceEpoch,
        'lastMessageSenderId': currentUserId,
        'participants': [currentUserId, receiverId],
      }, SetOptions(merge: true));
      
      return message;
    } catch (e) {
      throw Exception('Failed to send message: ${e.toString()}');
    }
  }
  
  @override
  Stream<List<MessageModel>> getMessages({
    required String receiverId,
    int limit = 30,
  }) {
    try {
      final currentUserId = firebaseAuth.currentUser?.uid;
      
      if (currentUserId == null) {
        throw Exception('User not signed in');
      }
      
      final chatId = _getChatId(currentUserId, receiverId);
      
      return firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return MessageModel.fromJson(doc.data());
        }).toList();
      });
    } catch (e) {
      throw Exception('Failed to get messages: ${e.toString()}');
    }
  }
  
  @override
  Future<void> updateMessageStatus({
    required String messageId,
    required MessageStatus status,
  }) async {
    try {
      await firestore.collection('messages').doc(messageId).update({
        'status': status.name,
      });
      
      // Also update in chat collection
      final message = await firestore.collection('messages').doc(messageId).get();
      
      if (message.exists) {
        final data = message.data();
        if (data != null) {
          final senderId = data['senderId'];
          final receiverId = data['receiverId'];
          final chatId = _getChatId(senderId, receiverId);
          
          await firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .doc(messageId)
              .update({
            'status': status.name,
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to update message status: ${e.toString()}');
    }
  }
  
  @override
  Future<void> deleteMessage({
    required String messageId,
  }) async {
    try {
      await firestore.collection('messages').doc(messageId).update({
        'isDeleted': true,
        'content': 'This message was deleted',
      });
      
      // Also update in chat collection
      final message = await firestore.collection('messages').doc(messageId).get();
      
      if (message.exists) {
        final data = message.data();
        if (data != null) {
          final senderId = data['senderId'];
          final receiverId = data['receiverId'];
          final chatId = _getChatId(senderId, receiverId);
          
          await firestore
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .doc(messageId)
              .update({
            'isDeleted': true,
            'content': 'This message was deleted',
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to delete message: ${e.toString()}');
    }
  }
  
  @override
  Stream<int> getUnreadMessageCount({
    required String userId,
  }) {
    try {
      final currentUserId = firebaseAuth.currentUser?.uid;
      
      if (currentUserId == null) {
        throw Exception('User not signed in');
      }
      
      final chatId = _getChatId(currentUserId, userId);
      
      return firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isNotEqualTo: MessageStatus.read.name)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      throw Exception('Failed to get unread message count: ${e.toString()}');
    }
  }
  
  @override
  Future<void> markAllMessagesAsRead({
    required String senderId,
  }) async {
    try {
      final currentUserId = firebaseAuth.currentUser?.uid;
      
      if (currentUserId == null) {
        throw Exception('User not signed in');
      }
      
      final chatId = _getChatId(currentUserId, senderId);
      
      final unreadMessages = await firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('senderId', isEqualTo: senderId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('status', isNotEqualTo: MessageStatus.read.name)
          .get();
      
      // Create a batch write to update all messages at once
      final batch = firestore.batch();
      
      for (final doc in unreadMessages.docs) {
        final messageId = doc.id;
        
        // Update in messages collection
        final messageRef = firestore.collection('messages').doc(messageId);
        batch.update(messageRef, {'status': MessageStatus.read.name});
        
        // Update in chat collection
        final chatMessageRef = firestore
            .collection('chats')
            .doc(chatId)
            .collection('messages')
            .doc(messageId);
        batch.update(chatMessageRef, {'status': MessageStatus.read.name});
      }
      
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark messages as read: ${e.toString()}');
    }
  }
  
  // Helper method to generate a unique chat ID
  String _getChatId(String userId1, String userId2) {
    // Sort the user IDs to ensure consistency
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }
} 