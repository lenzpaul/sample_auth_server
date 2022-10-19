import 'package:sample_auth_server/models/models.dart';
import 'package:sample_auth_server/models/responses/response_body.dart';

/// Body of the [AuthResponse] sent back to the client.
///
/// Contains a [AuthUser] on successful login.
///
/// Contains an error message on failed login.
abstract class AuthResponseBody extends ResponseBody {
  AuthResponseBody({required super.statusCode, required super.defaultMessage});
}
