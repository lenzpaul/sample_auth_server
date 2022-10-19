// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sample_auth_server/models/responses/response_body.dart';

/// {@template payload}
/// A payload contained in a [ResponseBody].
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
