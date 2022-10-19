part of 'firebase_auth_client.dart';

/// {@template firestore_repository}
/// Wrapper for the Firestore API.
/// {@endtemplate}
class FirebaseApiRepository {
  static get _firestoreBaseCollectionPath {
    final projectId = FirebaseClient.instance.projectId;
    return 'projects/$projectId/databases/(default)/documents';
  }

  /// {@macro firestore_repository}
  FirebaseApiRepository({required this.firebaseAuthClient})
      : _api = FirestoreApi(firebaseAuthClient.authenticatedClient),
        projectId = firebaseAuthClient.projectId;

  /// The Google Cloud Project ID.
  final String projectId;

  /// An authenticated HTTP client that can be used to make requests to the
  /// Firestore API.
  final FirebaseClient firebaseAuthClient;

  /// The Firestore API.
  final FirestoreApi _api;

  /// GET /issues
  ///
  /// Handler for the GET /issues endpoint. Returns a list of all issues.
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

    return DatabaseResponse.successfulRequest(payload: issues);
  }

  /// POST /issues/{id}
  ///
  /// This is the handler for the POST /issues/{id} endpoint.
  ///
  /// It creates a new issue with the given ID.
  Future<shelf.Response> createIssueHandler(shelf.Request request) async {
    try {
      // The document ID is the last part of the URL path (e.g. "issues/123").
      //
      // Here should be the same as the Issues uuid in the request body.
      final documentId = request.url.pathSegments.last;

      // Get the issue from the request body.
      Map<String, dynamic> issueAsMap =
          await request.readAsString().then((value) {
        try {
          return jsonDecode(value);
        } catch (e) {
          throw DecodingException(
            message: 'The request body is not a valid JSON string.',
          );
        }
      });

      Map<String, dynamic> issueAsFields = mapToFieldValueMap(issueAsMap);

      // Create the document from the issue.
      //
      // Times must be in UTC format for Firestore database.
      var document = Document.fromJson(
        {
          "createTime": DateTime.now().toUtc().toIso8601String(),
          "updateTime": DateTime.now().toUtc().toIso8601String(),
          'fields': issueAsFields,
        },
      );

      /// Create the issue Document in Firestore database.
      final Document result =
          await _api.projects.databases.documents.createDocument(
        document,
        '$_firestoreBaseCollectionPath',
        'issues', // the collectionId
        documentId: documentId,
      );

      return shelf.Response.ok(
        JsonUtf8Encoder(' ').convert(result),
        headers: {
          'content-type': 'application/json',
        },
      );
    } catch (e) {
      return DatabaseResponse.unsuccessfulRequest(
        errorMessage: e.toString(),
        errorDescription: 'Error creating issue in Firestore database.',
      );
    }
  }

  //
  // /// TODO: GET /issues/{id}
  // ///
  // /// Endpoint to get a single issue.
  // Future<shelf.Response> getIssueHandler(shelf.Request request) async {
  //   final issueId = request.url.pathSegments.last;

  //   final result = await _api.projects.databases.documents.get(
  //     '$_firestoreBaseCollectionPath/issues/$issueId',
  //   );

  //   if (result.fields != null) {
  //     // This block is to convert the Document to a Map<String, dynamic> in
  //     // JSON format, instead of a Map<String, Value>.
  //     var docAsJson = result.toJson(); // convert to Map<String, dynamic>
  //     var docAsString = jsonEncode(docAsJson); // convert to JSON string
  //     var docAsMap =
  //         jsonDecode(docAsString); // convert to Map<String, dynamic>

  //     return DatabaseResponse.successfulRequest(payload: Issue.fromFirestoreDocument(docAsMap));
  //   }

  //   return DatabaseResponse.notFound();
  // }

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
