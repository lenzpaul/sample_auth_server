import 'package:sample_auth_server/helpers.dart';

/// Body of the [AuthResponse] object.
///
/// Contains a [User] on successful login.
///
/// Contains an error message on failed login.
abstract class AuthResponseBody {
  AuthResponseBody({
    required this.statusCode,
    required this.message,
  });
  final int statusCode;
  final String message;

  Map<String, dynamic> toMap() {
    return {
      'code': statusCode,
      'message': message,
    };
  }

  String toJson() => prettyJsonEncode(toMap());
}
