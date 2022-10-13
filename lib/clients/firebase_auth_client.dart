// ignore_for_file: unnecessary_this, no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:markdown/markdown.dart' as md;
// import 'package:sample_auth_server/clients/firestore_repository.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_router/shelf_router.dart' as shelf_router;
import 'package:sample_auth_server/helpers.dart';
import 'dart:convert';
import 'package:sample_auth_server/models/models.dart';
import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

part 'firestore_repository.dart';

/// Name of the methods to call on the [FirebaseAuthClient] class.
///
/// These map the Firebase Auth REST API methods.
class FirebaseAuthAPIMethods {
  FirebaseAuthAPIMethods._();

  static const signInAnonymously = 'signUp';
  static const signInWithPassword = 'signInWithPassword';
  static const signUp = 'signUp';

  /// Fetches the user data from the Firebase Auth API.
  static const getUserData = 'lookup';

  /// Updates the user data from the Firebase Auth API.
  static const updateUser = 'update';
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

  /// The authenticated client used to make requests to the Firestore API.
  late http.Client _authenticatedClient;

  /// http.Client used to make requests to the Firebase Auth API.
  late http.Client _client;

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
        // User data
        "https://www.googleapis.com/auth/firebase"
      ],
    );

    _client = http.Client();

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

  /// Appends the [FirebaseAuthAPIMethods.signUp] method to the base URL.
  static String get signUpUrl =>
      '$firebaseAuthBaseUrl:${FirebaseAuthAPIMethods.signUp}?key=$apiKey';

  /// Appends the [FirebaseAuthAPIMethods.getUserData] method to the base URL.
  ///
  /// The [FirebaseAuthAPIMethods.getUserData] method is used to fetch the user
  /// data from the Firebase Auth API.
  static String get getUserDataUrl =>
      '$firebaseAuthBaseUrl:${FirebaseAuthAPIMethods.getUserData}?key=$apiKey';

  /// Appends the [FirebaseAuthAPIMethods.updateUser] method to the base URL.
  static String get updateUserUrl =>
      '$firebaseAuthBaseUrl:${FirebaseAuthAPIMethods.updateUser}?key=$apiKey';

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
      response = AuthResponse.failedWithFirebaseResponseBody(result.body);
    }

    return response;
  }

  /// POST /login
  ///
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
    final result = await _client.post(
      Uri.parse(signInWithPasswordUrl),
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );

    // Authentication not successful.
    if (result.statusCode != 200) {
      return AuthResponse.failedWithFirebaseResponseBody(result.body);
    }

    // Authentication successful.
    //
    // Return the user data.
    final Map<String, dynamic> body = jsonDecode(result.body);

    var user = AuthUser(
      email: body['email'],
      uid: body['localId'],
      isGuest: false,
      username: body['displayName'],
      idToken: body['idToken'],
    );

    return AuthResponse.loginSuccesful(user);
  }

  /// Expects a POST [Request] with basic authorization with base64 encoded
  /// credentials in the format of <email>:<password> and a body with the
  /// desired username.
  ///
  /// Headers:
  /// `{authorization: 'Basic <base64 encoded email:password>'}`
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
  Future<shelf.Response> signUpWithEmailAndPasswordHandler(
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

    // Get the username from the request body.
    var clientReqBody = await request.readAsString();
    var username = jsonDecode(clientReqBody)['username'];

    // Create a new user in Firebase. This does not add the username to the
    // user's profile. This is done in the next step.
    //
    // !!! Security risk here: for the sample, the password is sent in plain
    // text at the moment. DON'T DO THIS IN A REAL APP! At minimum, the password
    // should be hashed before sending to Firebase.
    //
    /// Use http client to send the request to Firebase.
    final result = await _client.post(
      Uri.parse(signUpUrl),
      body: jsonEncode({
        'email': email,
        'password': password, // !!! Unhashed password
        'returnSecureToken': true,
      }),
    );

    // final result = await _authenticatedClient.post(
    // Uri.parse(signUpUrl),
    // body: createUserReqBody,
    // headers: {
    //   'Content-Type': 'application/json',
    // },
    // encoding: Encoding.getByName('utf-8'),

    // body: {
    //   'email': email,
    //   'password': password, // !!! Security risk here !!!
    //   'returnSecureToken': true,
    // },
    // );

    // Sign up not successful.
    if (result.statusCode != 200) {
      var res = AuthResponse.signupFailedFromFirebaseResponse(result.body);

      print(res.body);

      // print('Sign up failed: ${res.readAsString()}');
      return res;
    }

    // Sign up successful. Get the uid of the newly created user.
    final Map<String, dynamic> fbSignupResponseBody = jsonDecode(result.body);
    var uid = fbSignupResponseBody['localId'];
    var idToken = fbSignupResponseBody['idToken'];

    // Now we add the username to the user's profile.
    //
    // Call our [updateProfileHandler] to update the user's profile.
    //
    // We create a Shelf request with the uid and username in the body.
    var updateReq = shelf.Request(
      // Method
      'POST',
      // The full to our endpoint. Here we are using the incoming request's url
      // and replace the endpoint with the update profile endpoint.
      // ($serverUrl/updateProfile)
      Uri.parse(request.requestedUri.toString().replaceFirst(
          FirebaseAuthAPIMethods.signUp, FirebaseAuthAPIMethods.getUserData)),

      headers: {'authorization': 'Bearer $idToken'},
      body: jsonEncode({'username': username}),
    );

    // Call the update profile handler.
    shelf.Response updateProfileResponse =
        await updateProfileHandler(updateReq);

    // Update profile not successful.
    if (updateProfileResponse.statusCode != 200) {
      // Return our handler's response.
      return updateProfileResponse;
    }

    // Update profile successful. Return the user's data.
    return AuthResponse.signUpSuccesful(
      AuthUser(
        uid: uid,
        email: email,
        username: username,
        isGuest: false,
        idToken: idToken,
      ),
    );
  }

  /// GET /verifyIdToken
  ///
  /// Expects a [Request] with `Bearer <idToken>` in the authorization header.
  ///
  /// Returns a 200 response if the token is valid. Returns a 401 response if
  /// the token is invalid. Returns a 400 response if the authorization header
  /// is missing.
  ///
  /// The response body is in the following format. If the token is valid, the
  /// user uid and email are returned under the `userData` key:
  ///
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
      return shelf.Response(
        400,
        body: 'Unsupported authentication type.',
      );
    }

    // The authorization type is Bearer. Get the idToken.
    var idToken = authorizationHeader.split(' ')[1];

    try {
      // Check if the token is valid.
      bool tokenIsValid = verifyJwt(idToken);
      if (!tokenIsValid) {
        return shelf.Response.unauthorized(
          prettyJsonEncode(
            {
              'code': 401,
              'message': 'TOKEN_INVALID',
            },
          ),
        );
      }

      // Token is valid.
      final Map<String, dynamic> result = decodeJwt(idToken);

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

  /// POST /updateProfile
  ///
  /// Updates the user's profile.
  ///
  /// Expects a [Request] with `Bearer <idToken>` in the authorization header and
  /// a body with the following format:
  /// ```json
  /// {
  ///  'username': 'username'
  /// }
  ///
  /// Returns a [Response] with the following body:
  /// ```json
  /// {
  ///  'code': 200,
  ///  'message': 'PROFILE_UPDATED',
  /// }
  /// ```
  ///
  /// If the request fails, the response will return a 400, 401 or 500 status
  /// code. The response body will contain the error message.
  ///
  /// Fomat of the error response body:
  ///
  /// ```json
  /// {
  ///   'code': 500,
  ///   'message': 'PROFILE_UPDATE_FAILED'
  /// }
  /// ```
  ///
  Future<shelf.Response> updateProfileHandler(shelf.Request request) async {
    var authorizationHeader = request.headers['authorization'];

    // Authorization header is missing.
    if (authorizationHeader == null) {
      return AuthResponse.badRequest('Authorization header is missing');
    }

    // Check authorization header for the Bearer token.
    var authType = authorizationHeader.split(' ')[0];

    // Bearer token is missing. Unsupported authentication type provided.
    if (authType != 'Bearer') {
      return AuthResponse.badRequest(
        'Unsupported authentication type. Only Bearer Auth is supported.',
      );
    }

    // The authorization type is Bearer. Get the idToken.
    var idToken = authorizationHeader.split(' ')[1];

    // Check if the token is valid.
    bool tokenIsValid = verifyJwt(idToken);

    if (!tokenIsValid) {
      // Token is invalid.
      return shelf.Response.unauthorized(
        prettyJsonEncode(
          {
            'code': 401,
            'message': 'TOKEN_INVALID',
          },
        ),
      );
    }

    // Token is valid. Update the user's profile.
    String? username;
    String? photoUrl;

    // Get the request body.
    var clientReqBody = await request.readAsString();
    var clientReqBodyMap = jsonDecode(clientReqBody);

    // Prepare the request body for the Firebase API.
    var serverReqBody = {'idToken': idToken};

    // Get the username from the request body and add it to the server's
    // request body.
    if (clientReqBodyMap['username'] != null) {
      username = clientReqBodyMap['username'];
      // `username` is `displayName` on Firebase.
      serverReqBody['displayName'] = username!;
    }

    // Get the photo url from the request body and add it to the server's
    // request body.
    if (clientReqBodyMap['photoUrl'] != null) {
      photoUrl = clientReqBodyMap['photoUrl'];
      serverReqBody['photoUrl'] = photoUrl!;
    }

    // If both the display name and the photo url are null, return a bad
    // request response.
    if (username == null && photoUrl == null) {
      // TODO: Create a method to format the response.
      return shelf.Response.badRequest(
        body: prettyJsonEncode({
          'code': 400,
          'message':
              'At least one of the following fields must be provided: displayName, photoUrl',
        }),
      );
    }

    // Update the user's profile.
    final result = await _authenticatedClient.post(
      Uri.parse(updateUserUrl),
      body: serverReqBody,
    );

    // Update not successful.
    if (result.statusCode != 200) {
      // TODO: Create a method to format the response.
      return shelf.Response.internalServerError(
        body: prettyJsonEncode(
          {
            'code': 500,
            'message': 'PROFILE_UPDATE_FAILED',
          },
        ),
      );
    }

    // Update successful.
    return shelf.Response.ok(
      prettyJsonEncode(
        {
          'code': 200,
          'message': 'PROFILE_UPDATED',
        },
      ),
    );
  }

  /// GET /getProfile
  ///
  Future<shelf.Response> getProfileHandler(shelf.Request request) async {
    var authorizationHeader = request.headers['authorization'];

    // Authorization header is missing.
    if (authorizationHeader == null) {
      return AuthResponse.badRequest('Authorization header is missing');
    }

    // Check authorization header for the Bearer token.
    var authType = authorizationHeader.split(' ')[0];

    // Bearer token is missing. Unsupported authentication type provided.
    if (authType != 'Bearer') {
      return shelf.Response.badRequest(
        body: prettyJsonEncode(
          {
            'code': 400,
            'message':
                'Unsupported authentication type. Only Bearer Auth is supported '
                    'with idToken for this endpoint.',
          },
        ),
      );
    }

    // The authorization type is Bearer. Get the idToken.
    var idToken = authorizationHeader.split(' ')[1];

    // Check if the token is valid.
    bool tokenIsValid = verifyJwt(idToken);

    if (!tokenIsValid) {
      // Token is invalid.
      return shelf.Response.unauthorized(
        prettyJsonEncode(
          {
            'code': 401,
            'message': 'TOKEN_INVALID',
          },
        ),
      );
    }

    // Token is valid. Get the user's profile.
    final result = await _authenticatedClient.post(
      Uri.parse(getUserDataUrl),
      body: {'idToken': idToken},
    );

    // Get profile not successful.
    if (result.statusCode != 200) {
      shelf.Response.internalServerError(
        body: prettyJsonEncode(
          {
            'code': 500,
            'message': 'GET_PROFILE_FAILED',
          },
        ),
      );
    }

    // Get profile successful.
    return shelf.Response.ok(
      prettyJsonEncode(
        {
          'code': 200,
          'message': 'PROFILE_RETRIEVED',
          'userData':
              AuthUser.fromFirebaseGetProfileResponse(jsonDecode(result.body))
                  .toMap(),
        },
      ),
    );
  }

  /// GET /
  ///
  /// Serves README.md as the main page.
  Future<shelf.Response> getReadmeHandler(shelf.Request request) async {
    var readmeFile = File('README.md');
    var readmeMarkdown = await readmeFile.readAsString();
    var readmeHtml = md.markdownToHtml(readmeMarkdown);
    return shelf.Response.ok(
      readmeHtml,
      headers: {'Content-Type': 'text/html'},
    );

    // return shelf.Response.ok(readme);
  }

  /// Calls another handler function and returns the response.
  // Future<shelf.Response> _callHandler(
  //   shelf.Request request,
  //   shelf.Handler handler,
  // ) async {
  //   try {
  //     return await handler(request);
  //   } on shelf.HijackException catch (e) {
  //     rethrow;
  //   } catch (e, st) {
  //     print('Error: $e

  /// Sets up the [Router] and defines the request handlers.
  void _setupRouter() {
    this._router = (shelf_router.Router())
      ..post('/login', loginWithEmailAndPasswordHandler)
      ..post('/loginAnonymously', loginAnonymouslyHandler)
      ..post('/signup', signUpWithEmailAndPasswordHandler)
      ..post('/updateProfile', updateProfileHandler)
      ..get('/verifyIdToken', verifyIdTokenHandler)
      ..get('/db', _firestoreRepository.incrementHandler)
      ..get('/issues', _firestoreRepository.getIssuesHandler)
      ..get('/getProfile', getProfileHandler)
      ..get('/', getReadmeHandler);
  }
}
