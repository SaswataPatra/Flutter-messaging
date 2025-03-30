import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:uuid/uuid.dart';

import '../../../domain/entities/message.dart';
import '../../../domain/entities/user.dart';

// Provider for messages
final mockMessagesProvider = StateNotifierProvider.family<MessagesNotifier, List<Message>, String>(
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
      receiverId: receiverId,
      content: 'Hello, how are you?',
      type: MessageType.text,
      status: MessageStatus.read,
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    Message(
      id: '2',
      senderId: receiverId,
      receiverId: 'current-user',
      content: 'I\'m good, thanks! How about you?',
      type: MessageType.text,
      status: MessageStatus.read,
      timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
    ),
    Message(
      id: '3',
      senderId: 'current-user',
      receiverId: receiverId,
      content: 'I\'m doing well, thanks!',
      type: MessageType.text,
      status: MessageStatus.delivered,
      timestamp: DateTime.now().subtract(const Duration(minutes: 20)),
    ),
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
    );
    
    state = [...state, newMessage];
    
    // Simulate automatic reply after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      final replyMessage = Message(
        id: _uuid.v4(),
        senderId: receiverId,
        receiverId: 'current-user',
        content: 'This is an automatic reply!',
        type: MessageType.text,
        status: MessageStatus.sent,
        timestamp: DateTime.now(),
      );
      
      state = [...state, replyMessage];
    });
  }
}

class ChatPage extends ConsumerStatefulWidget {
  final User receiver;

  const ChatPage({
    Key? key,
    required this.receiver,
  }) : super(key: key);

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showEmoji = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      ref.read(mockMessagesProvider(widget.receiver.id).notifier).sendMessage(
        text,
        MessageType.text,
      );
      _messageController.clear();
      
      // Scroll to bottom after sending message
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(mockMessagesProvider(widget.receiver.id));
    
    // Scroll to bottom when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (messages.isNotEmpty) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: widget.receiver.isOnline ? Colors.green.shade100 : Colors.grey.shade200,
              child: Text(
                widget.receiver.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.receiver.isOnline ? Colors.green.shade800 : Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.receiver.name,
                  style: const TextStyle(fontSize: 16),
                ),
                Text(
                  widget.receiver.isOnline
                      ? 'Online'
                      : widget.receiver.lastSeen != null
                          ? 'Last seen ${timeago.format(widget.receiver.lastSeen!)}'
                          : 'Offline',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.receiver.isOnline ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Calling feature coming soon')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('More options coming soon')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: messages.isEmpty
                ? const Center(child: Text('No messages yet'))
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = message.senderId == 'current-user';
                      return _buildMessageItem(message, isMe);
                    },
                  ),
          ),
          
          // Input area
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _showEmoji ? Icons.keyboard : Icons.emoji_emotions_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _showEmoji = !_showEmoji;
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Type a message',
                      border: InputBorder.none,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Attachment feature coming soon')),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
          
          // Emoji picker (simplified for demo)
          if (_showEmoji)
            Container(
              height: 250,
              color: Colors.white,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 8,
                ),
                itemCount: 24,
                itemBuilder: (context, index) {
                  // Just show some basic emoji
                  final emojis = ['😀', '😂', '😍', '🥰', '😊', '👍', '❤️', '🔥', 
                                  '🤔', '😎', '🙏', '🤝', '👏', '🎉', '🎂', '🎁', 
                                  '🌹', '🌞', '⭐', '✨', '🚀', '🌈', '☕', '🍕'];
                  
                  return GestureDetector(
                    onTap: () {
                      _messageController.text += emojis[index];
                    },
                    child: Center(
                      child: Text(
                        emojis[index],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Message message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: widget.receiver.isOnline ? Colors.green.shade100 : Colors.grey.shade200,
              child: Text(
                widget.receiver.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.receiver.isOnline ? Colors.green.shade800 : Colors.grey.shade600,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: isMe ? Theme.of(context).colorScheme.primary : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: TextStyle(
                    color: isMe ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      timeago.format(message.timestamp, locale: 'en_short'),
                      style: TextStyle(
                        fontSize: 10,
                        color: isMe ? Colors.white.withOpacity(0.7) : Colors.black54,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.status == MessageStatus.sent
                            ? Icons.check
                            : message.status == MessageStatus.delivered
                                ? Icons.check_circle_outline
                                : Icons.check_circle,
                        size: 12,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 