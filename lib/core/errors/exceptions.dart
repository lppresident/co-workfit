/// Represents an exception from a remote server.
class ServerException implements Exception {
  final String message;

  ServerException(this.message);

  @override
  String toString() => 'ServerException: $message';
}

/// Represents an exception from the local cache.
class CacheException implements Exception {
  final String message;

  CacheException(this.message);

  @override
  String toString() => 'CacheException: $message';
}

/// Represents an exception related to authentication.
class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => 'AuthException: $message';
}
