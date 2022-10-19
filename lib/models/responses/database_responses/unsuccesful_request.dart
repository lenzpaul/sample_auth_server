// ignore_for_file: unnecessary_this

import 'dart:convert';

import 'package:sample_auth_server/helpers.dart';
import 'package:sample_auth_server/models/responses/auth_responses/auth_response_body.dart';

/// The response body for a failed database request.
///
/// Format:
/// ```json
/// {
///   "code": 401,
///   "message": "UNAUTHORIZED"",
///   "error": "Reason for failure"
/// }
/// ```
class UnsuccessfulRequest extends AuthResponseBody {
  static const String kUnauthorizedRequestMSg = 'UNAUTHORIZED';
  final String errorDescription;

  UnsuccessfulRequest({String? errorDescription})
      : this.errorDescription = errorDescription ?? kUnauthorizedRequestMSg,
        super(
          statusCode: 401,
          defaultMessage: kUnauthorizedRequestMSg,
        );

  UnsuccessfulRequest copyWith({
    int? statusCode,
    String? message,
    String? errorDescription,
  }) {
    return UnsuccessfulRequest(
      errorDescription: errorDescription ?? this.errorDescription,
    );
  }

  @override
  Map<String, dynamic> toMap() => super.toMap()
    ..addAll({
      'error': errorDescription,
    });

  factory UnsuccessfulRequest.fromMap(Map<String, dynamic> map) {
    return UnsuccessfulRequest(
      errorDescription: map['error'] as String,
    );
  }

  @override
  String toJson() => prettyJsonEncode(toMap());

  factory UnsuccessfulRequest.fromJson(String source) =>
      UnsuccessfulRequest.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      '${runtimeType.toString()}(errorDescription: $errorDescription)';

  @override
  bool operator ==(covariant UnsuccessfulRequest other) {
    if (identical(this, other)) return true;

    return other.errorDescription == errorDescription &&
        other.statusCode == statusCode &&
        other.defaultMessage == defaultMessage;
  }

  @override
  int get hashCode => errorDescription.hashCode;
}
