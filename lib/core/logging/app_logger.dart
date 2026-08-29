import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Thin wrapper around `dart:developer`'s log so call sites don't depend on
/// a specific logging package, and so log level/tagging stays consistent.
///
/// Also mirrors to [debugPrint]: `dart:developer.log` only surfaces in a
/// connected DevTools session, not in plain `flutter run`/logcat output,
/// which is where this app is actually debugged day-to-day.
class AppLogger {
  const AppLogger(this._tag);

  final String _tag;

  void debug(String message) => _log(message, level: 500);

  void info(String message) => _log(message, level: 800);

  void warning(String message, [Object? error, StackTrace? stackTrace]) =>
      _log(message, level: 900, error: error, stackTrace: stackTrace);

  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _log(message, level: 1000, error: error, stackTrace: stackTrace);

  void _log(
    String message, {
    required int level,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: _tag,
      level: level,
      error: error,
      stackTrace: stackTrace,
      time: DateTime.now(),
    );
    debugPrint('[$_tag] $message${error != null ? ' — $error' : ''}');
  }
}
