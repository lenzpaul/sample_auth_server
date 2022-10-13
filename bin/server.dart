import 'package:sample_auth_server/clients/firebase_auth_client.dart';

main() async {
  try {
    await FirebaseAuthClient.run();
  } finally {
    FirebaseAuthClient.close();
  }
}
