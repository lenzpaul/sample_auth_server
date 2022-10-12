// ignore_for_file: unnecessary_this, no_leading_underscores_for_local_identifiers

import 'dart:async';

import 'package:http/http.dart' as http;
// import 'package:sample_auth_server/clients/firestore_repository.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:sample_auth_server/helpers.dart';
import 'dart:convert';
import 'package:sample_auth_server/models/models.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';

part 'firestore_repository.dart';

/// Name of the methods to call on the [FirebaseAuthClient] class.
///
/// These map the Firebase Auth REST API methods.
class FirebaseAuthAPIMethods {
  FirebaseAuthAPIMethods._();

  static const signInAnonymously = 'signUp';
  static const signInWithPassword = 'signInWithPassword';
  static const signUp = 'signUp';
}

/// {@template firebase_auth_client}
/// Responsible for handling requests to the Firebase Auth REST API.
///
/// Defines the request handlers, builds the URL, and gets the API key from
/// env.
///
/// Routes are defined in [_setupRouter].
/// {@endtemplate}
class FirebaseAuthClient {
  // Private constructor to prevent instantiation.
  FirebaseAuthClient._();

  /// The base URL for the Firebase Auth REST API.
  static const firebaseAuthBaseUrl =
      'https://identitytoolkit.googleapis.com/v1/accounts';

  static const verifyIdTokenUrl =
      // 'https://function-1-k3wnvtq2fa-uc.a.run.app';
      'https://verify-id-token-k3wnvtq2fa-uc.a.run.app';

  static final _instance = FirebaseAuthClient._();
  static get instance => _instance;

  /// The authenticated client used to make requests to the Firebase Auth REST
  /// API.
  late http.Client _authenticatedClient;

  /// Initialized in [initClient]
  late FirebaseApiRepository _firestoreRepository;

  /// initialized in [initClient]
  late String _projectId;

  /// initialized in [initClient]
  late shelf_router.Router _router;

  /// Runs the server.
  ///
  /// This is the entry point for the server.
  static Future run() async {
    await _instance.initClient();
    try {
      await serveHandler(
          shelf.logRequests().addHandler(FirebaseAuthClient.instance.router));
    } catch (e) {
      rethrow;
    }
  }

  /// A [Router] that handles requests to the Firebase Auth REST API.
  shelf.Handler get router => _router;

  /// Same as [router], but with logging.
  shelf.Handler get routerWithLogging => shelf.logRequests().addHandler(router);

  static void close() {
    FirebaseAuthClient.instance._authenticatedClient.close();
  }

  String get projectId => _projectId;

  http.Client get authenticatedClient => _authenticatedClient;

  Future<void> initClient() async {
    _projectId = await currentProjectId();

    print('Current GCP project id: $_projectId');

    // `clientViaApplicationDefaultCredentials` is a function from the
    // `googleapis_auth` package. It authenticates the client using the
    // application default credentials.
    //
    // The application default credentials are typically stored in:
    // `$HOME/.config/gcloud/application_default_credentials.json`.
    _authenticatedClient = await clientViaApplicationDefaultCredentials(
      scopes: [
        // Required to have access to user data
        FirestoreApi.cloudPlatformScope,
        // Required for Firestore
        FirestoreApi.datastoreScope,
        // Cloud functions
        'https://www.googleapis.com/auth/cloud-platform',
      ],
    );

    _firestoreRepository = FirebaseApiRepository(firebaseAuthClient: this);

    _setupRouter();
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

  /// Appends the sign up method to the base URL.
  static String get signUpUrl =>
      '$firebaseAuthBaseUrl:${FirebaseAuthAPIMethods.signUp}?key=$apiKey';

  /// Handles requests to the Firebase Auth REST API for signing in anonymously.
  ///
  /// Does not require any headers or body.
  Future<shelf.Response> loginAnonymouslyHandler(shelf.Request request) async {
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
      response = AuthResponse.loginFailedFromFirebaseResponseBody(result.body);
    }

    return response;
  }

