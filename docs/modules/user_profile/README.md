# User Profile Module

This document describes the user profile module of the Flutter Messaging application, detailing its features, components, and implementation.

## Features

The user profile module provides the following features:

- User profile creation and setup
- Profile viewing and editing
- User status management (online/offline)
- Profile picture upload and management
- User search functionality
- User presence tracking (last seen)
- Profile privacy settings

## Components

### Domain Layer

#### Entities

- `User`: Represents a user profile

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

- `UserSettings`: Represents user profile settings

```dart
class UserSettings extends Equatable {
  final String userId;
  final bool showOnlineStatus;
  final bool showLastSeen;
  final bool allowMessageRequests;
  final NotificationPreference notificationPreference;

  const UserSettings({
    required this.userId,
    required this.showOnlineStatus,
    required this.showLastSeen,
    required this.allowMessageRequests,
    required this.notificationPreference,
  });

  @override
  List<Object> get props => [userId, showOnlineStatus, showLastSeen, allowMessageRequests, notificationPreference];
}

enum NotificationPreference { all, mentions, none }
```

#### Repository Interfaces

- `UserRepository`: Defines contract for user profile operations

```dart
abstract class UserRepository {
  // Get user profile by ID
  Future<Either<Failure, User>> getUserById(String userId);
  
  // Update user profile
  Future<Either<Failure, User>> updateUserProfile(User user);
  
  // Upload profile picture
  Future<Either<Failure, String>> uploadProfilePicture(String userId, File imageFile);
  
  // Update online status
  Future<Either<Failure, void>> updateOnlineStatus(String userId, bool isOnline);
  
  // Get user settings
  Future<Either<Failure, UserSettings>> getUserSettings(String userId);
  
  // Update user settings
  Future<Either<Failure, UserSettings>> updateUserSettings(UserSettings settings);
  
  // Search users by name
  Future<Either<Failure, List<User>>> searchUsers(String query, {int limit = 20});
  
  // Get user presence (online status and last seen)
  Stream<User> userPresenceStream(String userId);
}
```

#### Use Cases

- `GetUserByIdUseCase`: Handle user profile retrieval by ID
- `UpdateUserProfileUseCase`: Handle user profile update business logic
- `UploadProfilePictureUseCase`: Handle profile picture upload business logic
- `UpdateOnlineStatusUseCase`: Handle online status update business logic
- `GetUserSettingsUseCase`: Handle user settings retrieval business logic
- `UpdateUserSettingsUseCase`: Handle user settings update business logic
- `SearchUsersUseCase`: Handle user search business logic
- `UserPresenceStreamUseCase`: Stream of user presence updates

Example Use Case implementation:

```dart
class UpdateUserProfileUseCase implements UseCase<User, UpdateUserProfileParams> {
  final UserRepository repository;

  UpdateUserProfileUseCase(this.repository);

  @override
  Future<Either<Failure, User>> call(UpdateUserProfileParams params) async {
    return await repository.updateUserProfile(params.user);
  }
}

class UpdateUserProfileParams extends Equatable {
  final User user;

  const UpdateUserProfileParams({required this.user});

  @override
  List<Object> get props => [user];
}
```

### Data Layer

#### Data Sources

- `UserDataSource`: Provides implementation for user profile operations

```dart
abstract class UserDataSource {
  Future<UserModel> getUserById(String userId);
  Future<UserModel> updateUserProfile(UserModel user);
  Future<String> uploadProfilePicture(String userId, File imageFile);
  Future<void> updateOnlineStatus(String userId, bool isOnline);
  Future<UserSettingsModel> getUserSettings(String userId);
  Future<UserSettingsModel> updateUserSettings(UserSettingsModel settings);
  Future<List<UserModel>> searchUsers(String query, {int limit = 20});
  Stream<UserModel> userPresenceStream(String userId);
}

class FirebaseUserDataSource implements UserDataSource {
  final FirebaseFirestore firestore;
  final FirebaseStorage storage;

  FirebaseUserDataSource({
    required this.firestore,
    required this.storage,
  });

  // Implementation methods...
}

class MockUserDataSource implements UserDataSource {
  // Mock implementation for web-only testing...
}
```

#### Models

- `UserModel`: Data representation of a user profile

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

- `UserSettingsModel`: Data representation of user settings

