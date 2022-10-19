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
    final projectId = FirebaseClient.instance.projectId;

    return 'projects/$projectId/databases/(default)/documents';
  }

  FirebaseApiRepository({required this.firebaseAuthClient})
      : _api = FirestoreApi(firebaseAuthClient.authenticatedClient),
        projectId = firebaseAuthClient.projectId;

  final String projectId;

  final FirebaseClient firebaseAuthClient;
  final FirestoreApi _api;

  Future<shelf.Response> incrementHandler(shelf.Request request) async {
    var projectId = FirebaseClient.instance.projectId;

    final result = await _api.projects.databases.documents.commit(
      _incrementRequest(FirebaseClient.instance.projectId),
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
    Issues issues = Issues();

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
        // This block is to convert the Document to a Map<String, dynamic> in
        // JSON format, instead of a Map<String, Value>.
        var docAsJson = doc.toJson(); // convert to Map<String, dynamic>
        var docAsString = jsonEncode(docAsJson); // convert to JSON string
        var docAsMap =
            jsonDecode(docAsString); // convert to Map<String, dynamic>

        issues.add(Issue.fromFirestoreDocument(docAsMap));
      }
    }

    // String _issuesToJson(List<Issue> issues) {
    //   var issuesAsJson = issues.map((issue) => issue.toJson()).toList();
    //   return jsonEncode(issuesAsJson);
    // }

    return DatabaseResponse.successfulRequest(payload: issues);
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
