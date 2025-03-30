import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String name;
  final String? email;
  final String? photoUrl;
  final String? status;
  final bool isOnline;
  final DateTime? lastSeen;

  const User({
    required this.id,
    required this.name,
    this.email,
    this.photoUrl,
    this.status,
    required this.isOnline,
    this.lastSeen,
  });

  @override
  List<Object?> get props => [id, name, email, photoUrl, status, isOnline, lastSeen];
} 