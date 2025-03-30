# Presentation Layer

This document describes the presentation layer of the Flutter Messaging application, detailing its components, implementation, and patterns.

## Overview

The presentation layer is responsible for:

- Displaying data to the user through UI components
- Handling user interactions
- Managing UI state with Riverpod
- Implementing navigation between screens
- Providing a responsive and intuitive user experience

The presentation layer follows a clean, modular approach with a clear separation between UI components and state management.

## Components

### Pages

Pages represent full screens in the application. Each page:

1. Consumes data from providers
2. Handles user interactions
3. Manages its local UI state
4. Delegates business logic to use cases via providers

Main pages in the application:

- **SplashPage**: Initial loading screen and authentication check
- **AuthPage**: User authentication (sign in/sign up)
- **HomePage**: Main screen with conversation list
- **ChatPage**: One-to-one messaging interface
- **ProfilePage**: User profile display and editing

Example of a page implementation:

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // UI components...
                  
                  if (_isLoading)
                    const CircularProgressIndicator(),
                  
                  if (_errorMessage != null)
                    Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                    
                  // Form fields, buttons, etc.
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    // Validate form and call authentication use cases
  }
}
```

### Widgets

Widgets are reusable UI components that can be composed together to build pages. They are designed to be:

1. Reusable across different pages
2. Focused on a specific UI responsibility
3. Highly parameterized for flexibility
4. Stateless when possible, or with minimal local state

Key widgets in the application:

- **MessageBubble**: Individual message display
- **UserAvatar**: User profile image with online status indicator
- **ChatInput**: Message composition and sending
- **UserListTile**: User item for lists
- **OnlineStatusIndicator**: Indicator for user's online status

Example of a widget implementation:

```dart
class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;
  final VoidCallback? onLongPress;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isCurrentUser,
    this.onLongPress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isCurrentUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 10.0,
        ),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 2.0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message content based on type
            _buildMessageContent(context),
            
            // Timestamp and status
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    // Message content implementation
  }

  Widget _buildFooter(BuildContext context) {
    // Message footer implementation
  }
}
```

### State Management

The application uses Riverpod for state management, which provides:

1. Dependency injection
2. Reactive state management
3. Efficient rebuilds
4. Easy testing

Key state management patterns used:

#### Providers

Providers are used to expose state and functionality to the UI:

```dart
// Simple state provider for authentication state
final authProvider = StateProvider<bool>((ref) => false);

// Provider for mock users list
final mockUsersProvider = Provider<List<User>>((ref) {
  return [
    User(
      id: '1',
      name: 'Alice Smith',
      email: 'alice@example.com',
      photoUrl: 'https://randomuser.me/api/portraits/women/43.jpg',
      status: 'Available',
      isOnline: true,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 2)),
    ),
    // Other users...
  ];
});

// Provider for authentication state
final authStateProvider = FutureProvider.autoDispose<bool>((ref) async {
  final authRepository = sl<AuthRepository>();
  return await authRepository.isSignedIn();
});
```

#### StateNotifier Providers

StateNotifier providers are used for more complex state management:

```dart
// Provider for messages
final messagesProvider = StateNotifierProvider.family<MessagesNotifier, List<Message>, String>(
  (ref, receiverId) => MessagesNotifier(receiverId),
);

// Notifier for managing messages
class MessagesNotifier extends StateNotifier<List<Message>> {
  final String receiverId;
  final _uuid = Uuid();
  
  MessagesNotifier(this.receiverId) : super([
    // Initial mock messages
    Message(
      id: '1',
      senderId: 'current-user',
      receiverId: 'receiver-id',
      content: 'Hello!',
      type: MessageType.text,
      status: MessageStatus.read,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isDeleted: false,
    ),
    // Other messages...
  ]);
  
  void sendMessage(String content, MessageType type) {
    final newMessage = Message(
      id: _uuid.v4(),
      senderId: 'current-user',
      receiverId: receiverId,
      content: content,
      type: type,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
      isDeleted: false,
    );
    
    state = [...state, newMessage];
  }
  
  void deleteMessage(String messageId) {
    state = state.map((message) {
      if (message.id == messageId) {
        return Message(
          id: message.id,
          senderId: message.senderId,
          receiverId: message.receiverId,
          content: message.content,
          type: message.type,
          status: message.status,
          timestamp: message.timestamp,
          isDeleted: true,
        );
      }
      return message;
    }).toList();
  }
  
  void updateMessageStatus(String messageId, MessageStatus status) {
    state = state.map((message) {
      if (message.id == messageId) {
        return Message(
          id: message.id,
          senderId: message.senderId,
          receiverId: message.receiverId,
          content: message.content,
          type: message.type,
          status: status,
          timestamp: message.timestamp,
          isDeleted: message.isDeleted,
        );
      }
      return message;
    }).toList();
  }
}
```

#### Family Providers

Family providers are used to create parameterized providers:

```dart
final profileDataProvider = StateProvider.family<User, User>((ref, initialUser) => initialUser);

