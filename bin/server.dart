import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:sample_auth_server/firebase_auth_client.dart';
import 'package:sample_auth_server/helpers.dart';

/// See:
/// https://firebase.google.com/docs/reference/rest/auth#section-sign-in-email-password

Future main() async {
  final projectId = await currentProjectId();
  print('Current GCP project id: $projectId');

  final authClient = await clientViaApplicationDefaultCredentials(
    scopes: [FirestoreApi.datastoreScope],
  );

  try {
    // await serveHandler(FirebaseAuthClient().router);
    await serveHandler(FirebaseAuthClient().routerWithLogging);
  } finally {
    authClient.close();
  }
}
