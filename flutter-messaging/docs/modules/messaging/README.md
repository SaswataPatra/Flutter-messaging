# Messaging Module

This document describes the messaging module of the Flutter Messaging application, detailing its features, components, and implementation.

## Features

The messaging module provides the following features:

- Real-time one-to-one messaging
- Message history retrieval
- Message status tracking (sent, delivered, read)
- Typing indicators
- Multimedia messaging (text, images)
- Online status indicators
- Chat list with recent conversations
- Unread message count

## Components

### Domain Layer

#### Entities

- `Message`: Represents a message in a conversation

```dart
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

- `Conversation`: Represents a chat conversation between two users

```dart
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
```

#### Repository Interfaces

- `MessageRepository`: Defines contract for message operations

```dart
abstract class MessageRepository {
  // Send a new message
  Future<Either<Failure, Message>> sendMessage(Message message);
  
  // Get messages between two users
  Future<Either<Failure, List<Message>>> getMessages({
    required String userId1,
    required String userId2,
    int limit = 20,
    Message? lastMessage,
  });
  
  // Mark messages as read
  Future<Either<Failure, void>> markAsRead({
    required String senderId,
    required String receiverId,
  });
  
  // Get user's conversations
  Future<Either<Failure, List<Conversation>>> getConversations(String userId);
  
  // Stream of messages between two users
  Stream<List<Message>> messagesStream({
    required String userId1,
    required String userId2,
  });
  
  // Stream of user's conversations
  Stream<List<Conversation>> conversationsStream(String userId);
  
  // Update typing status
  Future<Either<Failure, void>> updateTypingStatus({
    required String senderId,
    required String receiverId,
    required bool isTyping,
  });
  
  // Stream of typing status for a conversation
  Stream<bool> typingStatusStream({
    required String senderId,
    required String receiverId,
  });
}
```

#### Use Cases

- `SendMessageUseCase`: Handle sending message business logic
- `GetMessagesUseCase`: Handle message retrieval business logic
- `MarkMessagesAsReadUseCase`: Handle marking messages as read
- `GetConversationsUseCase`: Handle conversation list retrieval
- `MessagesStreamUseCase`: Stream of messages for a conversation
- `ConversationsStreamUseCase`: Stream of user's conversations
- `UpdateTypingStatusUseCase`: Update typing status
- `TypingStatusStreamUseCase`: Stream of typing status

Example Use Case implementation:

```dart
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

### Data Layer

#### Data Sources

- `MessageDataSource`: Provides implementation for message operations

```dart
abstract class MessageDataSource {
  Future<MessageModel> sendMessage(MessageModel message);
  Future<List<MessageModel>> getMessages({
    required String userId1,
    required String userId2,
    int limit = 20,
    MessageModel? lastMessage,
  });
  Future<void> markAsRead({
    required String senderId,
    required String receiverId,
  });
  Future<List<ConversationModel>> getConversations(String userId);
  Stream<List<MessageModel>> messagesStream({
    required String userId1,
    required String userId2,
  });
  Stream<List<ConversationModel>> conversationsStream(String userId);
  Future<void> updateTypingStatus({
    required String senderId,
    required String receiverId,
    required bool isTyping,
  });
  Stream<bool> typingStatusStream({
    required String senderId,
    required String receiverId,
  });
}

class FirebaseMessageDataSource implements MessageDataSource {
  final FirebaseFirestore firestore;

  FirebaseMessageDataSource({required this.firestore});

  // Implementation methods...
}

class MockMessageDataSource implements MessageDataSource {
  // Mock implementation for web-only testing...
}
```

#### Models

