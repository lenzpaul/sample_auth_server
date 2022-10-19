import 'package:sample_auth_server/helpers.dart';

/// The body of a response sent back to the client.
class ResponseBody {
  ResponseBody({
    required this.statusCode,
    required this.defaultMessage,
  });

  final int statusCode;
  final String defaultMessage;

  Map<String, dynamic> toMap() {
    return {
      'code': statusCode,
      'message': defaultMessage,
    };
  }

  String toJson() => prettyJsonEncode(toMap());
}
