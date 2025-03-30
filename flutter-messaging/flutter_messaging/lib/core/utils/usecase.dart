import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import 'failure.dart';

// Interface for all Use Cases
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

// No parameters for use cases that don't need any
class NoParams extends Equatable {
  @override
  List<Object> get props => [];
} 