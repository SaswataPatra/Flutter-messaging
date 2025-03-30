# Domain Layer

This document describes the domain layer of the Flutter Messaging application, detailing its components, implementation, and patterns.

## Overview

The domain layer is the core of the application and contains the business logic. It is independent of other layers and defines:

- **Entities**: Core business objects
- **Repository Interfaces**: Contracts for data operations
- **Use Cases**: Business logic operations
- **Failures**: Domain-specific error handling

The domain layer follows Clean Architecture principles, ensuring that it has no dependencies on external frameworks or implementation details. This makes it highly testable, maintainable, and reusable across different platforms.

## Components

### Entities

Entities are the core business objects of the application. They:

1. Represent the fundamental data structures
2. Contain business logic related to the entity itself
3. Are immutable by design (using the `const` constructor)
4. Implement equality using `Equatable`
5. Contain no references to data sources or frameworks

Examples of entities:

```dart
class User extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? photoUrl;
  final String? status;
  final bool isOnline;
  final DateTime? lastSeen;

  const User({
    required this.id,
    required this.name,
    this.email,
    this.photoUrl,
    this.status,
    required this.isOnline,
    this.lastSeen,
  });

  @override
  List<Object?> get props => [id, name, email, photoUrl, status, isOnline, lastSeen];
}

class Message extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.status,
  });

  @override
  List<Object> get props => [id, senderId, receiverId, content, type, timestamp, status];
}

enum MessageType { text, image, video, audio }

enum MessageStatus { sent, delivered, read }
```

### Repository Interfaces

Repository interfaces define contracts for data operations. They:

1. Declare methods for CRUD operations on entities
2. Return `Either<Failure, T>` to handle both success and error cases
3. Define streams for real-time data
4. Have no implementation details
5. Use only domain entities in their signatures

Examples of repository interfaces:

```dart
abstract class AuthRepository {
  Future<Either<Failure, User>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });
  
  Future<Either<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  });
  
  Future<Either<Failure, User>> signInAnonymously();
  
  Future<Either<Failure, void>> signOut();
  
  Future<Either<Failure, User?>> getCurrentUser();
  
  Future<bool> isSignedIn();
}

abstract class MessageRepository {
  Future<Either<Failure, Message>> sendMessage(Message message);
  
  Future<Either<Failure, List<Message>>> getMessages({
    required String userId1,
    required String userId2,
    int limit = 20,
    Message? lastMessage,
  });
  
  Future<Either<Failure, void>> markAsRead({
    required String senderId,
    required String receiverId,
  });
  
  Future<Either<Failure, List<Conversation>>> getConversations(String userId);
  
  Stream<List<Message>> messagesStream({
    required String userId1,
    required String userId2,
  });
  
  Stream<List<Conversation>> conversationsStream(String userId);
  
  Future<Either<Failure, void>> updateTypingStatus({
    required String senderId,
    required String receiverId,
    required bool isTyping,
  });
  
  Stream<bool> typingStatusStream({
    required String senderId,
    required String receiverId,
  });
}
```

### Use Cases

Use cases encapsulate business logic operations. They:

1. Represent a single operation or business rule
2. Follow the Single Responsibility Principle
3. Use repository interfaces to access data
4. Accept and return only domain entities
5. Return `Either<Failure, T>` to handle success and error cases
6. Implement a common interface for consistency

Use case interface:

```dart
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}
```

Examples of use cases:

```dart
class SignInWithEmailUseCase implements UseCase<User, SignInWithEmailParams> {
  final AuthRepository repository;

  SignInWithEmailUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(SignInWithEmailParams params) async {
    return await repository.signInWithEmail(
      email: params.email,
      password: params.password,
    );
  }
}

class SignInWithEmailParams extends Equatable {
  final String email;
  final String password;

  const SignInWithEmailParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}
```

Some use cases don't require parameters, in which case a `NoParams` class is used:

```dart
class GetCurrentUserUseCase implements UseCase<User?, NoParams> {
  final AuthRepository repository;

  GetCurrentUserUseCase(this.repository);

  @override
  Future<Either<Failure, User?>> call(NoParams params) async {
    return await repository.getCurrentUser();
  }
}

class NoParams extends Equatable {
  @override
  List<Object> get props => [];
}
```

Use cases for streams:

```dart
abstract class StreamUseCase<Type, Params> {
  Stream<Type> call(Params params);
}

class MessagesStreamUseCase implements StreamUseCase<List<Message>, MessagesStreamParams> {
  final MessageRepository repository;

  MessagesStreamUseCase(this.repository);

  @override
  Stream<List<Message>> call(MessagesStreamParams params) {
    return repository.messagesStream(
      userId1: params.userId1,
      userId2: params.userId2,
    );
  }
}

class MessagesStreamParams extends Equatable {
  final String userId1;
  final String userId2;

  const MessagesStreamParams({
    required this.userId1,
    required this.userId2,
  });

  @override
  List<Object> get props => [userId1, userId2];
}
```

