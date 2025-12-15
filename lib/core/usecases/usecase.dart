import 'package:dartz/dartz.dart';
import 'package:co_workfit/core/error/failures.dart';

/// Base class for all use cases
///
/// [Type] - The type of data returned on success
/// [Params] - The parameters required for the use case
abstract class UseCase<Type, Params> {
  Future<Either<Failure, Type>> call(Params params);
}

/// Use case that doesn't require parameters
abstract class NoParamsUseCase<Type> {
  Future<Either<Failure, Type>> call();
}

/// Marker class for use cases that don't need parameters
class NoParams {
  const NoParams();
}
