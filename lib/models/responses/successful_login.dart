import 'dart:convert';

import 'package:sample_auth_server/helpers.dart';
import 'package:sample_auth_server/models/responses/auth_response_body.dart';
import 'package:sample_auth_server/models/auth_user.dart';

/// {@template successful_login}
/// A successful login response body.
///
/// Contains a [AuthUser] on successful login.
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
/// {@endtemplate}
class SuccessfulLogin extends AuthResponseBody {
  final AuthUser userData;

  /// {@macro successful_login}
  SuccessfulLogin({
    String message = 'LOGIN_SUCCESS',
    required this.userData,
  }) : super(statusCode: 200, kDefaultMessage: message);

  @override
  Map<String, dynamic> toMap() => super.toMap()
    ..addAll({
      'userData': userData.toMap(),
    });

  factory SuccessfulLogin.fromMap(Map<String, dynamic> map) {
    String? message = map['message'];
    return SuccessfulLogin(
      message: message ?? 'LOGIN_SUCCESS',
      userData: AuthUser.fromMap(map['userData'] as Map<String, dynamic>),
    );
  }

  String toJson() => prettyJsonEncode(toMap());

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
