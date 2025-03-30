# Data Layer

This document describes the data layer of the Flutter Messaging application, detailing its components, implementation, and patterns.

## Overview

The data layer is responsible for:

- Implementing repository interfaces defined in the domain layer
- Managing data sources (remote, local, mock)
- Transforming data between external sources and the domain model
- Handling network connectivity
- Implementing caching strategies
- Managing errors and exceptions

The data layer follows the Repository Pattern to abstract the data sources from the business logic.

## Components

### Repository Implementations

Repository implementations connect the domain layer to the data sources. They:

1. Implement repository interfaces defined in the domain layer
2. Handle data source selection (remote vs. local)
3. Perform network connectivity checks
4. Transform data models to domain entities and vice versa
5. Handle errors and wrap them in domain failures

Example of a repository implementation:

```dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final userModel = await remoteDataSource.signInWithEmail(
          email: email,
          password: password,
        );
        return Right(userModel);
      } on FirebaseAuthException catch (e) {
        return Left(AuthFailure(
          message: _mapFirebaseAuthErrorToMessage(e.code),
          code: int.tryParse(e.code) ?? 401,
        ));
      } catch (e) {
        return Left(AuthFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'No internet connection'));
    }
  }

  // Additional method implementations...
  
  String _mapFirebaseAuthErrorToMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user has been disabled.';
      default:
        return 'Authentication failed.';
    }
  }
}
```

### Data Sources

Data sources are responsible for:

1. Communicating with external systems (API, database, etc.)
2. Implementing CRUD operations
3. Converting external data formats to model objects

#### Remote Data Sources

Remote data sources interact with external APIs or services like Firebase:

```dart
class FirebaseMessageDataSource implements MessageDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  FirebaseMessageDataSource({
    required this.firestore,
    required this.storage,
  });

  @override
  Future<MessageModel> sendMessage(MessageModel message) async {
    final messageRef = firestore.collection('messages').doc();
    final messageWithId = message.copyWith(id: messageRef.id);
    
    await messageRef.set(messageWithId.toJson());
    
    // Update conversation with last message
    final conversationId = _generateConversationId(
      message.senderId, 
      message.receiverId,
    );
    
    final conversationRef = firestore.collection('conversations').doc(conversationId);
    final conversationSnapshot = await conversationRef.get();
    
    if (conversationSnapshot.exists) {
      await conversationRef.update({
        'lastMessage': messageWithId.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCount.${message.receiverId}': FieldValue.increment(1),
      });
    } else {
      await conversationRef.set({
        'id': conversationId,
        'participantIds': [message.senderId, message.receiverId],
        'lastMessage': messageWithId.toJson(),
        'updatedAt': FieldValue.serverTimestamp(),
        'unreadCount': {
          message.senderId: 0,
          message.receiverId: 1,
        },
      });
    }
    
    return messageWithId;
  }

  // Additional method implementations...
  
  String _generateConversationId(String userId1, String userId2) {
    List<String> ids = [userId1, userId2];
    ids.sort();
    return ids.join('_');
  }
}
```

#### Local Data Sources

Local data sources interact with persistent storage on the device:

```dart
class LocalUserDataSource implements UserDataSource {
  final SharedPreferences prefs;
  
  LocalUserDataSource({required this.prefs});
  
  static const String _userCacheKey = 'cached_user';
  static const String _userSettingsCacheKey = 'cached_user_settings';
  
  @override
  Future<UserModel> getUserById(String userId) async {
    final userJson = prefs.getString(_userCacheKey);
    if (userJson != null) {
      return UserModel.fromJson(json.decode(userJson));
    } else {
      throw CacheException(message: 'User not found in cache');
    }
  }
  
  Future<void> cacheUser(UserModel user) async {
    await prefs.setString(_userCacheKey, json.encode(user.toJson()));
  }
  
  // Additional method implementations...
}
```

#### Mock Data Sources

Mock data sources are used for testing and web-only implementations:

