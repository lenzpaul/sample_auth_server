import 'dart:convert';

import 'package:sample_auth_server/helpers.dart';

/// Represents a user on the server.
class AuthUser {
  final String uid;
  final String email;
  final String username;

  /// Whether the user is logged in anonymously.
  final bool isGuest;
  AuthUser({
    required this.uid,
    required this.email,
    required this.username,
    required this.isGuest,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'email': email,
      'username': username,
      'isGuest': isGuest,
    };
  }

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    return AuthUser(
      uid: map['uid'] as String,
      email: map['email'] as String,
      username: map['username'] as String,
      isGuest: map['isGuest'] as bool,
    );
  }

  String toJson() => prettyJsonEncode(toMap());

  factory AuthUser.fromJson(String source) =>
      AuthUser.fromMap(json.decode(source) as Map<String, dynamic>);
}
