// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:sample_auth_server/helpers.dart';

/// Represents a user on the server.
class AuthUser {
  final String uid;
  final String? email;
  final String? username;

  /// JWT token for the user. We use this to authenticate the user after they
  /// have logged in.
  final String? idToken;

  /// Whether the user is logged in anonymously.
  final bool? isGuest;

  AuthUser({
    required this.uid,
    this.email,
    this.username,
    this.idToken,
    this.isGuest = false,
  });

  AuthUser copyWith({
    String? uid,
    String? email,
    String? username,
    String? idToken,
    bool? isGuest,
  }) {
    return AuthUser(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      isGuest: isGuest ?? this.isGuest,
      idToken: idToken ?? this.idToken,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uid': uid,
      'email': email,
      'username': username,
      'idToken': idToken,
      'isGuest': isGuest,
    };
  }

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    return AuthUser(
      uid: map['uid'] as String,
      email: map['email'],
      username: map['username'],
      idToken: map['idToken'],
      isGuest: map['isGuest'],
    );
  }

  factory AuthUser.fromJson(String source) =>
      AuthUser.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AuthUser(uid: $uid, email: $email, username: $username, isGuest: $isGuest';
    // ', idToken: $idToken)';
  }

  @override
  bool operator ==(covariant AuthUser other) {
    if (identical(this, other)) return true;

    return other.uid == uid;
    // && other.email == email &&
    //     other.username == username &&
    //     other.isGuest == isGuest;
  }

  @override
  int get hashCode {
    return uid.hashCode;
    // return uid.hashCode ^ email.hashCode ^ username.hashCode ^ isGuest.hashCode;
  }

  /// Create a user from the Firebase Auth 'Get User Data' endpoint (`/lookup`)
  /// response.
  ///
  /// See:
  /// https://firebase.google.com/docs/reference/rest/auth#section-get-account-info
  factory AuthUser.fromFirebaseGetProfileResponse(Map<String, dynamic> map) {
    var userData = map['users'][0];

    return AuthUser(
      uid: userData['localId'] as String,
      email: userData['email'],
      username: userData['displayName'],
      // TODO: Verify that this is the correct field to use for anonymous users.
      isGuest: userData['providerUserInfo'][0]['providerId'] == 'anonymous',
    );
  }

  // Tojson
  String toJson() => jsonEncode(toMap());
}
