# Flutter Messaging App Architecture

This document describes the architectural patterns and design principles used in the Flutter Messaging app.

## Clean Architecture Overview

The application follows Clean Architecture principles, separating the code into distinct layers with clear boundaries:

```
lib/
├── core/            # Core functionality
│   ├── config/      # Configuration files
│   ├── network/     # Network related code
│   └── utils/       # Utility classes
├── data/            # Data layer
│   ├── datasources/ # Data sources implementation
│   ├── models/      # Data models
│   └── repositories/# Repository implementations
├── domain/          # Domain layer
│   ├── entities/    # Business entities
│   ├── repositories/# Repository interfaces
│   └── usecases/    # Use cases
└── presentation/    # Presentation layer
    ├── pages/       # UI pages
    └── widgets/     # Reusable widgets
```

### Layer Responsibilities

#### Domain Layer

The domain layer contains the business logic of the application and is independent of other layers.

- **Entities**: Core business objects like `User` and `Message`
- **Repositories**: Interfaces defining data operations
- **Use Cases**: Business rules that orchestrate the flow of data

Example domain entity (`User`):
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
```

#### Data Layer

The data layer implements the repository interfaces defined in the domain layer.

- **Models**: Data representations (extends domain entities)
- **Data Sources**: Classes responsible for fetching data from specific sources
- **Repositories**: Implementation of domain repositories

Example repository implementation:
```dart
class UserRepositoryImpl implements UserRepository {
  final UserDataSource userDataSource;
  final NetworkInfo networkInfo;

  UserRepositoryImpl({
    required this.userDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> getUserProfile({required String userId}) async {
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
  
  // Additional methods...
}
```

#### Presentation Layer

The presentation layer contains UI components and state management.

- **Pages**: Screen-level widgets
- **Widgets**: Reusable UI components
- **Providers**: State management (using Riverpod)

Example page:
```dart
class ChatPage extends ConsumerWidget {
  final User receiver;

  const ChatPage({required this.receiver, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messages = ref.watch(messagesProvider(receiver.id));
    
    // UI implementation...
  }
}
```

## Dependency Injection

The application uses GetIt as a service locator for dependency injection. This approach decouples object creation from object usage and facilitates testing.

```dart
// Global instance of GetIt service locator
final sl = GetIt.instance;

// Initialize all dependencies
Future<void> init() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);
  
  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
  
  // Data sources & repositories
  sl.registerLazySingleton<UserDataSource>(() => UserDataSourceImpl(firestore: sl(), firebaseAuth: sl()));
  sl.registerLazySingleton<UserRepository>(() => UserRepositoryImpl(userDataSource: sl(), networkInfo: sl()));
  
  // Use cases
  sl.registerLazySingleton(() => GetUserProfileUseCase(sl()));
  
  // For web testing, we have mock implementations
  if (kIsWeb) {
    _registerMocks();
  } else {
    _registerFirebaseImplementations();
  }
}
```

## State Management

The application uses Riverpod for state management, which provides:

- Reactive state management with providers
- Automatic dependency tracking
- Testability

Example provider:
```dart
final authStateProvider = FutureProvider.autoDispose<bool>((ref) async {
  final authRepository = sl<AuthRepository>();
  return await authRepository.isSignedIn();
});
```

## Error Handling

We use a consistent error handling approach:

1. All errors are wrapped into `Failure` objects
2. The Either type from Dartz is used to handle success/failure
3. Repositories return `Either<Failure, T>` to propagate errors elegantly

```dart
abstract class Failure extends Equatable {
  final String message;
  final int code;

  const Failure({
    required this.message,
    this.code = 0,
  });

  @override
  List<Object> get props => [message, code];
}

// Repository method
Future<Either<Failure, User>> getUserProfile({required String userId}) async {
  // Implementation
}
```

## Platform-Specific Configuration

The application detects the platform and adjusts its behavior accordingly:

```dart
if (kIsWeb) {
  // Web-specific implementation
  _registerMocks();
} else {
  // Native platform implementation
  _registerFirebaseImplementations();
}
```

## Mock Implementation for Web

For web testing, we've implemented mock repositories that mimic the behavior of Firebase without requiring actual Firebase credentials:

```dart
class MockAuthRepository implements AuthRepository {
  // Mock implementation of authentication methods
}

class MockMessageRepository implements MessageRepository {
  // Mock implementation of messaging methods
}
```

## Future Architecture Considerations

1. **Modularization**: Consider breaking the app into feature modules for better separation
2. **Caching Strategy**: Implement a more robust caching mechanism
3. **Offline Support**: Enhance offline capabilities
4. **Performance Optimization**: Implement pagination for message loading
5. **Security**: Review security practices, especially around data encryption 