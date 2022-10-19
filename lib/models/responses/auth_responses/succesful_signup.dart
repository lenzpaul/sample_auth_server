import 'dart:convert';

import 'package:sample_auth_server/helpers.dart';
import 'package:sample_auth_server/models/responses/auth_responses/auth_response_body.dart';
import 'package:sample_auth_server/models/auth_user.dart';

class SuccessfulSignup extends AuthResponseBody {
  final AuthUser userData;
  static const String _defaultSuccessMessage = 'SIGNUP_SUCCESS';

  SuccessfulSignup({
    required this.userData,
    String message = 'SIGNUP_SUCCESS',
  }) : super(statusCode: 200, defaultMessage: message);

  @override
  Map<String, dynamic> toMap() => super.toMap()
    ..addAll({
      'userData': userData.toMap(),
    });

  factory SuccessfulSignup.fromMap(Map<String, dynamic> map) {
    return SuccessfulSignup(
      message: map['message'] ?? _defaultSuccessMessage,
      userData: AuthUser.fromMap(map['userData'] as Map<String, dynamic>),
    );
  }

  @override
  String toJson() => prettyJsonEncode(toMap());

  factory SuccessfulSignup.fromJson(String source) =>
      SuccessfulSignup.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'SuccesfulSignup(userData: $userData)';
}
