import 'dart:convert';

abstract class SerializationException implements Exception {}

/// {@template encoding_exception}
/// Thrown when a [Map] cannot be converted to a [T] object.
/// {@endtemplate}
class EncodingException<T> implements SerializationException {
  final String? message;
  Object? object;

  /// {@macro encoding_exception}
  EncodingException({this.message, this.object});

  @override
  String toString() {
    var error = runtimeType.toString();
    if (T != dynamic) error += '<$T>';
    if (message != null) error += ': $message';
    if (object != null) error += "Object was: \n${json.encode(object)}";

    return error;
  }
}

/// {@template decoding_exception}
/// An exception thrown when decoding fails.
/// {@endtemplate}
class DecodingException implements SerializationException {
  final String? message;
  Object? object;

  /// {@macro decoding_exception}
  DecodingException({this.message, this.object});

  @override
  String toString() {
    var error = runtimeType.toString();
    if (message != null) error += ': $message';
    if (object != null) error += "Object was: \n${json.encode(object)}";
    return error;
  }
}

class InvalidAuthUserException extends DecodingException {
  InvalidAuthUserException({super.message, super.object});
}
