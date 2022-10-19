// ignore_for_file: unnecessary_this

import 'dart:convert';

import 'package:sample_auth_server/helpers.dart';
import 'package:sample_auth_server/models/firebase_auth_error.dart';
import 'package:sample_auth_server/models/responses/response_body.dart';

/// The response body for a failed database request with 400 status code.
class BadDatabaseRequestResponseBody extends ResponseBody {
  static const String kBadRequest = 'BAD_REQUEST';
  final String errorDescription;

  BadDatabaseRequestResponseBody({String? errorDescription})
      : this.errorDescription = errorDescription ?? kBadRequest,
        super(
          statusCode: 400,
          defaultMessage: kBadRequest,
        );

  BadDatabaseRequestResponseBody copyWith({
    int? statusCode,
    String? message,
    String? errorDescription,
  }) {
    return BadDatabaseRequestResponseBody(
      errorDescription: errorDescription ?? this.errorDescription,
    );
  }

  @override
  Map<String, dynamic> toMap() =>
      super.toMap()..addAll({'error': errorDescription});

  factory BadDatabaseRequestResponseBody.fromMap(Map<String, dynamic> map) {
    return BadDatabaseRequestResponseBody(
      errorDescription: map['error'] as String,
    );
  }

  @override
  String toJson() => prettyJsonEncode(toMap());

  factory BadDatabaseRequestResponseBody.fromJson(String source) =>
      BadDatabaseRequestResponseBody.fromMap(
          json.decode(source) as Map<String, dynamic>);

  factory BadDatabaseRequestResponseBody.fromFirebaseErrorJson(String source) {
    FirebaseAuthError firebaseAuthError = FirebaseAuthError.fromJson(source);

    var errorMsg = firebaseAuthError.message;
    if (errorMsg == null) return BadDatabaseRequestResponseBody();

    return BadDatabaseRequestResponseBody(
      errorDescription: errorMsg,
    );
  }

  @override
  String toString() =>
      '${runtimeType.toString}(errorDescription: $errorDescription)';

  @override
  bool operator ==(covariant BadDatabaseRequestResponseBody other) {
    if (identical(this, other)) return true;

    return other.errorDescription == errorDescription &&
        other.statusCode == statusCode &&
        other.defaultMessage == defaultMessage;
  }

  @override
  int get hashCode =>
      errorDescription.hashCode ^ statusCode.hashCode ^ defaultMessage.hashCode;
}