### Failures

Failures handle domain-specific errors. They:

1. Represent domain-specific errors
2. Are used with the `Either` type from `dartz` to handle both success and error cases
3. Extend a base `Failure` class
4. Include error messages and codes

Base failure class:

```dart
abstract class Failure extends Equatable {
  final String message;
  final int code;

  const Failure({
    required this.message,
    required this.code,
  });

  @override
  List<Object> get props => [message, code];
}
```

Specific failure classes:

```dart
class AuthFailure extends Failure {
  const AuthFailure({required String message, int code = 401})
      : super(message: message, code: code);
}

class MessageFailure extends Failure {
  const MessageFailure({required String message, int code = 500})
      : super(message: message, code: code);
}

class UserFailure extends Failure {
  const UserFailure({required String message, int code = 404})
      : super(message: message, code: code);
}

class ConnectionFailure extends Failure {
  const ConnectionFailure({required String message, int code = 503})
      : super(message: message, code: code);
}

class CacheFailure extends Failure {
  const CacheFailure({required String message, int code = 500})
      : super(message: message, code: code);
}
```

## Implementation Patterns

### Either Type

The domain layer uses the `Either` type from the `dartz` package to handle both success and error cases:

```dart
import 'package:dartz/dartz.dart';

// Example repository method
Future<Either<Failure, User>> signInWithEmail({
  required String email,
  required String password,
});

// Example use case implementation
@override
Future<Either<Failure, User>> call(SignInWithEmailParams params) async {
  return await repository.signInWithEmail(
    email: params.email,
    password: params.password,
  );
}

// Example of using Either in the application
final result = await signInWithEmailUseCase(
  SignInWithEmailParams(email: 'user@example.com', password: 'password'),
);

result.fold(
  (failure) => // Handle failure case,
  (user) => // Handle success case,
);
```

### Dependency Injection

While the domain layer defines interfaces, it relies on dependency injection to provide implementations at runtime. The service locator pattern is used:

```dart
// Registering use cases in the service locator
void initDomainDependencies() {
  // Auth use cases
  sl.registerLazySingleton(() => SignInWithEmailUseCase(sl()));
  sl.registerLazySingleton(() => SignUpWithEmailUseCase(sl()));
  sl.registerLazySingleton(() => SignInAnonymouslyUseCase(sl()));
  sl.registerLazySingleton(() => SignOutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));
  sl.registerLazySingleton(() => IsSignedInUseCase(sl()));
  
  // Message use cases
  sl.registerLazySingleton(() => SendMessageUseCase(sl()));
  sl.registerLazySingleton(() => GetMessagesUseCase(sl()));
  sl.registerLazySingleton(() => MarkAsReadUseCase(sl()));
  sl.registerLazySingleton(() => GetConversationsUseCase(sl()));
  sl.registerLazySingleton(() => MessagesStreamUseCase(sl()));
  sl.registerLazySingleton(() => ConversationsStreamUseCase(sl()));
  sl.registerLazySingleton(() => UpdateTypingStatusUseCase(sl()));
  sl.registerLazySingleton(() => TypingStatusStreamUseCase(sl()));
  
  // User use cases
  sl.registerLazySingleton(() => GetUserByIdUseCase(sl()));
  sl.registerLazySingleton(() => UpdateUserProfileUseCase(sl()));
  sl.registerLazySingleton(() => UploadProfilePictureUseCase(sl()));
  sl.registerLazySingleton(() => UpdateOnlineStatusUseCase(sl()));
  sl.registerLazySingleton(() => GetUserSettingsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateUserSettingsUseCase(sl()));
  sl.registerLazySingleton(() => SearchUsersUseCase(sl()));
  sl.registerLazySingleton(() => UserPresenceStreamUseCase(sl()));
}
```

### Testing

The domain layer is designed for testability. Use cases and repositories are easily testable through mocking:

```dart
void main() {
  late SignInWithEmailUseCase useCase;
  late MockAuthRepository mockRepository;

  setUp(() {
    mockRepository = MockAuthRepository();
    useCase = SignInWithEmailUseCase(mockRepository);
  });

  final tEmail = 'test@example.com';
  final tPassword = 'password123';
  final tUser = User(
    id: 'user-123',
    name: 'Test User',
    email: tEmail,
    isOnline: true,
  );

  test('should get user from the repository when login is successful', () async {
    // arrange
    when(() => mockRepository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Right(tUser));
    
    // act
    final result = await useCase(
      SignInWithEmailParams(email: tEmail, password: tPassword),
    );
    
    // assert
    expect(result, Right(tUser));
    verify(() => mockRepository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        )).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should return AuthFailure when login fails', () async {
    // arrange
    final tFailure = AuthFailure(message: 'Invalid credentials');
    when(() => mockRepository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        )).thenAnswer((_) async => Left(tFailure));
    
    // act
    final result = await useCase(
      SignInWithEmailParams(email: tEmail, password: tPassword),
    );
    
    // assert
    expect(result, Left(tFailure));
    verify(() => mockRepository.signInWithEmail(
          email: tEmail,
          password: tPassword,
        )).called(1);
    verifyNoMoreInteractions(mockRepository);
  });
}
```