```dart
class UserSettingsModel extends UserSettings {
  const UserSettingsModel({
    required super.userId,
    required super.showOnlineStatus,
    required super.showLastSeen,
    required super.allowMessageRequests,
    required super.notificationPreference,
  });

  factory UserSettingsModel.fromJson(Map<String, dynamic> json) {
    return UserSettingsModel(
      userId: json['userId'],
      showOnlineStatus: json['showOnlineStatus'] ?? true,
      showLastSeen: json['showLastSeen'] ?? true,
      allowMessageRequests: json['allowMessageRequests'] ?? true,
      notificationPreference: NotificationPreference.values.byName(
          json['notificationPreference'] ?? NotificationPreference.all.name),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'showOnlineStatus': showOnlineStatus,
      'showLastSeen': showLastSeen,
      'allowMessageRequests': allowMessageRequests,
      'notificationPreference': notificationPreference.name,
    };
  }
}
```

#### Repository Implementation

- `UserRepositoryImpl`: Implements the user repository interface

```dart
class UserRepositoryImpl implements UserRepository {
  final UserDataSource dataSource;
  final NetworkInfo networkInfo;

  UserRepositoryImpl({
    required this.dataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, User>> getUserById(String userId) async {
    if (await networkInfo.isConnected) {
      try {
        final user = await dataSource.getUserById(userId);
        return Right(user);
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

### Presentation Layer

#### State Management

- `userProfileProvider`: StateNotifierProvider for the current user's profile
- `userSettingsProvider`: StateNotifierProvider for the current user's settings
- `otherUserProfileProvider`: FutureProvider.family for viewing other users' profiles

```dart
final userProfileProvider = StateNotifierProvider<UserProfileNotifier, AsyncValue<User>>(
  (ref) => UserProfileNotifier(
    getUserByIdUseCase: sl<GetUserByIdUseCase>(),
    updateUserProfileUseCase: sl<UpdateUserProfileUseCase>(),
    updateOnlineStatusUseCase: sl<UpdateOnlineStatusUseCase>(),
  ),
);

class UserProfileNotifier extends StateNotifier<AsyncValue<User>> {
  final GetUserByIdUseCase getUserByIdUseCase;
  final UpdateUserProfileUseCase updateUserProfileUseCase;
  final UpdateOnlineStatusUseCase updateOnlineStatusUseCase;

  UserProfileNotifier({
    required this.getUserByIdUseCase,
    required this.updateUserProfileUseCase,
    required this.updateOnlineStatusUseCase,
  }) : super(const AsyncValue.loading()) {
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    // Get current user ID and load profile
  }

  Future<void> updateProfile({
    String? name,
    String? status,
    String? photoUrl,
  }) async {
    // Update user profile
  }

  @override
  void dispose() {
    // Update offline status when app is closed
    super.dispose();
  }
}
```

#### Pages and Widgets

- `ProfilePage`: UI for viewing and editing user profile
- `ProfileSettingsPage`: UI for managing profile settings
- `UserSearchPage`: UI for searching users
- `UserListTile`: Widget for displaying user information in lists
- `ProfilePictureWidget`: Widget for displaying and updating profile pictures

Example `ProfilePage` implementation:

```dart
class ProfilePage extends ConsumerStatefulWidget {
  final String? userId; // If null, show current user's profile

  const ProfilePage({Key? key, this.userId}) : super(key: key);

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _statusController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    // Initialize controllers
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    super.dispose();
  }
  
  Future<void> _updateProfile() async {
    // Update profile logic
  }
  
  Future<void> _pickImage() async {
    // Image picker logic
  }
  
  @override
  Widget build(BuildContext context) {
    // Build UI with profile information and edit options
  }
}
```

## User Profile Flow and Architecture

### Database Structure (Firebase)

User profiles are stored in Firestore with the following structure:

```
/users/{userId} - User profile documents
  - id: String (unique ID, matches auth UID)
  - name: String
  - email: String
  - photoUrl: String (URL to profile picture)
  - status: String (status message)
  - isOnline: Boolean
  - lastSeen: Timestamp

/userSettings/{userId} - User settings documents
  - userId: String (matches users collection ID)
  - showOnlineStatus: Boolean
  - showLastSeen: Boolean
  - allowMessageRequests: Boolean
  - notificationPreference: String (all, mentions, none)
