import 'dart:convert';

import 'package:sample_auth_server/helpers.dart';
import 'package:sample_auth_server/models/auth_response_body.dart';

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

  String toJson() => prettyJsonEncode(toMap());

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
