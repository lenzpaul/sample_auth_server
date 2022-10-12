// ignore_for_file: public_member_api_docs, sort_constructors_first, unnecessary_this
import 'dart:convert';
import 'dart:io';

import 'package:sample_auth_server/helpers.dart';
import 'package:sample_auth_server/models/auth_user.dart';
import 'package:sample_auth_server/models/bad_request.dart';
import 'package:sample_auth_server/models/successful_login.dart';
import 'package:sample_auth_server/models/unsuccesful_login.dart';
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
  AuthResponse.loginSuccesful(AuthUser user)
      : super.ok(
          SuccessfulLogin(userData: user).toJson(),
          encoding: utf8,
          headers: jsonContentTypeHeader,
        );

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
  AuthResponse.signUpSuccesful(AuthUser user)
      : super.ok(
          // TODO: Add SignUpResponse
          SuccessfulLogin(userData: user).toJson(),
          encoding: utf8,
          headers: jsonContentTypeHeader,
        );

  AuthResponse.loginFailed({String? errorDescription})
      : super.unauthorized(
          UnsuccessfulLogin(errorDescription: errorDescription).toJson(),
          encoding: utf8,
          headers: jsonContentTypeHeader,
        );

  /// Fail the login with a 401 status code and details about the error
  /// extracted from the [firebaseErrorResponseBody].
  AuthResponse.failedWithFirebaseResponseBody(Object firebaseErrorResponseBody)
      : super.unauthorized(
          UnsuccessfulLogin.fromFirebaseError(firebaseErrorResponseBody)
              .toJson(),
          encoding: utf8,
          headers: jsonContentTypeHeader,
        );

  /// Bad request, with a 400 status code and details about the error if any.
  AuthResponse.badRequest([String? errorDescription])
      : super.badRequest(
          body: BadRequestResponseBody(
            errorDescription: errorDescription,
          ).toJson(),
          encoding: utf8,
          headers: jsonContentTypeHeader,
        );
}
