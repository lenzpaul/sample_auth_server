import 'dart:convert';

abstract class SerializationException implements Exception {}

class EncodingException implements SerializationException {
  final String? message;

  EncodingException({this.message});

  @override
  String toString() {
    var error = runtimeType.toString();
    if (message != null) error += ': $message';
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
