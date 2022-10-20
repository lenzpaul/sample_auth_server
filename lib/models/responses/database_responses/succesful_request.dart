import 'dart:convert';

import 'package:sample_auth_server/helpers.dart';
import 'package:sample_auth_server/models/responses/payload.dart';
import 'package:sample_auth_server/models/responses/response_body.dart';

/// {@template successful_request}
/// A successful database request response body.
///
/// Contains an optional [Payload] on success of a database request.
///
/// Format:
/// ```json
/// {
///   code: 200,
///   message: "SUCCESS",
///   payload: {
///    ...
///   }
/// }
/// ```
/// {@endtemplate}
class SuccessfulRequest extends ResponseBody {
  final Payload? payload;
  final String? message;

  /// {@macro successful_request}
  SuccessfulRequest({
    this.message,
    this.payload,
  }) : super(
          statusCode: 200,
          defaultMessage: message ?? 'SUCCESS',
        );

  @override
  Map<String, dynamic> toMap() {
    if (payload == null) {
      return super.toMap();
    } else {
      return super.toMap()
        ..addAll({
          'payload': payload!.toMap(),
        });
    }
  }

  factory SuccessfulRequest.fromMap(Map<String, dynamic> map) {
    String? message = map['message'];
    return SuccessfulRequest(
      message: message ?? 'SUCCESS',
      payload: map['payload'] ? Payload.fromMap(map['payload']) : null,
    );
  }

  @override
  String toJson() => prettyJsonEncode(toMap());

  factory SuccessfulRequest.fromJson(String source) =>
      SuccessfulRequest.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => '${runtimeType.toString()}(payload: $payload)';
}
