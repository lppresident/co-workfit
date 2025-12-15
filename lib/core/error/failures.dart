import 'package:equatable/equatable.dart';

/// Base class for all failures in the application
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Server/Network related failures
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Cache related failures
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Permission related failures
class PermissionFailure extends Failure {
  const PermissionFailure(super.message);
}

/// Authentication related failures
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}

/// Validation related failures
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// Platform specific failures
class PlatformFailure extends Failure {
  const PlatformFailure(super.message);
}

/// Generic failure for unexpected errors
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}

/// Extensions for converting exceptions to failures
extension FailureExtensions on Exception {
  Failure toFailure() {
    final errorMessage = toString();

    if (errorMessage.contains('network') || errorMessage.contains('connection')) {
      return ServerFailure(errorMessage);
    }

    if (errorMessage.contains('permission') || errorMessage.contains('denied')) {
      return PermissionFailure(errorMessage);
    }

    if (errorMessage.contains('auth') || errorMessage.contains('unauthorized')) {
      return AuthFailure(errorMessage);
    }

    return UnexpectedFailure(errorMessage);
  }
}