## Domain Layer Dependencies

The domain layer has minimal dependencies:

1. **dartz**: For functional programming constructs like `Either`
2. **equatable**: For equality and value comparison
3. **meta**: For annotations like `@required`

The domain layer explicitly has no dependencies on:

1. Flutter/Dart UI components
2. Firebase or other external services
3. Platform-specific code
4. Implementation details from other layers

## Implementation Examples

### Authentication Module

```dart
// Entity
class User extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? photoUrl;
  final String? status;
  final bool isOnline;
  final DateTime? lastSeen;

  const User({
    required this.id,
    required this.name,
    this.email,
    this.photoUrl,
    this.status,
    required this.isOnline,
    this.lastSeen,
  });

  @override
  List<Object?> get props => [id, name, email, photoUrl, status, isOnline, lastSeen];
}

// Repository Interface
abstract class AuthRepository {
  Future<Either<Failure, User>> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });
  
  Future<Either<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  });
  
  Future<Either<Failure, User>> signInAnonymously();
  
  Future<Either<Failure, void>> signOut();
  
  Future<Either<Failure, User?>> getCurrentUser();
  
  Future<bool> isSignedIn();
}

// Use Case
class SignInWithEmailUseCase implements UseCase<User, SignInWithEmailParams> {
  final AuthRepository repository;

  SignInWithEmailUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(SignInWithEmailParams params) async {
    return await repository.signInWithEmail(
      email: params.email,
      password: params.password,
    );
  }
}

class SignInWithEmailParams extends Equatable {
  final String email;
  final String password;

  const SignInWithEmailParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}
```

### Messaging Module

```dart
// Entities
class Message extends Equatable {
  final String id;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final MessageStatus status;

  const Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.type,
    required this.timestamp,
    required this.status,
  });

  @override
  List<Object> get props => [id, senderId, receiverId, content, type, timestamp, status];
}

enum MessageType { text, image, video, audio }

enum MessageStatus { sent, delivered, read }

class Conversation extends Equatable {
  final String id;
  final List<String> participantIds;
  final Message lastMessage;
  final DateTime updatedAt;
  final Map<String, int> unreadCount;

  const Conversation({
    required this.id,
    required this.participantIds,
    required this.lastMessage,
    required this.updatedAt,
    required this.unreadCount,
  });

  @override
  List<Object> get props => [id, participantIds, lastMessage, updatedAt, unreadCount];
}

// Repository Interface
abstract class MessageRepository {
  Future<Either<Failure, Message>> sendMessage(Message message);
  
  Future<Either<Failure, List<Message>>> getMessages({
    required String userId1,
    required String userId2,
    int limit = 20,
    Message? lastMessage,
  });
  
  Future<Either<Failure, void>> markAsRead({
    required String senderId,
    required String receiverId,
  });
  
  Future<Either<Failure, List<Conversation>>> getConversations(String userId);
  
  Stream<List<Message>> messagesStream({
    required String userId1,
    required String userId2,
  });
  
  Stream<List<Conversation>> conversationsStream(String userId);
  
  Future<Either<Failure, void>> updateTypingStatus({
    required String senderId,
    required String receiverId,
    required bool isTyping,
  });
  
  Stream<bool> typingStatusStream({
    required String senderId,
    required String receiverId,
  });
}

// Use Case
class SendMessageUseCase implements UseCase<Message, SendMessageParams> {
  final MessageRepository repository;

  SendMessageUseCase(this.repository);

  @override
  Future<Either<Failure, Message>> call(SendMessageParams params) async {
    return await repository.sendMessage(params.message);
  }
}

class SendMessageParams extends Equatable {
  final Message message;

  const SendMessageParams({required this.message});

  @override
  List<Object> get props => [message];
}
```

## Future Enhancements

1. **Value Objects**: Implement domain-specific value objects with validation
2. **Domain Events**: Add support for domain events for cross-boundary communication
3. **Specifications Pattern**: For complex query and filtering logic
4. **Refined Error Handling**: More specific failure types and error codes
5. **Better Stream Handling**: More consistent approach to streaming data
6. **Cross-Entity Validation**: Validate relationships between different entities
7. **Optimistic Updates**: Support for optimistic updates in domain operations
8. **Command Pattern**: Implement commands for more complex operations
9. **Batch Operations**: Support for batched domain operations
10. **Time-based Operations**: Support for time-based business rules 