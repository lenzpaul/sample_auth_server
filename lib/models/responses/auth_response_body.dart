import 'package:sample_auth_server/helpers.dart';
import 'package:sample_auth_server/models/models.dart';

/// Body of the [AuthResponse] object.
///
/// Contains a [AuthUser] on successful login.
///
/// Contains an error message on failed login.
abstract class AuthResponseBody {
  AuthResponseBody({
    required this.statusCode,
    required this.kDefaultMessage,
  });
  final int statusCode;
  final String kDefaultMessage;

  Map<String, dynamic> toMap() {
    return {
      'code': statusCode,
      'message': kDefaultMessage,
    };
  }

  String toJson() => prettyJsonEncode(toMap());
}
