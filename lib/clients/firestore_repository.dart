// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:googleapis/firestore/v1.dart';
import 'package:sample_auth_server/clients/firebase_auth_client.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:sample_auth_server/helpers.dart';
import 'package:http/http.dart' as http;

/// Wrapper for the Firestore API.
class FirebaseApiRepository {
  FirebaseApiRepository({required this.firebaseAuthClient})
      : _api = FirestoreApi(firebaseAuthClient.authenticatedClient),
        projectId = firebaseAuthClient.projectId;

  final String projectId;

  final FirebaseAuthClient firebaseAuthClient;
  final FirestoreApi _api;

  Future<shelf.Response> incrementHandler(shelf.Request request) async {
    var projectId = FirebaseAuthClient.instance.projectId;

    final result = await _api.projects.databases.documents.commit(
      _incrementRequest(FirebaseAuthClient.instance.projectId),
      'projects/$projectId/databases/(default)',
    );

    return shelf.Response.ok(
      JsonUtf8Encoder(' ').convert(result),
      headers: {
        'content-type': 'application/json',
      },
    );
  }

  // get issues endpoint
  Future<shelf.Response> getIssuesHandler(shelf.Request request) async {
    final result = await _api.projects.databases.documents.list(
      'projects/$projectId/databases/(default)/documents',
      'issues',
    );

    return shelf.Response.ok(
      JsonUtf8Encoder(' ').convert(result),
      headers: {
        'content-type': 'application/json',
      },
    );
  }

  /// WIP
  // Future firestoreQuery() async {
  //   try {
  //     Future<shelf.Response> incrementHandler(shelf.Request request) async {
  //       final result = await _api.projects.databases.documents.commit(
  //         _incrementRequest(projectId),
  //         'projects/$projectId/databases/(default)',
  //       );

  //       return shelf.Response.ok(
  //         JsonUtf8Encoder(' ').convert(result),
  //         headers: {
  //           'content-type': 'application/json',
  //         },
  //       );
  //     }

  //     final router = shelf_router.Router()..get('/', incrementHandler);

  //     await serveHandler(router);
  //   } finally {
  //     firebaseAuthClient.close();
  //   }
  // }

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
}
