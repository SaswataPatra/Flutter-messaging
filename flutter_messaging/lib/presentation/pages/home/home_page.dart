import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../domain/entities/user.dart';
import '../auth/auth_page.dart';
import '../chat/chat_page.dart';
import '../profile/profile_page.dart';

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
    User(
      id: '2',
      name: 'Bob Johnson',
      email: 'bob@example.com',
      photoUrl: 'https://randomuser.me/api/portraits/men/22.jpg',
      status: 'Busy',
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    User(
      id: '3',
      name: 'Carol Wilson',
      email: 'carol@example.com',
      photoUrl: 'https://randomuser.me/api/portraits/women/67.jpg',
      status: 'At work',
      isOnline: true,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
  ];
});

// Provider for sign out
final signOutProvider = Provider<bool>((ref) => false);

class HomePage extends ConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(mockUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        actions: [
          // Profile button
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () => _navigateToProfile(context, ref),
          ),
          // Sign out button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context, ref),
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          return _buildChatListItem(context, user);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToNewChat(context),
        child: const Icon(Icons.chat),
      ),
    );
  }

  Widget _buildChatListItem(BuildContext context, User user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: user.isOnline
            ? Colors.green.shade200
            : Colors.grey.shade300,
        child: Text(
          user.name.substring(0, 1).toUpperCase(),
          style: TextStyle(
            color: user.isOnline
                ? Colors.green.shade800
                : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        user.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Row(
        children: [
          // Online status indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: user.isOnline ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          // Last seen text
          Text(
            user.isOnline
                ? 'Online'
                : user.lastSeen != null
                    ? 'Last seen ${timeago.format(user.lastSeen!)}'
                    : 'Offline',
            style: TextStyle(
              color: user.isOnline ? Colors.green : Colors.grey,
            ),
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _navigateToChat(context, user),
    );
  }

  void _navigateToChat(BuildContext context, User user) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatPage(receiver: user),
      ),
    );
  }

  void _navigateToNewChat(BuildContext context) {
    // This would typically navigate to a contacts page to start a new chat
    // For now, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('New chat feature coming soon!'),
      ),
    );
  }

  void _navigateToProfile(BuildContext context, WidgetRef ref) {
    final currentUser = User(
      id: 'current-user',
      name: 'Current User',
      email: 'me@example.com',
      status: 'Available for chat',
      isOnline: true,
      lastSeen: DateTime.now(),
    );
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfilePage(user: currentUser),
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true) {
      // For web demo, just navigate back to auth page
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
    }
  }
} 