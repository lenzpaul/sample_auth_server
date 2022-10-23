import 'dart:io';

import 'package:logger/logger.dart';
import 'package:sample_auth_server/helpers.dart';

/// [Level]s to control logging output. Logging can be enabled to include all
/// levels above certain [Level].
///
/// An implementation of the [Level] enum from the `package:logger` package.
enum ServerLogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  wtf,
  nothing,
}

/// Where the log messages are sent.
enum ServerLogOutput {
  editorConsole,
  stdout,
  file,
}

extension ServerLogLevelExtension on ServerLogLevel {
  /// Returns the [Level] equivalent of the [ServerLogLevel].
  Level toLoggerLevel() {
    switch (this) {
      case ServerLogLevel.verbose:
        return Level.verbose;
      case ServerLogLevel.debug:
        return Level.debug;
      case ServerLogLevel.info:
        return Level.info;
      case ServerLogLevel.warning:
        return Level.warning;
      case ServerLogLevel.error:
        return Level.error;
      case ServerLogLevel.wtf:
        return Level.wtf;
      case ServerLogLevel.nothing:
        return Level.nothing;
      default:
        return Level.nothing;
    }
  }
}

class ServerLogger {
  ServerLogger._();
  static final instance = ServerLogger._();

  /// The [Logger] instance used to log messages to editor, console, or file.
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 8,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
      noBoxingByDefault: true,
    ),
  );

  /// Current [ServerLogLevel] of the logger.
  ServerLogLevel _serverLogLevel = ServerLogLevel.verbose;

  ServerLogLevel get serverLogLevel => _serverLogLevel;

  set serverLogLevel(ServerLogLevel value) {
    _serverLogLevel = serverLogLevel;
    Logger.level = serverLogLevel.toLoggerLevel();
  }

  /// The path to which the log file should be written.
  String logFilePath = 'logs/server.log';
  static set logOutputs(List<ServerLogOutput> outputs) =>
      instance._logOutputs = outputs;

  /// Current [ServerLogOututs] of the logger.
  List<ServerLogOutput> _logOutputs = [
    ServerLogOutput.stdout,
    // ServerLogOutput.file,
    // ServerLogOutput.editorConsole,
  ];

  /// The log number of the current log.
  static int _logCount = 0;

  /// The output of the logger.
  // String _formatOutput(String message) {
  //   return '#${_logCount++}: $message';
  // }

  /// Emit a log event.
  ///
  /// This function was designed to map closely to the logging information
  /// collected by `package:logging`.
  ///
  /// - [message] is the log message
  /// - [time] (optional) is the timestamp
  /// - [sequenceNumber] (optional) is a monotonically increasing sequence number
  /// - [level] (optional) is the severity level (a value between 0 and 2000); see
  ///   the `package:logging` `Level` class for an overview of the possible values
  /// - [name] (optional) is the name of the source of the log message
  /// - [zone] (optional) the zone where the log was emitted
  /// - [error] (optional) an error object associated with this log event
  /// - [stackTrace] (optional) a stack trace associated with this log event
  static void log(
    String message, {
    DateTime? time,
    int? sequenceNumber,
    ServerLogLevel level = ServerLogLevel.info,
    String name = '',
    // Zone? zone,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (level.index >= instance._serverLogLevel.index) {
      final logMessage = '#${_logCount++}: $message';

      for (var logOutput in instance._logOutputs) {
        switch (logOutput) {
          case ServerLogOutput.editorConsole:
            if (level.index >= instance._serverLogLevel.index) {
              _logger.log(
                level.toLoggerLevel(),
                logMessage,
                error,
                stackTrace,
              );
            }
            break;

          case ServerLogOutput.stdout:
            if (level.index >= instance._serverLogLevel.index) {
              print(logMessage);
            }
            break;

          case ServerLogOutput.file:
            // Output to file
            writeStringToFile(
              logMessage,
              '${Directory.current.path}/${instance.logFilePath}',
            );

            break;
        }
      }
    }
  }
}
