import 'dart:convert';

abstract class SerializationException implements Exception {}

class EncodingException implements SerializationException {
  final String? message;

  Object? object;
  EncodingException({this.message, this.object});

  @override
  String toString() {
    var error = runtimeType.toString();
    if (message != null) error += ': $message';
    if (object != null) error += "Object was: \n${json.encode(object)}";

    return error;
  }
}

class DecodingException implements SerializationException {
  final String? message;
  Object? object;

  DecodingException({this.message, this.object});

  @override
  String toString() {
    var error = runtimeType.toString();
    if (message != null) error += ': $message';
    if (object != null) error += "Object was: \n${json.encode(object)}";
    return error;
  }
}