- `MessageModel`: Data representation of a message

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
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp']),
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
}
```

- `ConversationModel`: Data representation of a conversation

```dart
class ConversationModel extends Conversation {
  const ConversationModel({
    required super.id,
    required super.participantIds,
    required super.lastMessage,
    required super.updatedAt,
    required super.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'],
      participantIds: List<String>.from(json['participantIds']),
      lastMessage: MessageModel.fromJson(json['lastMessage']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt']),
      unreadCount: Map<String, int>.from(json['unreadCount']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantIds': participantIds,
      'lastMessage': (lastMessage as MessageModel).toJson(),
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'unreadCount': unreadCount,
    };
  }
}
```

#### Repository Implementation

- `MessageRepositoryImpl`: Implements the message repository interface

```dart
class MessageRepositoryImpl implements MessageRepository {
  final MessageDataSource dataSource;
  final NetworkInfo networkInfo;

  MessageRepositoryImpl({
    required this.dataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, Message>> sendMessage(Message message) async {
    if (await networkInfo.isConnected) {
      try {
        final messageModel = await dataSource.sendMessage(message as MessageModel);
        return Right(messageModel);
      } catch (e) {
        return Left(MessageFailure(message: e.toString()));
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

- `messagesProvider`: StateNotifierProvider for messages in a conversation
- `conversationsProvider`: StateNotifierProvider for user's conversations
- `typingStatusProvider`: StateProvider for typing status

```dart
final messagesProvider = StateNotifierProvider.family<MessagesNotifier, List<Message>, String>(
  (ref, conversationId) => MessagesNotifier(
    getMessagesUseCase: sl<GetMessagesUseCase>(),
    messagesStreamUseCase: sl<MessagesStreamUseCase>(),
    conversationId: conversationId,
  ),
);

class MessagesNotifier extends StateNotifier<List<Message>> {
  final GetMessagesUseCase getMessagesUseCase;
  final MessagesStreamUseCase messagesStreamUseCase;
  final String conversationId;
  StreamSubscription<List<Message>>? _messagesSubscription;

  MessagesNotifier({
    required this.getMessagesUseCase,
    required this.messagesStreamUseCase,
    required this.conversationId,
  }) : super([]) {
    _init();
  }

  Future<void> _init() async {
    // Load initial messages and set up stream subscription
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
```

#### Pages and Widgets

- `ChatPage`: UI for a conversation
- `ChatListPage`: UI for the list of conversations
- `MessageBubble`: Widget for displaying a message
- `ChatInput`: Widget for message input and sending

Example `ChatPage` implementation:

```dart
class ChatPage extends ConsumerStatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatPage({
    Key? key,
    required this.receiverId,
    required this.receiverName,
  }) : super(key: key);

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late String currentUserId;
  String? conversationId;
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Initialize current user ID and conversation ID
    // Set up scroll controller
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _sendMessage() {
    // Create and send message
  }

  void _handleTyping() {
    // Handle typing indicator logic
  }

  @override
  Widget build(BuildContext context) {
    // Build UI with message list and input area
  }
}
```

## Messaging Flow and Architecture

### Database Structure (Firebase)

Messages are stored in Firestore with the following structure:

```
/messages/{messageId} - Individual message documents
  - id: String (unique ID)
  - senderId: String (user ID)
  - receiverId: String (user ID)
  - content: String
  - type: String (text, image, etc.)
  - timestamp: Timestamp
  - status: String (sent, delivered, read)

/conversations/{conversationId} - Conversation metadata
  - id: String (unique ID, typically a combination of the two user IDs)
  - participantIds: Array<String> (user IDs)
  - lastMessage: Map (the most recent message)
  - updatedAt: Timestamp
  - unreadCount: Map<String, int> (counts of unread messages per user)

/typingStatus/{conversationId} - Typing indicators
  - userId: String
  - isTyping: Boolean
  - timestamp: Timestamp
```

### Conversation ID Generation

To ensure consistent conversation IDs between two users:

```dart
String generateConversationId(String userId1, String userId2) {
  List<String> ids = [userId1, userId2];
  ids.sort(); // Sort to ensure the same ID regardless of parameter order
  return ids.join('_');
}
```

### Real-time Messaging

Firestore streams are used to provide real-time updates:

1. Messages are added to the database when sent
2. UI subscribes to message streams for the current conversation
3. When new messages arrive, the UI updates automatically
4. Read status is updated when messages are viewed
5. Typing indicators use a similar real-time mechanism

### Offline Support

The messaging module supports offline capabilities:

1. Sent messages are cached locally and queued for sending when online
2. Received messages are cached locally for offline viewing
3. Firestore persistence enables accessing previously loaded content offline
4. Sync happens automatically when the device comes back online

### Image Message Handling

For image messages:

1. Images are selected from device gallery or camera
2. Images are uploaded to Firebase Storage
3. The download URL is stored in the message content
4. Images are cached locally for faster loading
5. The UI shows loading indicators during upload and download

## Web vs. Native Implementation

For web development and testing:

```dart
class MockMessageDataSource implements MessageDataSource {
  final List<MessageModel> _messages = [];
  final Map<String, List<ConversationModel>> _conversations = {};
  
  @override
  Future<MessageModel> sendMessage(MessageModel message) async {
    _messages.add(message);
    // Update conversations
    return message;
  }
  
  // Other method implementations...
}
```

For native platforms:

```dart
sl.registerLazySingleton<FirebaseFirestore>(
  () => FirebaseFirestore.instance,
);
sl.registerLazySingleton<MessageDataSource>(
  () => FirebaseMessageDataSource(firestore: sl()),
);
```

## Error Handling

Messaging errors are wrapped in `MessageFailure` objects:

```dart
class MessageFailure extends Failure {
  const MessageFailure({required String message, int code = 500})
      : super(message: message, code: code);
}
```

Common error scenarios handled:

1. Network connectivity issues
2. Message sending failures
3. Image upload failures
4. Permission issues
5. Database transaction failures

## Performance Considerations

1. **Pagination**: Messages are loaded in batches (typically 20 at a time)
2. **Caching**: Images are cached to avoid redownloading
3. **Optimistic Updates**: UI updates before server confirmation for better responsiveness
4. **Debounce**: Typing indicators use debounce to reduce database writes

## Testing Messaging

Manual testing steps:

1. Open the app and navigate to the chat list
2. Select an existing conversation or create a new one
3. Send text messages and verify they appear in real-time
4. Send image messages and verify upload/download
5. Test offline functionality by enabling airplane mode
6. Verify typing indicators and read receipts
7. Test conversation list updates with latest messages

## Future Enhancements

1. Group chat functionality
2. Message reactions (like, love, etc.)
3. Message replies and threading
4. Message search functionality
5. End-to-end encryption
6. Message deletion and editing
7. Voice messages
8. Video calls integration 