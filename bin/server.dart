// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:convert';

import 'package:cloud_run_google_apis/helpers.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class FirebaseAuthAPIMethods {
  FirebaseAuthAPIMethods._();
  static const signInWithPassword = 'signInWithPassword';
}

/// See:
/// https://firebase.google.com/docs/reference/rest/auth#section-sign-in-email-password
class FirebaseAuthClient {
  FirebaseAuthClient._();

// FIXME: Move to environment variable
  static const _apiKey = 'AIzaSyAcSBrLIJO4dP_KX6ojNvYvvH17s-BjVXY';

  static const firebaseAuthBaseUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts';

  static const signInWithPasswordUrl =
      '$firebaseAuthBaseUrl:${FirebaseAuthAPIMethods.signInWithPassword}?key=$_apiKey';

  /// Expects a [Request] with authorization header as follows:
  /// {authorization: 'Basic <base64 encoded email:password>'}
  ///
  /// Returns a [Response] with the following body:
  /// {
  ///   "uid": "string",
  ///   "email": "string"
  /// }
  static loginHandler(Request request) async {
    var authorization = request.headers['authorization'];
    if (authorization == null) {
      return Response(401, body: 'Unauthorized. Missing authorization header.');
    }

    // Check authorization header for the type of authentication. Only support
    // Firebase authentication for now with Basic Auth base64 encoded.
    var authType = authorization.split(' ')[0];
    if (authType != 'Basic') {
      return Response(
        401,
        body: 'Invalid authorization type. '
            'Only Basic is supported at this time.',
      );
    }

    // If the authorization type is Basic, then decode the base64 encoded
    // credentials and send to Firebase for authentication.
    //
    // The encoded credentials are expected to be in the format of
    // <email>:<password>.
    var authValue = authorization.split(' ')[1]; // base64 encoded credentials
    var decoded = base64.decode(authValue); // decoded credentials in bytes
    var decodedString = utf8.decode(decoded); // decoded credentials in string
    var email = decodedString.split(':')[0];
    var password = decodedString.split(':')[1];

    final result = await http.post(
      Uri.parse(FirebaseAuthClient.signInWithPasswordUrl),
      body: {
        'email': email,
        'password': password,
      },
    );

    // Return the uid and the email of the firebase user.
    if (result.statusCode == 200) {
      var body = jsonDecode(result.body);
      var email = body['email'];
      var uid = body['localId'];

      return Response.ok(
        JsonUtf8Encoder(' ').convert(
          {
            'email': email,
            'uid': uid,
          },
        ),
        headers: {
          'content-type': 'application/json',
        },
      );
    } else {
      return Response(
        result.statusCode,
        body: result.body,
      );
    }
  }
}

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
  router.get('/login', FirebaseAuthClient.loginHandler);
  // router.get('/logout', _firebaseLogoutHandler);

  return router;
}
