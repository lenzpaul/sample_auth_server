import 'package:sample_auth_server/clients/firebase_auth_client.dart';
import 'package:sample_auth_server/helpers.dart';
import 'package:sample_auth_server/logger.dart';

main(List<String> arguments) async {
  // Initializing logging
  _setupLogging();

  try {
    await FirebaseClient.run();
  } finally {
    FirebaseClient.close();
  }
}

void _setupLogging() {
  ServerLogger.logLevel = ServerLogLevel.verbose;

  ServerLogger.logFilePath = 'logs/server.log';

  ServerLogger.maxLogFileSize = 1000000; // 1MB

  // Output destination for log messages. stdout is the default.
  ServerLogger.logOutputs = [
    ServerLogOutput.file,
    // if debugging in vscode this will output the log messages to the debug
    // console.
    isInDebugMode
        ? ServerLogOutput.editorConsole
        : ServerLogOutput.stdout, // useful for remote debugging
  ];

  if (isInDebugMode) {
    ServerLogger.log('Running in debug mode', level: ServerLogLevel.debug);
  } else {
    ServerLogger.log('Running in release mode', level: ServerLogLevel.debug);
  }
}