final userOnlineStatusProvider = StreamProvider.family<bool, String>((ref, userId) async* {
  // Implementation...
});
```

### Navigation

The application uses Flutter's built-in navigation system with some custom patterns:

#### Navigator 2.0 Patterns

For simple navigation between screens:

```dart
void _navigateToChat(BuildContext context, User user) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ChatPage(receiver: user),
    ),
  );
}
```

#### Route Generation

For more complex navigation patterns:

```dart
Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case '/':
      return MaterialPageRoute(builder: (_) => const SplashPage());
    case '/auth':
      return MaterialPageRoute(builder: (_) => const AuthPage());
    case '/home':
      return MaterialPageRoute(builder: (_) => const HomePage());
    case '/chat':
      final arguments = settings.arguments as Map<String, dynamic>;
      final user = arguments['user'] as User;
      return MaterialPageRoute(builder: (_) => ChatPage(receiver: user));
    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(
            child: Text('No route defined for ${settings.name}'),
          ),
        ),
      );
  }
}
```

### Error Handling

The presentation layer handles errors in a user-friendly way:

```dart
void _handleError(Failure failure) {
  setState(() {
    _isLoading = false;
    _errorMessage = failure.message;
  });
  
  // Show a snackbar for transient errors
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(failure.message),
      backgroundColor: Colors.red,
    ),
  );
}

// Usage in a consumer widget
ref.watch(authStateProvider).when(
  data: (isSignedIn) {
    // Handle successful data
  },
  loading: () => const CircularProgressIndicator(),
  error: (error, stackTrace) => Text('Error: $error'),
);
```

## UI Design Principles

The application follows these UI design principles:

### Responsive Design

UI adapts to different screen sizes:

```dart
Widget build(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  
  return Scaffold(
    body: screenWidth > 600
        ? _buildTabletLayout()
        : _buildMobileLayout(),
  );
}
```

### Accessible UI

UI components are designed with accessibility in mind:

```dart
ElevatedButton(
  onPressed: _isLoading ? null : _submitForm,
  child: Text(_isLoading ? 'Please wait...' : 'Sign In'),
  style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 16.0),
  ),
);

// Semantic labels for screen readers
Semantics(
  label: 'User profile image',
  child: CircleAvatar(
    backgroundImage: NetworkImage(user.photoUrl ?? ''),
    radius: 24.0,
  ),
);
```

### Theme and Styling

The application uses a consistent theme system:

```dart
MaterialApp(
  title: 'Flutter Messaging',
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.light,
    ),
    useMaterial3: true,
  ),
  darkTheme: ThemeData(
    colorScheme: ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    ),
    useMaterial3: true,
  ),
  themeMode: ThemeMode.system,
  home: const SplashPage(),
);
```

## Communication with Domain Layer

The presentation layer communicates with the domain layer through use cases and repositories:

```dart
// Sign-in functionality in a page
Future<void> _signIn() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });
  
  final params = SignInWithEmailParams(
    email: _emailController.text,
    password: _passwordController.text,
  );
  
  final signInWithEmailUseCase = sl<SignInWithEmailUseCase>();
  final result = await signInWithEmailUseCase(params);
  
  result.fold(
    (failure) {
      setState(() {
        _isLoading = false;
        _errorMessage = failure.message;
      });
    },
    (user) {
      // Navigate to home page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    },
  );
}
```

## Testing the Presentation Layer

The presentation layer is tested through:

### Widget Tests

Testing widgets in isolation:

```dart
testWidgets('MessageBubble renders correctly', (WidgetTester tester) async {
  final message = Message(
    id: '1',
    senderId: 'sender',
    receiverId: 'receiver',
    content: 'Hello',
    type: MessageType.text,
    status: MessageStatus.sent,
    timestamp: DateTime.now(),
    isDeleted: false,
  );
  
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: MessageBubble(
          message: message,
          isCurrentUser: true,
        ),
      ),
    ),
  );
  
  expect(find.text('Hello'), findsOneWidget);
});
```

### Provider Tests

Testing state management:

```dart
test('MessagesNotifier adds a message correctly', () {
  final notifier = MessagesNotifier('test-receiver');
  
  // Initial state check
  expect(notifier.debugState.length, 1);
  
  // Add a message
  notifier.sendMessage('Test message', MessageType.text);
  
  // Verify state has been updated
  expect(notifier.debugState.length, 2);
  expect(notifier.debugState.last.content, 'Test message');
  expect(notifier.debugState.last.type, MessageType.text);
});
```

### Integration Tests

Testing user flows:

```dart
testWidgets('User can sign in and navigate to home page', (WidgetTester tester) async {
  // Build our app and trigger a frame.
  await tester.pumpWidget(const ProviderScope(child: MyApp()));
  
  // Navigate to auth page
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();
  
  // Enter credentials
  await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com');
  await tester.enterText(find.byType(TextFormField).at(1), 'password');
  
  // Submit form
  await tester.tap(find.text('Sign In'));
  await tester.pumpAndSettle();
  
  // Verify navigation to home page
  expect(find.text('Messages'), findsOneWidget);
});
```

## Future Enhancements

1. **Animations**: Add more sophisticated animations for page transitions and UI interactions
2. **Localization**: Implement multi-language support
3. **Theming**: Add more theme options and custom themes
4. **Accessibility**: Enhance accessibility features
5. **Responsive Design**: Improve tablet and desktop layouts
6. **State Management**: Refine the state management with more efficient patterns
7. **Error Handling**: Improve error handling and recovery mechanisms
8. **Offline UI**: Enhance UI for offline mode
9. **Performance Optimization**: Optimize UI rendering for better performance
10. **Design System**: Implement a more comprehensive design system 