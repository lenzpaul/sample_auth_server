// ignore_for_file: public_member_api_docs, sort_constructors_first, unnecessary_this
import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;

/// Encode the [object] as multiline JSON with 2 space indentation.
String _encode(Object? object) =>
    JsonEncoder.withIndent('  ').convert(object).trim();

/// Response sent back to the client. It contains a [AuthResponseBody].
///
/// Ther server responds with a 200 status code on successfull login. On an
/// unsuccessful login, the server responds with a 401.
///
/// A successful login response contains a [AuthUser] object, as a `userData`
/// key, see [SuccessfulLogin].
///
/// An unsuccessful login response contains an error message as an `error` key,
/// see [UnsuccessfulLogin].
class AuthResponse extends shelf.Response {
  AuthResponse.loginSuccesful(AuthUser user)
      : super.ok(SuccessfulLogin(userData: user).toJson());

  AuthResponse.loginFailed({String? errorDescription})
      : super.unauthorized(
          UnsuccessfulLogin(errorDescription: errorDescription).toJson(),
        );
}

/// Body of the [AuthResponse] object.
///
/// Contains a [User] on successful login.
///
/// Contains an error message on failed login.
abstract class AuthResponseBody {
  AuthResponseBody({
    required this.statusCode,
    required this.message,
  });
  final int statusCode;
  final String message;

  Map<String, dynamic> toMap() {
    return {
      'code': statusCode,
      'message': message,
    };
  }
}

/// Contains a [User] on successful login.
///
/// Format:
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
class SuccessfulLogin extends AuthResponseBody {
  final AuthUser userData;

  SuccessfulLogin({
    String message = 'LOGIN_SUCCESS',
    required this.userData,
  }) : super(statusCode: 200, message: message);

  SuccessfulLogin copyWith({
    AuthUser? userData,
  }) {
    return SuccessfulLogin(
      userData: userData ?? this.userData,
    );
  }

  @override
  Map<String, dynamic> toMap() => super.toMap()
    ..addAll({
      'userData': userData.toMap(),
    });

  factory SuccessfulLogin.fromMap(Map<String, dynamic> map) {
    return SuccessfulLogin(
      userData: AuthUser.fromMap(map['userData'] as Map<String, dynamic>),
    );
  }

  String toJson() => _encode(toMap());

  factory SuccessfulLogin.fromJson(String source) =>
      SuccessfulLogin.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'SuccessfulLogin(userData: $userData)';

  @override
  bool operator ==(covariant SuccessfulLogin other) {
    if (identical(this, other)) return true;

    return other.userData == userData;
  }

  @override
  int get hashCode => userData.hashCode;
}

/// The response body for a failed login.
///
/// Format:
/// ```json
/// {
///   "code": 401,
///   "message": "LOGIN_FAILED",
///   "error": "Invalid email or password"
/// }
/// ```
class UnsuccessfulLogin extends AuthResponseBody {
  static const String kLoginFailed = 'LOGIN_FAILED';
  final String errorDescription;

  UnsuccessfulLogin({String? errorDescription})
      : this.errorDescription = errorDescription ?? kLoginFailed,
        super(
          statusCode: 401,
          message: kLoginFailed,
        );

  UnsuccessfulLogin copyWith({
    int? statusCode,
    String? message,
    String? errorDescription,
  }) {
    return UnsuccessfulLogin(
      errorDescription: errorDescription ?? this.errorDescription,
    );
  }

  @override
  Map<String, dynamic> toMap() => super.toMap()
    ..addAll({
      'error': errorDescription,
    });

  factory UnsuccessfulLogin.fromMap(Map<String, dynamic> map) {
    return UnsuccessfulLogin(
      errorDescription: map['error'] as String,
    );
  }

  String toJson() => _encode(toMap());

  factory UnsuccessfulLogin.fromJson(String source) =>
      UnsuccessfulLogin.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'UnsuccessfulLogin(errorDescription: $errorDescription)';

  @override
  bool operator ==(covariant UnsuccessfulLogin other) {
    if (identical(this, other)) return true;

    return other.errorDescription == errorDescription &&
        other.statusCode == statusCode &&
        other.message == message;
  }

  @override
  int get hashCode => errorDescription.hashCode;
}

/// Represents a user on the server.
class AuthUser {
  final String uid;
  final String email;
  final String username;

  /// Whether the user is logged in anonymously.
  final bool isGuest;
  AuthUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.isGuest,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'email': email,
      'username': username,
      'isGuest': isGuest,
    };
  }

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    return AuthUser(
      uid: map['uid'] as String,
      email: map['email'] as String,
      username: map['username'] as String,
      isGuest: map['isGuest'] as bool,
    );
  }

  String toJson() => _encode(toMap());

  factory AuthUser.fromJson(String source) =>
      AuthUser.fromMap(json.decode(source) as Map<String, dynamic>);
}
