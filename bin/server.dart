import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:sample_auth_server/clients/firebase_auth_client.dart';
import 'package:sample_auth_server/helpers.dart';
import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// See:
/// https://firebase.google.com/docs/reference/rest/auth#section-sign-in-email-password

main() async {
  await FirebaseAuthClient().initClient();

  Future<Response> incrementHandler(Request request) async {
    final result = await api.projects.databases.documents.commit(
      _incrementRequest(projectId),
      'projects/$projectId/databases/(default)',
    );

    return Response.ok(
      JsonUtf8Encoder(' ').convert(result),
      headers: {
        'content-type': 'application/json',
      },
    );
  }

  // get issues endpoint
  Future<Response> getIssuesHandler(Request request) async {
    final result = await api.projects.databases.documents.list(
      'projects/$projectId/databases/(default)/documents',
      'issues',
    );

    return Response.ok(
      JsonUtf8Encoder(' ').convert(result),
      headers: {
        'content-type': 'application/json',
      },
    );
  }

  try {
    // await serveHandler(FirebaseAuthClient().router);
    final Router router = FirebaseAuthClient().router
      ..get('/db', incrementHandler)
      ..get('/issues', getIssuesHandler);
    // await serveHandler(router);
    await serveHandler(logRequests().addHandler(router));

    // await serveHandler(FirebaseAuthClient().routerWithLogging);
    // .addRoute('GET', '/increment', incrementHandler));

  } finally {
    authClient.close();
  }
}

CommitRequest _incrementRequest(String projectId) => CommitRequest(
      writes: [
        Write(
          transform: DocumentTransform(
            document:
                'projects/$projectId/databases/(default)/documents/settings/count',
            fieldTransforms: [
              FieldTransform(
                fieldPath: 'count',
                increment: Value(integerValue: '1'),
              )
            ],
          ),
        ),
      ],
    );
