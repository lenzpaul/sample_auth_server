// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:sample_auth_server/helpers.dart';

/// Represents a user on the server.
class AuthUser {
  final String uid;
  final String? email;
  final String? username;

  /// Whether the user is logged in anonymously.
  final bool? isGuest;

  AuthUser({
    required this.uid,
    this.email,
    this.username,
    this.isGuest = false,
  });

  AuthUser copyWith({
    String? uid,
    String? email,
    String? username,
    bool? isGuest,
  }) {
    return AuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      isGuest: isGuest ?? this.isGuest,
    );
  }

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
      email: map['email'] != null ? map['email'] as String : null,
      username: map['username'] != null ? map['username'] as String : null,
      isGuest: map['isGuest'] != null ? map['isGuest'] as bool : null,
    );
  }

  factory AuthUser.fromJson(String source) =>
      AuthUser.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AuthUser(uid: $uid, email: $email, username: $username, isGuest: $isGuest)';
  }

  @override
  bool operator ==(covariant AuthUser other) {
    if (identical(this, other)) return true;

    return other.uid == uid &&
        other.email == email &&
        other.username == username &&
        other.isGuest == isGuest;
  }

  @override
  int get hashCode {
    return uid.hashCode ^ email.hashCode ^ username.hashCode ^ isGuest.hashCode;
  }
}
