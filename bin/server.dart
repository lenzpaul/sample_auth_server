// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:convert';
import 'dart:developer';

import 'package:cloud_run_google_apis/helpers.dart';
import 'package:dotenv/dotenv.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class FirebaseAuthAPIMethods {
  FirebaseAuthAPIMethods._();
  static const signInWithPassword = 'signInWithPassword';
  static const signInAnonymously = 'signUp';
}

/// See:
/// https://firebase.google.com/docs/reference/rest/auth#section-sign-in-email-password
class FirebaseAuthClient {
  FirebaseAuthClient._();
// curl 'https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=[API_KEY]' \
// -H 'Content-Type: application/json' --data-binary '{"returnSecureToken":true}'

  static String get apiKey {
    var env = DotEnv(includePlatformEnvironment: true)..load();

    if (env['FIREBASE_API_KEY'] == null) {
      throw Exception(
        'FIREBASE_API_KEY is not set. '
        'Please set it in your .env file at the root of your project.\n'
        'e.g.: FIREBASE_API_KEY="APIKEYHERE"',
      );
    }

    return env['FIREBASE_API_KEY']!;
  }

  static const firebaseAuthBaseUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts';

  static String get signInWithPasswordUrl =>
      '$firebaseAuthBaseUrl:${FirebaseAuthAPIMethods.signInWithPassword}?key=$apiKey';

  static String get signInAnonymouslyUrl =>
      '$firebaseAuthBaseUrl:${FirebaseAuthAPIMethods.signInAnonymously}?key=$apiKey';

  static loginAnonymouslyHandler(Request request) async {
    log("Request: ${request.url}");

    final http.Response result = await http.post(
      Uri.parse(signInAnonymouslyUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'returnSecureToken': true,
      }),
    );

    Response response;

    if (result.statusCode == 200) {
      var body = jsonDecode(result.body);
      var email = body['email']; // Empty string
      var uid = body['localId'];

      response = Response.ok(
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
      response = Response(
        result.statusCode,
        body: result.body,
      );
    }

    log("Response: ${response.statusCode}");

    return response;
  }

  /// Expects a [Request] with authorization header as follows:
  /// {authorization: 'Basic <base64 encoded email:password>'}
  ///
  /// Returns a [Response] with the following body:
  /// {
  ///   "uid": "string",
  ///   "email": "string"
  /// }
  static loginWithEmailAndPasswordHandler(Request request) async {
    log("Request: ${request.url}");

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
      Uri.parse(signInWithPasswordUrl),
      body: {
        'email': email,
        'password': password,
      },
    );

    // Return the uid and the email of the firebase user.
    var response;
    if (result.statusCode == 200) {
      var body = jsonDecode(result.body);
      var email = body['email'];
      var uid = body['localId'];

      response = Response.ok(
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
      response = Response(
        result.statusCode,
        body: result.body,
      );
    }

    log("Response: ${response.statusCode}");

    return response;
  }
}

Future main() async {
  // await Future.delayed(Duration(hours: 1));

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
