import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../domain/entities/user.dart';

// Provider for profile editing state
final profileEditingProvider = StateProvider<bool>((ref) => false);

// Provider for profile data
final profileDataProvider = StateProvider.family<User, User>((ref, initialUser) => initialUser);

class ProfilePage extends ConsumerStatefulWidget {
  final User user;

  const ProfilePage({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _statusController;
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _statusController = TextEditingController(text: widget.user.status ?? 'Hey there! I am using Flutter Messaging.');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  void _toggleEditMode() {
    final isEditing = ref.read(profileEditingProvider);
    ref.read(profileEditingProvider.notifier).state = !isEditing;
    
    if (isEditing) {
      // If we're exiting edit mode, discard changes
      _nameController.text = widget.user.name;
      _statusController.text = widget.user.status ?? 'Hey there! I am using Flutter Messaging.';
    }
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isLoading = true;
    });
    
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));
    
    // Update the user data
    final updatedUser = User(
      id: widget.user.id,
      name: _nameController.text,
      email: widget.user.email,
      photoUrl: widget.user.photoUrl,
      status: _statusController.text,
      isOnline: widget.user.isOnline,
      lastSeen: widget.user.lastSeen,
    );
    
    ref.read(profileDataProvider(widget.user).notifier).state = updatedUser;
    ref.read(profileEditingProvider.notifier).state = false;
    
    setState(() {
      _isLoading = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = ref.watch(profileEditingProvider);
    final userData = ref.watch(profileDataProvider(widget.user));
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          isEditing
              ? IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _isLoading ? null : _saveChanges,
                )
              : IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _toggleEditMode,
                ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Profile picture
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey.shade200,
                          backgroundImage: userData.photoUrl != null
                              ? NetworkImage(userData.photoUrl!)
                              : null,
                          child: userData.photoUrl == null
                              ? Text(
                                  userData.name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade800,
                                  ),
                                )
                              : null,
                        ),
                        if (isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.camera_alt, color: Colors.white),
                                onPressed: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Change profile picture feature coming soon'),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Online status indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: userData.isOnline ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        userData.isOnline
                            ? 'Online'
                            : userData.lastSeen != null
                                ? 'Last seen ${timeago.format(userData.lastSeen!)}'
                                : 'Offline',
                        style: TextStyle(
                          color: userData.isOnline ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Name field
                  isEditing
                      ? TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Name',
                            border: OutlineInputBorder(),
                          ),
                        )
                      : ListTile(
                          title: const Text(
                            'Name',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          subtitle: Text(
                            userData.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                  const SizedBox(height: 16),
                  
                  // Email field (read-only)
                  ListTile(
                    title: const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    subtitle: Text(
                      userData.email ?? 'No email provided',
                      style: const TextStyle(
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Status field
                  isEditing
                      ? TextField(
                          controller: _statusController,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          maxLength: 50,
                        )
                      : ListTile(
                          title: const Text(
                            'Status',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          subtitle: Text(
                            userData.status ?? 'Hey there! I am using Flutter Messaging.',
                            style: const TextStyle(
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                  const SizedBox(height: 32),
                  
                  // Action buttons
                  if (!isEditing) ...[
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Block user feature coming soon'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.block),
                      label: const Text('Block User'),
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Delete chat history feature coming soon'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete Chat History'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
} 