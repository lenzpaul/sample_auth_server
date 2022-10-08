// ignore_for_file: unnecessary_this, no_leading_underscores_for_local_identifiers

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:sample_auth_server/helpers.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

/// Name of the method to call on the [FirebaseAuthClient] class.
///
/// These map the Firebase Auth REST API methods.
class FirebaseAuthAPIMethods {
  FirebaseAuthAPIMethods._();
  static const signInWithPassword = 'signInWithPassword';
  static const signInAnonymously = 'signUp';
}

/// {@template firebase_auth_client}
/// Responsible for handling requests to the Firebase Auth REST API.
///
/// Defines the request handlers, builds the URL, and gets the API key from
/// env.
/// {@endtemplate}
class FirebaseAuthClient {
  FirebaseAuthClient._() {
    _setupRouter();
  }

  /// {@macro firebase_auth_client}
  factory FirebaseAuthClient() => _instance; // Singleton

  static final _instance = FirebaseAuthClient._();
  late Router _router;

  /// A [Router] that handles requests to the Firebase Auth REST API.
  Handler get router => _router;

  /// Same as [router], but with logging.
  Handler get routerWithLogging => logRequests().addHandler(router);

  /// Initializes the router and adds the request handlers.
  void _setupRouter() {
    this._router = (Router())
      ..get('/login', FirebaseAuthClient.loginWithEmailAndPasswordHandler)
      ..get('/loginAnonymously', FirebaseAuthClient.loginAnonymouslyHandler);
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

  /// The base URL for the Firebase Auth REST API.
  static const firebaseAuthBaseUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts';

  /// Appends the sign in with password method to the base URL.
  static String get signInWithPasswordUrl =>
      '$firebaseAuthBaseUrl:${FirebaseAuthAPIMethods.signInWithPassword}?key=$apiKey';

  /// Appends the sign in anonymously method to the base URL.
  static String get signInAnonymouslyUrl =>
      '$firebaseAuthBaseUrl:${FirebaseAuthAPIMethods.signInAnonymously}?key=$apiKey';

  /// Handles requests to the Firebase Auth REST API for signing in anonymously.
  ///
  /// Does not require any headers or body.
  static Future<Response> loginAnonymouslyHandler(Request request) async {
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
  static Future<Response> loginWithEmailAndPasswordHandler(
      Request request) async
  //
  {
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

    // Authentication not successful.
    if (result.statusCode != 200) {
      var res = Response(
        result.statusCode,
        body: result.body,
      );
      return res;
    }

    // Authentication successful. Return the uid and the email of the firebase
    // user.
    var body = jsonDecode(result.body);
    email = body['email'];
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
  }
}
