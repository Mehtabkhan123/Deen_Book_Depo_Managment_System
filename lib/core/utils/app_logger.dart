import 'dart:developer' as developer;

enum LogLevel { debug, info, success, warning, error }

/// Production-ready logger for the offline wholesale application
class AppLogger {
  AppLogger._();

  static const String _name = 'WholesaleBooks';

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.debug, message, error, stackTrace);
  }

  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }

  static void success(String message) {
    _log(LogLevel.success, message);
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    final prefix = _getPrefix(level);

    final formattedMessage = '[$timestamp][$prefix] $message';

    developer.log(
      formattedMessage,
      name: _name,
      time: DateTime.now(),
      level: _levelToInt(level),
      error: error,
      stackTrace: stackTrace,
    );

    // Also output to console for Windows desktop debugging
    // ignore: avoid_print
    print(formattedMessage);
    if (error != null) {
      // ignore: avoid_print
      print('  Error details: $error');
    }
    if (stackTrace != null) {
      // ignore: avoid_print
      print('  StackTrace:\n$stackTrace');
    }
  }

  static String _getPrefix(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 'DEBUG';
      case LogLevel.info:
        return 'INFO';
      case LogLevel.success:
        return 'SUCCESS';
      case LogLevel.warning:
        return 'WARN';
      case LogLevel.error:
        return 'ERROR';
    }
  }

  static int _levelToInt(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return 500;
      case LogLevel.info:
      case LogLevel.success:
        return 800;
      case LogLevel.warning:
        return 900;
      case LogLevel.error:
        return 1000;
    }
  }
}
