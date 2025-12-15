import 'package:flutter/foundation.dart';

/// Centralized logging utility for the application
///
/// Use this instead of print() statements for better control and production safety
class AppLogger {
  static const String _prefix = '[CoWorkFit]';

  /// Log debug information (only in debug mode)
  static void debug(String tag, String message) {
    if (kDebugMode) {
      debugPrint('$_prefix [$tag] $message');
    }
  }

  /// Log info messages (only in debug mode)
  static void info(String tag, String message) {
    if (kDebugMode) {
      debugPrint('$_prefix [$tag] ℹ️ $message');
    }
  }

  /// Log warning messages (only in debug mode)
  static void warning(String tag, String message) {
    if (kDebugMode) {
      debugPrint('$_prefix [$tag] ⚠️ $message');
    }
  }

  /// Log error messages (shown in both debug and release modes)
  static void error(String tag, String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('$_prefix [$tag] ❌ $message');
    if (error != null) {
      debugPrint('$_prefix [$tag] Error details: $error');
    }
    if (stackTrace != null && kDebugMode) {
      debugPrint('$_prefix [$tag] Stack trace: $stackTrace');
    }
  }

  /// Log performance metrics (only in debug mode)
  static void performance(String tag, String operation, int durationMs) {
    if (kDebugMode) {
      debugPrint('$_prefix [$tag] ⏱️ $operation completed in ${durationMs}ms');
    }
  }
}
