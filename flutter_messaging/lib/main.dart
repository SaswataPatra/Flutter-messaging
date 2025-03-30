import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';

import 'presentation/pages/auth/auth_page.dart';
import 'domain/repositories/auth_repository.dart';
import 'domain/repositories/message_repository.dart';
import 'domain/repositories/user_repository.dart';
import 'data/mocks/mock_repositories.dart';

// Global instance of GetIt service locator
final sl = GetIt.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize dependencies with mock repositories for all platforms
  await initializeDependencies();
  
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// Initialize all dependencies with mock implementations
Future<void> initializeDependencies() async {
  try {
    // Register repositories with mock implementations for testing
    sl.registerLazySingleton<AuthRepository>(() => MockAuthRepository());
    sl.registerLazySingleton<MessageRepository>(() => MockMessageRepository());
    sl.registerLazySingleton<UserRepository>(() => MockUserRepository());
    
    debugPrint('Application initialized with mock repositories');
  } catch (e) {
    debugPrint('Error initializing dependencies: $e');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
      // For simplicity in web demo, we'll start directly at the AuthPage
      home: const AuthPage(),
    );
  }
}
