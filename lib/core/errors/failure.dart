import 'package:equatable/equatable.dart';

/// Represents a failure in the application.
abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

/// Represents a failure from a remote server.
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// Represents a failure from the local cache.
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

/// Represents a failure related to authentication.
class AuthFailure extends Failure {
  const AuthFailure(super.message);
}