```dart
class MockAuthDataSource implements AuthDataSource {
  final User _mockUser = const User(
    id: 'mock-user-123',
    name: 'Test User',
    email: 'test@example.com',
    isOnline: true,
    lastSeen: null,
  );
  
  bool _isSignedIn = false;
  
  @override
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (email == 'test@example.com' && password == 'password') {
      _isSignedIn = true;
      return UserModel.fromJson(_mockUser.toJson());
    } else {
      throw Exception('Invalid credentials');
    }
  }
  
  // Additional method implementations...
}
```

### Models

Models represent the data structure of entities in the data layer. They:

1. Extend domain entities
2. Add serialization/deserialization methods
3. May contain additional data source specific fields or methods

Example of a model:

```dart
class MessageModel extends Message {
  const MessageModel({
    required super.id,
    required super.senderId,
    required super.receiverId,
    required super.content,
    required super.type,
    required super.timestamp,
    required super.status,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      content: json['content'],
      type: MessageType.values.byName(json['type']),
      timestamp: json['timestamp'] is Timestamp
          ? (json['timestamp'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
      status: MessageStatus.values.byName(json['status']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'content': content,
      'type': type.name,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status.name,
    };
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? content,
    MessageType? type,
    DateTime? timestamp,
    MessageStatus? status,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      content: content ?? this.content,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
    );
  }
}
```

### Network Handling

Network connectivity is checked before performing remote operations:

```dart
abstract class NetworkInfo {
  Future<bool> get isConnected;
}

class NetworkInfoImpl implements NetworkInfo {
  final Connectivity connectivity;

  NetworkInfoImpl(this.connectivity);

  @override
  Future<bool> get isConnected async {
    final connectivityResult = await connectivity.checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }
}
```

## Error Handling

Errors in the data layer are caught and transformed into domain failures:

```dart
class CacheException implements Exception {
  final String message;
  
  CacheException({required this.message});
  
  @override
  String toString() => 'CacheException: $message';
}

class ServerException implements Exception {
  final String message;
  final int? statusCode;
  
  ServerException({required this.message, this.statusCode});
  
  @override
  String toString() => 'ServerException: $message (Status code: $statusCode)';
}
```

## Dependency Injection

Services and data sources are registered using the service locator pattern:

```dart
Future<void> initDataDependencies() async {
  // Data sources
  if (kIsWeb) {
    // Mock implementations for web
    sl.registerLazySingleton<AuthDataSource>(
      () => MockAuthDataSource(),
    );
    sl.registerLazySingleton<MessageDataSource>(
      () => MockMessageDataSource(),
    );
    sl.registerLazySingleton<UserDataSource>(
      () => MockUserDataSource(),
    );
  } else {
    // Firebase implementations for native
    sl.registerLazySingleton<AuthDataSource>(
      () => FirebaseAuthDataSourceImpl(firebaseAuth: sl()),
    );
    sl.registerLazySingleton<MessageDataSource>(
      () => FirebaseMessageDataSource(firestore: sl(), storage: sl()),
    );
    sl.registerLazySingleton<UserDataSource>(
      () => FirebaseUserDataSourceImpl(firestore: sl(), storage: sl()),
    );
  }
  
  // Local data sources
  final prefs = await SharedPreferences.getInstance();
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<LocalUserDataSource>(
    () => LocalUserDataSourceImpl(prefs: sl()),
  );
  
  // Network info
  sl.registerLazySingleton<NetworkInfo>(
    () => NetworkInfoImpl(sl()),
  );
  sl.registerLazySingleton<Connectivity>(
    () => Connectivity(),
  );
  
  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<MessageRepository>(
    () => MessageRepositoryImpl(
      dataSource: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(
      dataSource: sl(),
      networkInfo: sl(),
    ),
  );
}
```

## Caching Strategy

The data layer implements caching strategies for improved performance and offline support:

