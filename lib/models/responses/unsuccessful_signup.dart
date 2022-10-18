// ignore_for_file: unnecessary_this

import 'dart:convert';

import 'package:sample_auth_server/helpers.dart';
import 'package:sample_auth_server/models/responses/auth_response_body.dart';

/// The response body for a failed login.
///
/// Format:
/// ```json
/// {
///   "code": 401,
///   "message": "SIGNUP_FAILED",
///   "error": "Invalid email or password"
/// }
/// ```
class UnsuccessfulSignup extends AuthResponseBody {
  static const String _defaultErrorMessage = 'SIGNUP_FAILED';
  final String errorDescription;

  UnsuccessfulSignup({String? errorDescription})
      : this.errorDescription = errorDescription ?? _defaultErrorMessage,
        super(
          statusCode: 401,
          kDefaultMessage: _defaultErrorMessage,
        );

  UnsuccessfulSignup copyWith({
    int? statusCode,
    String? message,
    String? errorDescription,
  }) {
    return UnsuccessfulSignup(
      errorDescription: errorDescription ?? this.errorDescription,
    );
  }

  @override
  Map<String, dynamic> toMap() => super.toMap()
    ..addAll({
      'error': errorDescription,
    });

  factory UnsuccessfulSignup.fromMap(Map<String, dynamic> map) {
    return UnsuccessfulSignup(
      errorDescription: map['error'] as String,
    );
  }

  String toJson() => prettyJsonEncode(toMap());

  factory UnsuccessfulSignup.fromJson(String source) =>
      UnsuccessfulSignup.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'UnsuccessfulSignup(errorDescription: $errorDescription)';

  @override
  bool operator ==(covariant UnsuccessfulSignup other) {
    if (identical(this, other)) return true;

    return other.errorDescription == errorDescription &&
        other.statusCode == statusCode &&
        other.kDefaultMessage == kDefaultMessage;
  }

  @override
  int get hashCode => errorDescription.hashCode;

  /// The response body for a failed login.
  ///
  /// Here we provide details about the error (e.g. invalid email or password).
  ///
  /// Sample Firebase Error Response:
  /// ```json
  /// {
  ///     "error": {
  ///         "code": 400,
  ///         "message": "INVALID_PASSWORD",
  ///         "errors": [
  ///             {
  ///                 "message": "INVALID_PASSWORD",
  ///                 "domain": "global",
  ///                 "reason": "invalid"
  ///             }
  ///         ]
  ///     }
  /// }
  /// ```
  factory UnsuccessfulSignup.fromFirebaseError(Object firebaseError) {
    var msg = json.decode(firebaseError.toString())['error']['message'];
    return UnsuccessfulSignup(errorDescription: msg);
  }
}
