// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:sample_auth_server/helpers.dart';
import 'package:shelf_router/shelf_router.dart';

/// See:
/// https://firebase.google.com/docs/reference/rest/auth#section-sign-in-email-password

Future main() async {
  final projectId = await currentProjectId();
  print('Current GCP project id: $projectId');

  final authClient = await clientViaApplicationDefaultCredentials(
    scopes: [FirestoreApi.datastoreScope],
  );

  try {
    var router = _initRouter();
    await serveHandler(router);
  } finally {
    authClient.close();
  }
}

Router _initRouter() {
  final router = Router();
  router.get('/login', FirebaseAuthClient.loginWithEmailAndPasswordHandler);
  router.get('/loginAnonymously', FirebaseAuthClient.loginAnonymouslyHandler);
  // router.get('/logout', _firebaseLogoutHandler);

  return router;
}
