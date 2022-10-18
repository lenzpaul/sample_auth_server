// ignore_for_file: unnecessary_this

import 'dart:convert';

import 'package:sample_auth_server/helpers.dart';
import 'package:sample_auth_server/models/responses/auth_response_body.dart';
import 'package:sample_auth_server/models/firebase_auth_error.dart';

class BadRequestResponseBody extends AuthResponseBody {
  static const String kBadRequest = 'BAD_REQUEST';
  final String errorDescription;

  BadRequestResponseBody({String? errorDescription})
      : this.errorDescription = errorDescription ?? kBadRequest,
        super(
          statusCode: 400,
          kDefaultMessage: kBadRequest,
        );

  BadRequestResponseBody copyWith({
    int? statusCode,
    String? message,
    String? errorDescription,
  }) {
    return BadRequestResponseBody(
      errorDescription: errorDescription ?? this.errorDescription,
    );
  }

  @override
  Map<String, dynamic> toMap() =>
      super.toMap()..addAll({'error': errorDescription});

  factory BadRequestResponseBody.fromMap(Map<String, dynamic> map) {
    return BadRequestResponseBody(
      errorDescription: map['error'] as String,
    );
  }

  String toJson() => prettyJsonEncode(toMap());

  factory BadRequestResponseBody.fromJson(String source) =>
      BadRequestResponseBody.fromMap(
          json.decode(source) as Map<String, dynamic>);

  factory BadRequestResponseBody.fromFirebaseErrorJson(String source) {
    FirebaseAuthError firebaseAuthError = FirebaseAuthError.fromJson(source);

    var errorMsg = firebaseAuthError.message;
    if (errorMsg == null) return BadRequestResponseBody();

    return BadRequestResponseBody(
      errorDescription: errorMsg,
    );
  }

  @override
  String toString() =>
      'BadRequestResponseBody(errorDescription: $errorDescription)';

  @override
  bool operator ==(covariant BadRequestResponseBody other) {
    if (identical(this, other)) return true;

    return other.errorDescription == errorDescription &&
        other.statusCode == statusCode &&
        other.kDefaultMessage == kDefaultMessage;
  }

  @override
  int get hashCode =>
      errorDescription.hashCode ^
      statusCode.hashCode ^
      kDefaultMessage.hashCode;
}
