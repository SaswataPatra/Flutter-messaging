import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../main.dart'; // For the sl global instance
import '../../../domain/repositories/auth_repository.dart';
import '../auth/auth_page.dart';
import '../home/home_page.dart';

final authStateProvider = FutureProvider.autoDispose<bool>((ref) async {
  final authRepository = sl<AuthRepository>();
  return await authRepository.isSignedIn();
});

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _isDisposed = false;
  
  @override
  void initState() {
    super.initState();
    
    // Trigger the auth check directly when the widget is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        ref.read(authStateProvider);
      }
    });
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    
    // Handle auth state changes
    authState.whenData((isSignedIn) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isDisposed && mounted) {
          if (isSignedIn) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const AuthPage()),
            );
          }
        }
      });
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            // App name
            Text(
              'Flutter Messaging',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 48),
            // Loading indicator
            authState.isLoading
              ? const CircularProgressIndicator()
              : authState.hasError 
                ? Text('Error: ${authState.error}')
                : const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
} 