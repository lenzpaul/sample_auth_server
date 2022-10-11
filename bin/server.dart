import 'package:sample_auth_server/clients/firebase_auth_client.dart';
import 'package:sample_auth_server/helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

main() async {
  await FirebaseAuthClient.instance.initClient();

  try {
    final Router router = FirebaseAuthClient.instance.router;
    await serveHandler(logRequests().addHandler(router));
  } finally {
    FirebaseAuthClient.instance.close();
  }
}
