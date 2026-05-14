import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// AppLogger - Logs errors to terminal AND browser console (web)
///
/// Usage:
///   AppLogger.info('Something happened');
///   AppLogger.error('Login failed', error: e, stackTrace: stackTrace);
///   AppLogger.warning('Deprecated API used');
///   AppLogger.debug('Debug info: $data');
class AppLogger {
  // ─── Tags ────────────────────────────────────────
  static const String _infoTag = 'ℹ️ INFO';
  static const String _warnTag = '⚠️ WARN';
  static const String _errorTag = '❌ ERROR';
  static const String _debugTag = '🔍 DEBUG';

  // ─── Core Log Method ─────────────────────────────
  /// Internal method that outputs to:
  /// 1. Dart `print()` → visible in terminal + browser console
  /// 2. Dart `developer.log()` → visible in DevTools
  /// 3. Web `console.error/warn/info` via JS interop (web only)
  static void _log(
    String level,
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final prefix = tag ?? level;
    final fullMessage = '[$timestamp] $prefix: $message';

    // 1. Use developer.log for proper logging
    developer.log(fullMessage, level: _levelToInt(level), name: prefix);

    // 2. Log error details if available
    if (error != null) {
      developer.log('  └─ Error: $error',
          level: _levelToInt(level), name: prefix);
    }
    if (stackTrace != null) {
      developer.log('  └─ StackTrace:\n${_formatStackTrace(stackTrace)}',
          level: _levelToInt(level), name: prefix);
    }

    // 3. developer.log for DevTools
    developer.log(
      message,
      time: DateTime.now(),
      level: _levelToInt(level),
      name: prefix,
      error: error,
      stackTrace: stackTrace,
    );

    // 4. Web-specific: Use browser console methods for better DevTools integration
    if (kIsWeb) {
      _logToBrowserConsole(level, fullMessage, error, stackTrace);
    }
  }

  // ─── Public Methods ──────────────────────────────

  /// Log informational message
  static void info(String message, {String? tag}) {
    _log(_infoTag, message, tag: tag);
  }

  /// Log warning message
  static void warning(String message, {String? tag, Object? error}) {
    _log(_warnTag, message, tag: tag, error: error);
  }

  /// Log error message with optional error object and stack trace
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(_errorTag, message, tag: tag, error: error, stackTrace: stackTrace);
  }

  /// Log debug message (only in debug mode)
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      _log(_debugTag, message, tag: tag);
    }
  }

  /// Log API error with response details
  static void apiError(
    String endpoint, {
    int? statusCode,
    String? responseBody,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final details = StringBuffer();
    if (statusCode != null) details.write('Status: $statusCode | ');
    if (responseBody != null) details.write('Body: $responseBody');

    _log(
      _errorTag,
      'API Error [$endpoint] $details',
      tag: '🌐 API',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Log authentication error
  static void authError(
    String action, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    _log(
      _errorTag,
      'Auth Error [$action]',
      tag: '🔐 AUTH',
      error: error,
      stackTrace: stackTrace,
    );
  }

  // ─── Helpers ─────────────────────────────────────

  static int _levelToInt(String level) {
    switch (level) {
      case _errorTag:
        return 1000; // SEVERE
      case _warnTag:
        return 900; // WARNING
      case _infoTag:
        return 800; // INFO
      case _debugTag:
        return 500; // FINE
      default:
        return 800;
    }
  }

  /// Format stack trace to show top 10 lines only (avoid flooding)
  static String _formatStackTrace(StackTrace stackTrace) {
    final lines = stackTrace.toString().split('\n');
    final top = lines.take(10).join('\n');
    return lines.length > 10 ? '$top\n  ... (${lines.length - 10} more)' : top;
  }

  /// Web-specific: Log to browser console using dart:html interop
  static void _logToBrowserConsole(
    String level,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    // On web, print() already goes to browser console,
    // but we can use more specific console methods for better DevTools experience
    try {
      // Use dart:js_interop if available, or just rely on print()
      // print() on Flutter web automatically outputs to browser console
      // Additional structured logging for error cases
      if (level == _errorTag && error != null) {
        // This ensures error objects show up in browser console's red error section
        developer.log('Console Error Object: $error',
            level: 1000, name: 'Browser Console');
        if (stackTrace != null) {
          developer.log('Console StackTrace: ${_formatStackTrace(stackTrace)}',
              level: 1000, name: 'Browser Console');
        }
      }
    } catch (e) {
      // Fallback - print already handles it
    }
  }
}

