// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: unnecessary_this

import 'dart:convert';

/// An error response from the Firebase Authentication API.
///
/// See https://firebase.google.com/docs/reference/rest/auth#section-error-response
///
/// e.g.:
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
class FirebaseAuthError {
  int? code;
  String? message;
  List<Error>? errors;

  FirebaseAuthError({
    this.code,
    this.message,
    this.errors,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'code': code,
      'message': message,
      'errors': errors?.map((x) => x.toMap()).toList(),
    };
  }

  factory FirebaseAuthError.fromMap(Map<String, dynamic> map) {
    var data = map['error'] as Map<String, dynamic>;
    return FirebaseAuthError(
      code: data['code'],
      message: data['message'],
      errors: data['errors'] != null
          ? List<Error>.from(data['errors']?.map((x) => Error.fromMap(x)))
          : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory FirebaseAuthError.fromJson(String source) =>
      FirebaseAuthError.fromMap(json.decode(source) as Map<String, dynamic>);
}

class Error {
  String? message;
  String? domain;
  String? reason;

  Error({
    this.message,
    this.domain,
    this.reason,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'message': message,
      'domain': domain,
      'reason': reason,
    };
  }

  factory Error.fromMap(Map<String, dynamic> map) {
    return Error(
      message: map['message'],
      domain: map['domain'],
      reason: map['reason'],
    );
  }

  String toJson() => json.encode(toMap());

  factory Error.fromJson(String source) =>
      Error.fromMap(json.decode(source) as Map<String, dynamic>);
}