1. **Repository-level Caching**: Repositories decide whether to use remote or local data sources
2. **TTL Caching**: Time-to-live based caching for non-critical data
3. **Write-through Caching**: Updates are written to both remote and local storage
4. **Invalidation**: Cache is invalidated when data is updated

Example of TTL caching:

```dart
class CachedData<T> {
  final T data;
  final DateTime timestamp;
  final Duration ttl;
  
  CachedData({
    required this.data,
    required this.timestamp,
    required this.ttl,
  });
  
  bool get isValid {
    return DateTime.now().difference(timestamp) < ttl;
  }
}

class UserRepositoryImpl implements UserRepository {
  final UserDataSource remoteDataSource;
  final LocalUserDataSource localDataSource;
  final NetworkInfo networkInfo;
  
  CachedData<List<User>>? _cachedUsers;
  static const Duration _usersCacheTtl = Duration(minutes: 5);
  
  @override
  Future<Either<Failure, List<User>>> searchUsers(String query, {int limit = 20}) async {
    // Check if we have valid cache
    if (_cachedUsers != null && _cachedUsers!.isValid && query.isEmpty) {
      return Right(_cachedUsers!.data);
    }
    
    // Otherwise fetch from remote
    if (await networkInfo.isConnected) {
      try {
        final users = await remoteDataSource.searchUsers(query, limit: limit);
        
        // Cache the result if it's a full list (empty query)
        if (query.isEmpty) {
          _cachedUsers = CachedData(
            data: users,
            timestamp: DateTime.now(),
            ttl: _usersCacheTtl,
          );
        }
        
        return Right(users);
      } catch (e) {
        return Left(UserFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'No internet connection'));
    }
  }
  
  // Additional method implementations...
}
```

## Firebase Integration

The data layer integrates with Firebase services:

1. **FirebaseAuth**: For authentication
2. **Firestore**: For storing and retrieving data
3. **FirebaseStorage**: For file storage
4. **FirebaseMessaging**: For push notifications

Example of Firebase integration:

```dart
class FirebaseAuthDataSourceImpl implements AuthDataSource {
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  FirebaseAuthDataSourceImpl({
    required this.firebaseAuth,
    required this.firestore,
  });

  @override
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    // Create user in Firebase Auth
    final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Create user profile in Firestore
    final userId = userCredential.user!.uid;
    final userModel = UserModel(
      id: userId,
      name: name,
      email: email,
      isOnline: true,
    );
    
    await firestore.collection('users').doc(userId).set(userModel.toJson());
    
    // Create default user settings
    final userSettings = UserSettingsModel(
      userId: userId,
      showOnlineStatus: true,
      showLastSeen: true,
      allowMessageRequests: true,
      notificationPreference: NotificationPreference.all,
    );
    
    await firestore.collection('userSettings').doc(userId).set(userSettings.toJson());
    
    return userModel;
  }
  
  // Additional method implementations...
}
```

## Offline Support

The data layer provides offline support through:

1. **Firestore Offline Persistence**: Automatically caches Firestore data
2. **Local Caching**: Using SharedPreferences for small data or Hive for larger datasets
3. **Offline Queue**: Storing operations to be performed when online

Example of offline queue implementation:

