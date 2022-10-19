// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// import 'dart:convert';

// import 'package:googleapis/firestore/v1.dart';
// import 'package:sample_auth_server/clients/firebase_auth_client.dart';
// import 'package:shelf/shelf.dart' as shelf;
// import 'package:shelf_router/shelf_router.dart' as shelf_router;
// import 'package:sample_auth_server/helpers.dart';
// import 'package:http/http.dart' as http;

part of 'firebase_auth_client.dart';

/// Wrapper for the Firestore API.
class FirebaseApiRepository {
  static get _firestoreBaseCollectionPath {
    final projectId = FirebaseAuthClient.instance.projectId;

    return 'projects/$projectId/databases/(default)/documents';
  }

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
    List<Issue> issues = [];

    // Get the issues from Firestore.
    final ListDocumentsResponse result =
        await _api.projects.databases.documents.list(
      _firestoreBaseCollectionPath,
      'issues',
    );

    // Convert the Firestore documents to Issues.
    for (Document doc in result.documents!) {
      // issues.add(Issue.fromMap(doc.fields!));

      if (doc.fields != null) {
        // issues2.add(Issue.fromFirestoreDocument(doc.fields!));
        var js = doc.toJson(); // convert to json
        var js2 = jsonEncode(js); // convert to string
        var js3 = jsonDecode(js2); // convert to map
        issues.add(Issue.fromFirestoreDocument(js3));
        // issues2.add(Issue.fromFirestoreDocument(js));
      }
    }

    return shelf.Response.ok(
      JsonUtf8Encoder(' ').convert(result),
      headers: {
        'content-type': 'application/json',
      },
    );
  }

  // WIP: Finish this method
  /// Writes a new document to the Firestore database.
  /// The document is created with a random ID.
  Future<shelf.Response> writeHandler(shelf.Request request) async {
    String? collectionId = request.url.queryParameters['collectionId'];
    if (collectionId == null) {
      return shelf.Response(400, body: 'Missing collectionId');
    }

    Document document = Document(
      name: '$_firestoreBaseCollectionPath/$collectionId',
      fields: {
        // WIP: add fields from request
        // 'title': Value()..stringValue = 'Hello World',
        // 'description': Value()..stringValue = 'This is a description',
        // 'created': Value()..timestampValue = DateTime.now().toUtc(),
      },
    );

    final result = await _api.projects.databases.documents.createDocument(
      document,
      // Top level base collection path
      _firestoreBaseCollectionPath,
      collectionId,
    );

    return shelf.Response.ok(
      JsonUtf8Encoder(' ').convert(result),
      headers: {
        'content-type': 'application/json',
      },
    );
  }

  // WIP: Add Try Catch error handling
  // WIP: Finish this method
  /// Reads a document from the Firestore database.
  ///
  /// Expected request body:
  /// ```json
  /// {
  ///   "collectionId": "issues",
  ///   "document": "documentId"
  /// }
  ///
  Future<shelf.Response> readDocumentHandler(shelf.Request request) async {
    // Get the collection and document ID from the request.
    final collectionId = request.url.queryParameters['collectionId'];
    final documentId = request.url.queryParameters['documentId']!;

    final result = await _api.projects.databases.documents.get(
      'projects/$projectId/databases/(default)/documents/$collectionId/$documentId',
    );

    return shelf.Response.ok(
      prettyJsonEncode(result),
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
