// ignore_for_file: unnecessary_this, no_leading_underscores_for_local_identifiers

import 'package:http/http.dart' as http;
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:sample_auth_server/helpers.dart';
import 'dart:convert';
import 'package:sample_auth_server/models/models.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';

/// Name of the method to call on the [FirebaseAuthClient] class.
///
/// These map the Firebase Auth REST API methods.
class FirebaseAuthAPIMethods {
  FirebaseAuthAPIMethods._();

  static const signInAnonymously = 'signUp';
  static const signInWithPassword = 'signInWithPassword';
}

/// {@template firebase_auth_client}
/// Responsible for handling requests to the Firebase Auth REST API.
///
/// Defines the request handlers, builds the URL, and gets the API key from
/// env.
/// {@endtemplate}
class FirebaseAuthClient {
  /// {@macro firebase_auth_client}
  factory FirebaseAuthClient() => instance; // Singleton

  FirebaseAuthClient._() {
    _setupRouter();
  }

  /// The base URL for the Firebase Auth REST API.
  static const firebaseAuthBaseUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts';

  static final instance = FirebaseAuthClient._();

  late http.Client _authenticatedClient;
  late final String _projectId;
  late shelf_router.Router _router;

  /// A [Router] that handles requests to the Firebase Auth REST API.
  shelf_router.Router get router => _router;

  /// Same as [router], but with logging.
  shelf.Handler get routerWithLogging => shelf.logRequests().addHandler(router);

  Future<void> initClient() async {
    _projectId = await currentProjectId();
    print('Current GCP project id: $_projectId');

    _authenticatedClient = await clientViaApplicationDefaultCredentials(
      scopes: [FirestoreApi.datastoreScope],
    );
  }

  /// Get the API key from the environment.
  static String get apiKey {
    // final env = Platform.environment;

    var _apiKey = getEnvVar("FIREBASE_API_KEY");

    if (_apiKey == null) {
      throw Exception(
        'FIREBASE_API_KEY is not set. '
        'Please set it in your .env file at the root of your project.\n'
        'e.g.: FIREBASE_API_KEY="APIKEYHERE"',
      );
    }

    return _apiKey;
  }

  /// Appends the sign in with password method to the base URL.
  static String get signInWithPasswordUrl =>
      '$firebaseAuthBaseUrl:${FirebaseAuthAPIMethods.signInWithPassword}?key=$apiKey';

  /// Appends the sign in anonymously method to the base URL.
  static String get signInAnonymouslyUrl =>
      '$firebaseAuthBaseUrl:${FirebaseAuthAPIMethods.signInAnonymously}?key=$apiKey';

  /// Handles requests to the Firebase Auth REST API for signing in anonymously.
  ///
  /// Does not require any headers or body.
  static Future<shelf.Response> loginAnonymouslyHandler(
      shelf.Request request) async {
    final http.Response result = await http.post(
      Uri.parse(signInAnonymouslyUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'returnSecureToken': true,
      }),
    );

    shelf.Response response;

    if (result.statusCode == 200) {
      var body = jsonDecode(result.body);
      var user = AuthUser(
        uid: body['localId'],
        isGuest: true, // Logged in anonymously
      );

      response = AuthResponse.loginSuccesful(user);
    } else {
      // An error occurred.
      response = AuthResponse.fromFirebaseAuthErrorResponseBody(result.body);
    }

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
  static Future<shelf.Response> loginWithEmailAndPasswordHandler(
      shelf.Request request) async
  //
  {
    var authorization = request.headers['authorization'];
    if (authorization == null) {
      return AuthResponse.badRequest('Authorization header is missing');
    }

    // Check authorization header for the type of authentication. Only support
    // Firebase authentication for now with Basic Auth base64 encoded.
    var authType = authorization.split(' ')[0];

    // Unsupported authentication type provided.
    if (authType != 'Basic') {
      return AuthResponse.badRequest(
        'Unsupported authentication type. Only Basic Auth is supported.',
      );
    }

    // The authorization type is Basic. Decode the base64 encoded
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

    // Authentication not successful.
    if (result.statusCode != 200) {
      return AuthResponse.fromFirebaseAuthErrorResponseBody(result.body);
    }

    // Authentication successful.
    //
    // Return the uid and the email of the firebase user.
    final Map<String, dynamic> body = jsonDecode(result.body);

    var user = AuthUser(
      email: body['email'],
      uid: body['localId'],
    );

    return AuthResponse.loginSuccesful(user);
  }

  /// Initializes the router and adds the request handlers.
  void _setupRouter() {
    this._router = (shelf_router.Router())
      ..get('/login', FirebaseAuthClient.loginWithEmailAndPasswordHandler)
      ..get('/loginAnonymously', FirebaseAuthClient.loginAnonymouslyHandler);
  }
}
