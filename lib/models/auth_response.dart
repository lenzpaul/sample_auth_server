// ignore_for_file: public_member_api_docs, sort_constructors_first, unnecessary_this
import 'dart:convert';
import 'dart:io';

import 'package:sample_auth_server/helpers.dart';
import 'package:sample_auth_server/models/models.dart';

import 'package:shelf/shelf.dart' as shelf;

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
  // AuthResponse._();

  /// The body of the response.
  ///
  /// It contains a [AuthResponseBody] which we can call
  /// [AuthResponseBody.toMap] on.
  final AuthResponseBody body;

  AuthResponse._({required this.body, int statusCode = 200})
      : super(
          statusCode,
          body: body.toJson(),
          headers: {'Content-Type': 'application/json'},
          encoding: utf8,
        );

  factory AuthResponse.loginSuccesful(AuthUser user) {
    return AuthResponse._(
      body: SuccessfulLogin(userData: user),
      statusCode: 200,
    );
  }

  /// Successful signup response, with a 200 status code and details about the
  /// user.
  ///
  /// ```json
  /// {
  ///   code: 200,
  ///   message: "SIGNUP_SUCCESS",
  ///   userData: {
  ///     'uid': 'xxxxx',
  ///     'email': email@email.ca',
  ///     'username': 'a',
  ///     'isGuest': false
  ///   }
  /// }
  ///
  factory AuthResponse.signUpSuccesful(AuthUser user) {
    return AuthResponse._(
      body: SuccessfulSignup(userData: user),
      statusCode: 200,
    );
  }

  factory AuthResponse.loginFailed({String? errorDescription}) {
    return AuthResponse._(
      body: UnsuccessfulLogin(
        errorDescription: errorDescription,
      ),
      statusCode: 401,
    );
  }

  /// Fail the login with a 401 status code and details about the error
  /// extracted from the [firebaseErrorResponseBody].
  factory AuthResponse.failedWithFirebaseResponseBody(
    String firebaseErrorResponseBody,
  ) {
    return AuthResponse._(
      body: UnsuccessfulLogin(
        errorDescription: FirebaseAuthError.fromJson(
          firebaseErrorResponseBody,
        ).message,
      ),
      statusCode: 401,
    );
  }
  // : super.unauthorized(
  //     UnsuccessfulLogin.fromFirebaseError(firebaseErrorResponseBody)
  //         .toJson(),
  //     encoding: utf8,
  //     headers: jsonContentTypeHeader,
  //   );

  /// Bad request, with a 400 status code and details about the error if any.
  factory AuthResponse.badRequest([String? errorDescription]) {
    return AuthResponse._(
      body: BadRequestResponseBody(
        errorDescription: errorDescription,
      ),
      statusCode: 400,
    );
  }

  /// Badly formatted request, with a 400 status code and details about the
  /// error.
  factory AuthResponse.signUpFailed([String? errorDescription]) {
    return AuthResponse._(
      body: UnsuccessfulSignup(
        errorDescription: errorDescription,
      ),
      statusCode: 400,
    );
  }

  /// Create a response from a [FirebaseAuthError] json.
  factory AuthResponse.signupFailedFromFirebaseResponse(
      String firebaseErrorJsonResponseBody) {
    return AuthResponse._(
      body: UnsuccessfulSignup(
        errorDescription: FirebaseAuthError.fromJson(
          firebaseErrorJsonResponseBody,
        ).message,
      ),
      statusCode: 400,
    );
  }
}