  /// Expects a [Request] with authorization header as follows:
  /// {authorization: 'Basic <base64 encoded email:password>'}
  ///
  /// Returns a [Response] with the following body:
  /// ```json
  /// {
  ///   code: 200,
  ///   message: "LOGIN_SUCCESS",
  ///   userData: {
  ///    'uid': 'xxxxx',
  ///    'email': 'a@a.ca',
  ///    'username': 'a',
  ///    'isGuest': false,
  ///   }
  /// }
  /// ```
  Future<shelf.Response> loginWithEmailAndPasswordHandler(
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

    // final result = await _authenticatedClient.post(
    final result = await _authenticatedClient.post(
      Uri.parse(signInWithPasswordUrl),
      body: {
        'email': email,
        'password': password,
      },
    );

    // Authentication not successful.
    if (result.statusCode != 200) {
      return AuthResponse.loginFailedFromFirebaseResponseBody(result.body);
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

  /// Expects a [Request] with basic authorization with base64 encoded
  /// credentials in the format of <email>:<password> and a body with the
  /// desired username.
  ///
  /// Headers:
  /// {authorization: 'Basic <base64 encoded email:password>'}
  ///
  /// Body:
  /// ```json
  /// {
  ///  "username": "string",
  /// }
  /// ```
  ///
  /// Returns a [Response] with the following body:
  /// ```json
  /// {
  ///   code: 200,
  ///   message: "SIGNUP_SUCCESS",
  ///   userData: {
  ///     'uid': 'xxxxx',
  ///     'email': '
  ///     'username': 'a',
  ///     'isGuest': false,
  ///   }
  /// }
  /// ```
  /// or
  /// ```json
  /// {
  ///  code: 400,
  /// message: "SIGNUP_FAILED",
  /// }
  /// ```
  // WIP
  // Future<shelf.Response> signUpWithEmailAndPasswordHandler(
  //     shelf.Request request) async
  // //
  // {
  //   var authorization = request.headers['authorization'];
  //   if (authorization == null) {
  //     return AuthResponse.badRequest('Authorization header is missing');
  //   }

  //   // Check authorization header for the type of authentication. Only support
  //   // Firebase authentication for now with Basic Auth base64 encoded.
  //   var authType = authorization.split(' ')[0];

  //   // Unsupported authentication type provided.
  //   if (authType != 'Basic') {
  //     return AuthResponse.badRequest(
  //       'Unsupported authentication type. Only Basic Auth is supported.',
  //     );
  //   }

  //   // The authorization type is Basic. Decode the base64 encoded
  //   // credentials and send to Firebase for authentication.
  //   //
  //   // The encoded credentials are expected to be in the format of
  //   // <email>:<password>.
  //   var authValue = authorization.split(' ')[1]; // base64 encoded credentials
  //   var decoded = base64.decode(authValue); // decoded credentials in bytes
  //   var decodedString = utf8.decode(decoded); // decoded credentials in string
  //   var email = decodedString.split(':')[0];
  //   var password = decodedString.split(':')[1];

  //   // Get the username from the request body.
  //   var body = await request.readAsString();
  //   var username = jsonDecode(body)['username'];

  //   // Send the request to Firebase.
  //   final result = await _authenticatedClient.post(
  //     Uri.parse(signUpUrl),
  //     body: {
  //       'email': email,
  //       'password': password,
  //       'returnSecureToken': true,
  //     },
  //   );

  //   // Sign up not successful.
  //   if (result.statusCode != 200) {
  //     return AuthResponse.fromFirebaseAuthErrorResponseBody(result.body);
  //   }

  //   // Sign up successful.
  //   //
  //   // Return the uid and the email of the firebase user.
  //   final Map<String, dynamic> body = jsonDecode(result.body);

  //   var user = AuthUser(
  //     email: body['email'],
  //     uid: body['localId'],
  //   );

  //   return AuthResponse.signUpSuccesful(user);
  // }

  /// Expects a [Request] with `Bearer <idToken>` in the authorization header.
  ///
  /// Returns a [Response] with the following body:
  ///
  /// Returns a successful response if the token is valid and not expired. The
  /// response body contains the user data in the following format:
  /// ```json
  /// {
  ///   'code': 200,
  ///   'message': 'TOKEN_VALID',
  ///   'userData': {
  ///     'uid': result['user_id'],
  ///     'email': result['email'],
  ///   },
  /// },
  /// ```
  Future<shelf.Response> verifyIdTokenHandler(shelf.Request request) async {
    var authorizationHeader = request.headers['authorization'];
    if (authorizationHeader == null) {
      return AuthResponse.badRequest('Authorization header is missing');
    }

    // Check authorization header for the Bearer token.
    var authType = authorizationHeader.split(' ')[0];

    // Unsupported authentication type provided.
    if (authType != 'Bearer') {
      return AuthResponse.badRequest(
        'Unsupported authentication type. Only Bearer Auth is supported.',
      );
    }

    // The authorization type is Bearer. Get the idToken.
    var idToken = authorizationHeader.split(' ')[1];

    try {
      final Map<String, dynamic> result = decodeJwt(idToken);

      // Check if the token is expired.
      if (result['exp'] * 1000 < DateTime.now().millisecondsSinceEpoch) {
        // Token is expired.
        return shelf.Response.unauthorized(
          prettyJsonEncode(
            {
              'code': 401,
              'message': 'TOKEN_EXPIRED',
            },
          ),
        );
      }

      // Token is not expired.
      return shelf.Response.ok(
        // TODO: Create a method to format the response.
        prettyJsonEncode(
          {
            'code': 200,
            'message': 'TOKEN_VALID',
            'userData': {
              'uid': result['user_id'],
              'email': result['email'],
            },
          },
        ),
      );
    } catch (e) {
      print(e);

      return shelf.Response.unauthorized(
        prettyJsonEncode(
          {
            'code': 401,
            'message': 'ID_TOKEN_VERIFICATION_FAILED',
          },
        ),
      );
    }
  }

  /// Sets up the [Router] and defines the request handlers.
  void _setupRouter() {
    this._router = (shelf_router.Router())
      ..get('/login', loginWithEmailAndPasswordHandler)
      ..get('/loginAnonymously', loginAnonymouslyHandler)
      // ..get('/signUp', signUpHandler)
      ..get('/verifyIdToken', verifyIdTokenHandler)
      ..get('/db', _firestoreRepository.incrementHandler)
      ..get('/issues', _firestoreRepository.getIssuesHandler);
  }
}
