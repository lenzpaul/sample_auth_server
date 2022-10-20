// ignore_for_file: public_member_api_docs, sort_constructors_first, unnecessary_this
import 'dart:convert';

import 'package:sample_auth_server/models/responses/database_responses/bad_request.dart';
import 'package:sample_auth_server/models/responses/database_responses/succesful_request.dart';
import 'package:sample_auth_server/models/responses/database_responses/unsuccesful_request.dart';
import 'package:sample_auth_server/models/responses/payload.dart';
import 'package:sample_auth_server/models/responses/response_body.dart';
import 'package:shelf/shelf.dart' as shelf;

/// A [shelf.Response] sent back to the client. It contains a [ResponseBody] as
/// its body. The [ResponseBody] contains a [Payload]  object, as the `payload`
/// key. See [SuccessfulRequest], as an example of a [Payload].
///
/// Ther server responds with a 200 status code on successfull request, 401 on
/// unauthorised request, and 400 on bad request.
///
///
/// An unsuccessful login response contains an error message as an `error` key,
/// see [UnsuccessfulRequest].
class DatabaseResponse extends shelf.Response {
  /// The body of the response.
  ///
  /// It contains a [ResponseBody] which we can call
  /// [ResponseBody.toMap] on.
  final ResponseBody body;

  DatabaseResponse._({required this.body, int statusCode = 200})
      : super(
          statusCode,
          body: body.toJson(),
          headers: {'Content-Type': 'application/json'},
          encoding: utf8,
        );

  factory DatabaseResponse.successfulRequest(
      {Payload? payload, String? message}) {
    return DatabaseResponse._(
      body: SuccessfulRequest(
        message: message,
        payload: payload,
      ),
      statusCode: 200,
    );
  }

  factory DatabaseResponse.unsuccessfulRequest({
    String? errorMessage,
    String? errorDescription,
  }) {
    return DatabaseResponse._(
      body: BadDatabaseRequestResponseBody(
        errorMessage: errorMessage,
        errorDescription: errorDescription,
      ),
      statusCode: 400,
    );
  }

  factory DatabaseResponse.unauthorisedRequest(String errorDescription) {
    return DatabaseResponse._(
      body: UnsuccessfulRequest(
        errorDescription: errorDescription,
      ),
      statusCode: 401,
    );
  }
}
