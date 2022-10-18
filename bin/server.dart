import 'package:sample_auth_server/clients/firebase_auth_client.dart';
import 'package:sample_auth_server/helpers.dart';

main(List<String> arguments) async {
  if (isInDebugMode) {
    print('Running in debug mode');
  } else {
    print('Running in release mode');
  }

  try {
    await FirebaseAuthClient.run();
  } finally {
    FirebaseAuthClient.close();
  }
}
