import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';

import '../../core/utils/failure.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/message_repository.dart';
import '../../domain/repositories/user_repository.dart';

class MockAuthRepository implements AuthRepository {
  final _currentUser = const User(
    id: 'mock-user-123',
    name: 'Test User',
    email: 'test@example.com',
    isOnline: true,
    lastSeen: null,
  );
  
  bool _isSignedIn = false;

  @override
  Future<Either<Failure, User?>> getCurrentUser() async {
    if (_isSignedIn) {
      return Right(_currentUser);
    } else {
      return const Right(null);
    }
  }

  @override
  Future<bool> isSignedIn() async {
    return _isSignedIn;
  }

  @override
  Future<Either<Failure, User>> signInAnonymously() async {
    _isSignedIn = true;
    return Right(_currentUser);
  }

  @override
  Future<Either<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _isSignedIn = true;
    return Right(_currentUser);
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    _isSignedIn = false;
    return const Right(null);
  }

  @override
  Future<Either<Failure, User>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    _isSignedIn = true;
    return Right(_currentUser);
  }
}

class MockMessageRepository implements MessageRepository {
  final _uuid = Uuid();
  final List<Message> _messages = [
    Message(
      id: '1',
      senderId: 'mock-user-123',
      receiverId: '2',
      content: 'Hello there!',
      type: MessageType.text,
      status: MessageStatus.sent,
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    Message(
      id: '2',
      senderId: '2',
      receiverId: 'mock-user-123',
      content: 'Hi! How are you?',
      type: MessageType.text,
      status: MessageStatus.read,
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    Message(
      id: '3',
      senderId: 'mock-user-123',
      receiverId: '2',
      content: 'I\'m doing well, thanks!',
      type: MessageType.text,
      status: MessageStatus.delivered,
      timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
  ];

  @override
  Future<Either<Failure, void>> deleteMessage({required String messageId}) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, Stream<List<Message>>>> getMessages({
    required String receiverId,
    int limit = 30,
  }) async {
    final filteredMessages = _messages.where((m) =>
      (m.senderId == 'mock-user-123' && m.receiverId == receiverId) ||
      (m.receiverId == 'mock-user-123' && m.senderId == receiverId)
    ).toList();
    
    return Right(Stream.value(filteredMessages));
  }

  @override
  Future<Either<Failure, Stream<int>>> getUnreadMessageCount({required String userId}) async {
    return Right(Stream.value(2));
  }

  @override
  Future<Either<Failure, void>> markAllMessagesAsRead({required String senderId}) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, Message>> sendMessage({
    required String receiverId,
    required String content,
    required MessageType type,
  }) async {
    final newMessage = Message(
      id: _uuid.v4(),
      senderId: 'mock-user-123',
      receiverId: receiverId,
      content: content,
      type: type,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
    );
    
    _messages.add(newMessage);
    return Right(newMessage);
  }

  @override
  Future<Either<Failure, void>> updateMessageStatus({
    required String messageId,
    required MessageStatus status,
  }) async {
    return const Right(null);
  }
}

class MockUserRepository implements UserRepository {
  final List<User> _users = [
    const User(
      id: '1',
      name: 'Alice Smith',
      email: 'alice@example.com',
      photoUrl: 'https://randomuser.me/api/portraits/women/43.jpg',
      status: 'Available',
      isOnline: true,
      lastSeen: null,
    ),
    const User(
      id: '2',
      name: 'Bob Johnson',
      email: 'bob@example.com',
      photoUrl: 'https://randomuser.me/api/portraits/men/22.jpg',
      status: 'Busy',
      isOnline: false,
      lastSeen: null,
    ),
    const User(
      id: '3',
      name: 'Carol Wilson',
      email: 'carol@example.com',
      photoUrl: 'https://randomuser.me/api/portraits/women/67.jpg',
      status: 'At work',
      isOnline: true,
      lastSeen: null,
    ),
  ];

  @override
  Future<Either<Failure, Stream<List<User>>>> getAllUsers() async {
    return Right(Stream.value(_users));
  }

  @override
  Future<Either<Failure, Stream<bool>>> getUserOnlineStatus({required String userId}) async {
    final user = _users.firstWhere(
      (u) => u.id == userId, 
      orElse: () => User(
        id: '',
        name: '',
        isOnline: false,
      )
    );
    
    return Right(Stream.value(user.isOnline));
  }

  @override
  Future<Either<Failure, User>> getUserProfile({required String userId}) async {
    final user = _users.firstWhere(
      (u) => u.id == userId, 
      orElse: () => User(
        id: userId,
        name: 'Unknown User',
        isOnline: false,
      )
    );
    
    return Right(user);
  }

  @override
  Future<Either<Failure, Stream<bool>>> getUserTypingStatus({required String userId}) async {
    return Right(Stream.value(false));
  }

  @override
  Future<Either<Failure, void>> setUserTypingStatus({
    required String receiverId,
    required bool isTyping,
  }) async {
    return const Right(null);
  }

  @override
  Future<Either<Failure, User>> updateUserProfile({
    String? name,
    String? photoUrl,
    String? status,
  }) async {
    final updatedUser = User(
      id: 'mock-user-123',
      name: 'Test User',
      email: 'test@example.com',
      isOnline: true,
      lastSeen: null,
    );
    
    return Right(updatedUser);
  }

  @override
  Future<Either<Failure, void>> updateUserStatus({required bool isOnline}) async {
    return const Right(null);
  }
} 