```

### Profile Picture Management

Profile pictures are handled through Firebase Storage:

1. Images are selected from device gallery or camera
2. Images are resized and compressed before upload
3. Images are stored in a path like `/profile_pictures/{userId}/{timestamp}.jpg`
4. The download URL is saved to the user's profile
5. Images are cached locally for faster loading

```dart
Future<String> uploadProfilePicture(String userId, File imageFile) async {
  // Resize and compress image
  final compressedImage = await compressImage(imageFile);
  
  // Create storage reference
  final storageRef = storage.ref().child(
    'profile_pictures/${userId}/${DateTime.now().millisecondsSinceEpoch}.jpg'
  );
  
  // Upload file
  await storageRef.putFile(compressedImage);
  
  // Get download URL
  final downloadUrl = await storageRef.getDownloadURL();
  
  return downloadUrl;
}
```

### User Presence System

The user presence system handles online status and last seen time:

1. When a user logs in, their status is set to online
2. A listener is attached to the app's lifecycle to detect when it goes to background
3. When the app goes to background, the user's status is set to offline and lastSeen is updated
4. When the app returns to foreground, the user's status is set back to online
5. Firebase Realtime Database is used for presence tracking for better performance
6. Firebase Cloud Functions handle cleanup of offline users

Example presence handling:

```dart
void setupPresenceTracking(String userId) {
  // Set up app lifecycle listener
  SystemChannels.lifecycle.setMessageHandler((message) async {
    if (message == AppLifecycleState.paused.toString()) {
      await updateOnlineStatus(userId, false);
    } else if (message == AppLifecycleState.resumed.toString()) {
      await updateOnlineStatus(userId, true);
    }
    return message;
  });
  
  // Set initial online status
  updateOnlineStatus(userId, true);
}
```

### User Search Implementation

User search is implemented with Firestore queries:

1. The search query is used to perform a prefix search on the name field
2. Results are paginated to improve performance
3. Result caching is implemented to reduce database reads
4. Recent searches are stored locally for quick access

```dart
Future<List<UserModel>> searchUsers(String query, {int limit = 20}) async {
  if (query.isEmpty) return [];
  
  final querySnapshot = await firestore
      .collection('users')
      .where('name', isGreaterThanOrEqualTo: query)
      .where('name', isLessThan: query + 'z')
      .limit(limit)
      .get();
  
  return querySnapshot.docs
      .map((doc) => UserModel.fromJson(doc.data()))
      .toList();
}
```

## Web vs. Native Implementation

For web development and testing:

```dart
class MockUserDataSource implements UserDataSource {
  final Map<String, UserModel> _users = {
    'user1': const UserModel(
      id: 'user1',
      name: 'Test User 1',
      email: 'test1@example.com',
      isOnline: true,
      status: 'Available',
    ),
    'user2': const UserModel(
      id: 'user2',
      name: 'Test User 2',
      email: 'test2@example.com',
      isOnline: false,
      lastSeen: null,
    ),
  };
  
  final Map<String, UserSettingsModel> _settings = {};
  
  @override
  Future<UserModel> getUserById(String userId) async {
    if (_users.containsKey(userId)) {
      return _users[userId]!;
    } else {
      throw Exception('User not found');
    }
  }
  
  // Other method implementations...
}
```

For native platforms:

```dart
sl.registerLazySingleton<FirebaseFirestore>(
  () => FirebaseFirestore.instance,
);
sl.registerLazySingleton<FirebaseStorage>(
  () => FirebaseStorage.instance,
);
sl.registerLazySingleton<UserDataSource>(
  () => FirebaseUserDataSource(
    firestore: sl(),
    storage: sl(),
  ),
);
```

## Error Handling

User profile errors are wrapped in `UserFailure` objects:

```dart
class UserFailure extends Failure {
  const UserFailure({required String message, int code = 404})
      : super(message: message, code: code);
}
```

Common error scenarios handled:

1. User not found
2. Profile picture upload failures
3. Permission issues
4. Network connectivity issues
5. Data validation errors

## Performance Considerations

1. **Profile Caching**: User profiles are cached locally for faster access
2. **Image Optimization**: Profile pictures are compressed and resized before upload
3. **Lazy Loading**: User data is loaded only when needed
4. **Batch Operations**: Updates to multiple fields are batched for efficiency
5. **Incremental Updates**: Only changed fields are updated rather than the entire profile

## Testing User Profile Module

Manual testing steps:

1. Create a new user account and verify profile setup
2. Edit profile information and verify changes persist
3. Upload a profile picture and verify it displays correctly
4. Change user settings and verify they take effect
5. Test search functionality with various queries
6. Verify presence tracking by logging in/out on multiple devices
7. Test profile visibility based on privacy settings

Unit testing considerations:

1. Test repository methods with mock data sources
2. Test use cases to ensure business logic is correct
3. Test models for correct serialization/deserialization
4. Test UI components with mock data

## Future Enhancements

1. Profile verification badges
2. Profile themes and customization options
3. Profile sharing via deep links
4. User blocking functionality
5. Enhanced privacy controls
6. Activity status with custom messages
7. Multiple profile pictures
8. Integration with social media profiles 