```dart
class OfflineQueueManager {
  final Queue<OfflineOperation> _operationQueue = Queue();
  final SharedPreferences prefs;
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();
  
  Stream<bool> get connectivityStream => _connectivityController.stream;
  
  OfflineQueueManager({required this.prefs}) {
    _loadSavedOperations();
    _listenToConnectivity();
  }
  
  void _listenToConnectivity() {
    Connectivity().onConnectivityChanged.listen((result) {
      final isConnected = result != ConnectivityResult.none;
      _connectivityController.add(isConnected);
      
      if (isConnected) {
        _processQueue();
      }
    });
  }
  
  Future<void> _loadSavedOperations() async {
    final savedOperations = prefs.getStringList('offline_operations') ?? [];
    for (final opJson in savedOperations) {
      _operationQueue.add(OfflineOperation.fromJson(json.decode(opJson)));
    }
  }
  
  Future<void> _saveOperations() async {
    final operationsJson = _operationQueue
        .map((op) => json.encode(op.toJson()))
        .toList();
    await prefs.setStringList('offline_operations', operationsJson);
  }
  
  void addOperation(OfflineOperation operation) {
    _operationQueue.add(operation);
    _saveOperations();
  }
  
  Future<void> _processQueue() async {
    while (_operationQueue.isNotEmpty) {
      final operation = _operationQueue.first;
      try {
        await operation.execute();
        _operationQueue.removeFirst();
        await _saveOperations();
      } catch (e) {
        // If operation fails, we'll try again later
        break;
      }
    }
  }
}

class OfflineOperation {
  final String type;
  final Map<String, dynamic> data;
  final Function execute;
  
  OfflineOperation({
    required this.type,
    required this.data,
    required this.execute,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'data': data,
    };
  }
  
  factory OfflineOperation.fromJson(Map<String, dynamic> json) {
    // Factory would need to recreate the execute function based on type and data
    // This is a simplified version
    return OfflineOperation(
      type: json['type'],
      data: json['data'],
      execute: () async {
        // Implementation would depend on the operation type
      },
    );
  }
}
```

## Implementation Strategies

### Firebase vs. Web Implementation

The data layer provides different implementations for Firebase and web:

```dart
if (kIsWeb) {
  // Use mock implementations for web
  sl.registerLazySingleton<AuthDataSource>(() => MockAuthDataSource());
} else {
  // Use Firebase implementations for native platforms
  sl.registerLazySingleton<AuthDataSource>(
    () => FirebaseAuthDataSourceImpl(firebaseAuth: sl()),
  );
}
```

### Testing Strategies

The data layer is designed for testability:

1. **Dependency Injection**: All dependencies are injected for easy mocking
2. **Repository Pattern**: Abstracts data sources for easier testing
3. **Interface-based Design**: All components implement interfaces
4. **Mock Data Sources**: Dedicated mock implementations for testing

Example of repository testing:

```dart
void main() {
  late MessageRepositoryImpl repository;
  late MockMessageDataSource mockMessageDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockMessageDataSource = MockMessageDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = MessageRepositoryImpl(
      dataSource: mockMessageDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('sendMessage', () {
    final tMessage = MessageModel(
      id: 'test-id',
      senderId: 'sender-id',
      receiverId: 'receiver-id',
      content: 'Hello',
      type: MessageType.text,
      timestamp: DateTime.now(),
      status: MessageStatus.sent,
    );

    test('should check if the device is online', () async {
      // arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockMessageDataSource.sendMessage(tMessage))
          .thenAnswer((_) async => tMessage);
      
      // act
      await repository.sendMessage(tMessage);
      
      // assert
      verify(() => mockNetworkInfo.isConnected).called(1);
    });

    test('should return remote data when the call to remote data source is successful', 
    () async {
      // arrange
      when(() => mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(() => mockMessageDataSource.sendMessage(tMessage))
          .thenAnswer((_) async => tMessage);
      
      // act
      final result = await repository.sendMessage(tMessage);
      
      // assert
      verify(() => mockMessageDataSource.sendMessage(tMessage));
      expect(result, equals(Right(tMessage)));
    });

    // Additional tests...
  });
}
```

## Future Enhancements

1. **Improved Caching**: Implement more sophisticated caching strategies
2. **Pagination Support**: Standardized approach to paginated data
3. **Real-time Sync**: Better handling of real-time data synchronization
4. **Encryption**: Add end-to-end encryption for sensitive data
5. **Analytics Integration**: Track usage patterns and performance metrics
6. **Batch Operations**: Support for batch operations to reduce network calls
7. **Rate Limiting**: Implement rate limiting to prevent API abuse
8. **Data Validation**: Comprehensive data validation before persistence
9. **Conflict Resolution**: Strategies for resolving conflicting updates
10. **Background Sync**: Implement background data synchronization 