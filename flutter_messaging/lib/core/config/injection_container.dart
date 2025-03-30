import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../../data/datasources/auth_data_source.dart';
import '../../data/datasources/message_data_source.dart';
import '../../data/datasources/user_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/message_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/message_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../domain/usecases/auth/sign_in_with_email_usecase.dart';
import '../../domain/usecases/auth/sign_out_usecase.dart';
import '../../domain/usecases/auth/sign_up_with_email_usecase.dart';
import '../../domain/usecases/message/get_messages_usecase.dart';
import '../../domain/usecases/message/send_message_usecase.dart';
import '../../domain/usecases/user/get_user_profile_usecase.dart';
import '../../domain/usecases/user/update_user_status_usecase.dart';
import '../network/network_info.dart';
import '../../data/mocks/mock_repositories.dart';

// Global instance of GetIt service locator
final sl = GetIt.instance;

// Initialize all dependencies
Future<void> init() async {
  try {
    // External dependencies
    final sharedPreferences = await SharedPreferences.getInstance();
    sl.registerSingleton<SharedPreferences>(sharedPreferences);
    
    sl.registerLazySingleton<InternetConnectionChecker>(() => InternetConnectionChecker());
    
    // Core
    sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(sl()));
    
    if (kIsWeb) {
      // Register mock implementations for web testing
      _registerMocks();
    } else {
      // Register real Firebase implementations
      _registerFirebaseImplementations();
    }
    
    // Use cases
    // Auth
    sl.registerLazySingleton(() => SignInWithEmailUseCase(sl()));
    sl.registerLazySingleton(() => SignUpWithEmailUseCase(sl()));
    sl.registerLazySingleton(() => SignOutUseCase(sl()));
    
    // Messages
    sl.registerLazySingleton(() => GetMessagesUseCase(sl()));
    sl.registerLazySingleton(() => SendMessageUseCase(sl()));
    
    // User
    sl.registerLazySingleton(() => GetUserProfileUseCase(sl()));
    sl.registerLazySingleton(() => UpdateUserStatusUseCase(sl()));
  } catch (e) {
    debugPrint('Error initializing dependencies: $e');
    // Register mock implementations if Firebase initialization fails
    _registerMocks();
  }
}

void _registerFirebaseImplementations() {
  // Firebase instances
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  sl.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  
  // Data sources
  sl.registerLazySingleton<AuthDataSource>(
    () => AuthDataSourceImpl(firebaseAuth: sl()),
  );
  sl.registerLazySingleton<MessageDataSource>(
    () => MessageDataSourceImpl(firestore: sl(), firebaseAuth: sl()),
  );
  sl.registerLazySingleton<UserDataSource>(
    () => UserDataSourceImpl(firestore: sl(), firebaseAuth: sl()),
  );
  
  // Repositories
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(authDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<MessageRepository>(
    () => MessageRepositoryImpl(messageDataSource: sl(), networkInfo: sl()),
  );
  sl.registerLazySingleton<UserRepository>(
    () => UserRepositoryImpl(userDataSource: sl(), networkInfo: sl()),
  );
}

void _registerMocks() {
  // Repositories with mock implementations for web testing
  sl.registerLazySingleton<AuthRepository>(() => MockAuthRepository());
  sl.registerLazySingleton<MessageRepository>(() => MockMessageRepository());
  sl.registerLazySingleton<UserRepository>(() => MockUserRepository());
} 