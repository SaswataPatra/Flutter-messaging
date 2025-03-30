import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

// This class handles Firebase initialization and configuration
class FirebaseConfig {
  // Private constructor to prevent direct instantiation
  FirebaseConfig._();
  
  static Future<void> initialize() async {
    try {
      if (kIsWeb) {
        // For web testing without proper Firebase setup, we'll skip initialization
        debugPrint('Running on web platform - skipping Firebase initialization for testing');
        return;
      }
      
      await Firebase.initializeApp(
        // For web, the options are provided automatically
        // For Android and iOS, Firebase configuration is done through firebase_options.dart
        // which will be generated when running flutterfire configure
        // options: DefaultFirebaseOptions.currentPlatform,
      );
      
      // Log successful initialization
      debugPrint('Firebase initialized successfully');
    } catch (e) {
      // Log any initialization errors
      debugPrint('Error initializing Firebase: $e');
      rethrow;
    }
  }
} 