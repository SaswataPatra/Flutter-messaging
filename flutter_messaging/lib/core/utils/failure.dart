import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  final int code;

  const Failure({
    required this.message,
    this.code = 0,
  });

  @override
  List<Object> get props => [message, code];
}

// Server failures
class ServerFailure extends Failure {
  const ServerFailure({required String message, int code = 500})
      : super(message: message, code: code);
}

// Connection failures
class ConnectionFailure extends Failure {
  const ConnectionFailure({required String message})
      : super(message: message, code: -1);
}

// Cache failures
class CacheFailure extends Failure {
  const CacheFailure({required String message})
      : super(message: message, code: -2);
}

// Auth failures
class AuthFailure extends Failure {
  const AuthFailure({required String message, int code = 401})
      : super(message: message, code: code);
} 