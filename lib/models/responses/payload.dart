// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sample_auth_server/models/issue.dart';
import 'package:sample_auth_server/models/responses/response_body.dart';

/// {@template payload}
/// A payload contained in a [ResponseBody].
///
/// A [Payload] represents the data sent back to the client, and is serializable
/// to JSON.
///
/// An example of a [Payload] is an [Issue].
/// {@endtemplate}
abstract class Payload {
  Payload();

  Map<String, dynamic> toMap();

  String toJson();

  factory Payload.fromMap(Map<String, dynamic> map) {
    // Child classes will implement this
    throw UnimplementedError();
  }

  factory Payload.fromJson(String source) {
    // Child classes will implement this
    throw UnimplementedError();
  }
}
