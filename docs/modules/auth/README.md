# Authentication Module

This document describes the authentication module of the Flutter Messaging application, detailing its features, components, and implementation.

## Features

The authentication module provides the following features:

- Email/password authentication
- Anonymous sign-in (guest mode)
- User session management
- Sign-out functionality
- User registration
- Current user retrieval

## Components

### Domain Layer

#### Entities

- `User`: Represents an authenticated user

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

#### Repository Interface

- `AuthRepository`: Defines the contract for authentication operations

```dart
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
```

#### Use Cases

- `SignInWithEmailUseCase`: Handle email sign-in business logic
- `SignUpWithEmailUseCase`: Handle user registration business logic
- `SignInAnonymouslyUseCase`: Handle anonymous sign-in business logic
- `SignOutUseCase`: Handle sign-out business logic
- `GetCurrentUserUseCase`: Retrieve the currently authenticated user
- `IsSignedInUseCase`: Check if a user is currently signed in

Example Use Case implementation:

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

### Data Layer

#### Data Sources

- `AuthDataSource`: Provides the implementation for authentication operations

```dart
abstract class AuthDataSource {
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  });

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  });

  Future<UserModel> signInAnonymously();

  Future<void> signOut();

  Future<UserModel?> getCurrentUser();

  Future<bool> isSignedIn();
}

class AuthDataSourceImpl implements AuthDataSource {
  final firebase_auth.FirebaseAuth firebaseAuth;

  AuthDataSourceImpl({required this.firebaseAuth});

  // Implementation of methods...
}

class MockAuthDataSource implements AuthDataSource {
  // Mock implementation for web-only testing...
}
```

#### Models

- `UserModel`: Data representation of a user, extending the domain entity

```dart
class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    super.email,
    super.photoUrl,
    super.status,
    required super.isOnline,
    super.lastSeen,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      photoUrl: json['photoUrl'],
      status: json['status'],
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastSeen'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'status': status,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
    };
  }
}
```

#### Repository Implementation

- `AuthRepositoryImpl`: Implements the auth repository interface

```dart
class AuthRepositoryImpl implements AuthRepository {
  final AuthDataSource authDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.authDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await authDataSource.signInWithEmail(
          email: email,
          password: password,
        );
        return Right(user);
      } catch (e) {
        return Left(AuthFailure(message: e.toString()));
      }
    } else {
      return Left(ConnectionFailure(message: 'No internet connection'));
    }
  }

  // Additional method implementations...
}
```

### Presentation Layer

#### State Management

- `authProvider`: StateProvider to track authentication state

```dart
final authProvider = StateProvider<bool>((ref) => false);

final authStateProvider = FutureProvider.autoDispose<bool>((ref) async {
  final authRepository = sl<AuthRepository>();
  return await authRepository.isSignedIn();
});
```

#### Pages

- `AuthPage`: UI for user authentication
- `SplashPage`: Initial page that checks authentication state

```dart
class AuthPage extends ConsumerStatefulWidget {
  const AuthPage({Key? key}) : super(key: key);

  @override
  ConsumerState<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends ConsumerState<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  bool _isSignUp = false;
  bool _isLoading = false;
  String? _errorMessage;

  // Implementation...
}
```

## Authentication Flow

1. The app starts at `SplashPage`, which checks if a user is already signed in
2. If a user is signed in, they are directed to `HomePage`
3. If not, they are directed to `AuthPage` where they can:
   - Sign in with email and password
   - Sign up with email, password, and name
   - Sign in anonymously as a guest
4. On successful authentication, the user is directed to `HomePage`
5. At any point, the user can sign out, which redirects them back to `AuthPage`

## Web vs. Native Implementation

For web development and testing, we use a mock implementation of the authentication:

```dart
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

  // Additional method implementations...
}
```

For native platforms, we use Firebase Authentication:

```dart
sl.registerLazySingleton<firebase_auth.FirebaseAuth>(
  () => firebase_auth.FirebaseAuth.instance
);
sl.registerLazySingleton<AuthDataSource>(
  () => AuthDataSourceImpl(firebaseAuth: sl()),
);
```

## Error Handling

Authentication errors are wrapped in `AuthFailure` objects:

```dart
class AuthFailure extends Failure {
  const AuthFailure({required String message, int code = 401})
      : super(message: message, code: code);
}
```

Common error scenarios handled:

1. Invalid email format
2. Weak password
3. Email already in use
4. User not found
5. Wrong password
6. Network errors
7. Server errors

## Testing Authentication

Manual testing steps:

1. Open the app and verify you're taken to the authentication page
2. Test sign-up with a new email and valid password
3. Sign out and test sign-in with the created credentials
4. Test sign-in with invalid credentials and verify error messages
5. Test anonymous sign-in
6. Test automatic sign-in when returning to the app

For unit tests, the repository and use cases should be tested with mock data sources.

## Future Enhancements

1. Social authentication (Google, Facebook, Apple)
2. Email verification
3. Password reset functionality
4. Two-factor authentication
5. Biometric authentication for mobile devices
6. Remember me functionality
7. Session timeout management 