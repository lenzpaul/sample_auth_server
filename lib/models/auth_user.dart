// ignore_for_file: public_member_api_docs, sort_constructors_first, unnecessary_this
import 'dart:convert';

import 'package:sample_auth_server/exceptions/exceptions.dart';
import 'package:sample_auth_server/models/models.dart';

/// Represents a user on the server.
///
/// The encoded [AuthUser] is returned to the client when required, e.g. when a
/// user logs in or signs up.
///
/// The encoding is done in [AuthResponseBody] and its subclasses.
class AuthUser {
  final String uuid;
  final String? email;
  final String? username;

  /// JWT token for the user. We use this to authenticate the user after they
  /// have logged in.
  final String? idToken;

  /// Whether the user is logged in anonymously.
  final bool? isGuest;

  AuthUser({
    required this.uuid,
    this.email,
    this.username,
    this.idToken,
    this.isGuest = false,
  });

  AuthUser copyWith({
    String? uuid,
    String? email,
    String? username,
    String? idToken,
    bool? isGuest,
  }) {
    return AuthUser(
      uuid: uuid ?? this.uuid,
      email: email ?? this.email,
      username: username ?? this.username,
      isGuest: isGuest ?? this.isGuest,
      idToken: idToken ?? this.idToken,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uuid': uuid,
      'email': email,
      'username': username,
      'idToken': idToken,
      'isGuest': isGuest,
    };
  }

  factory AuthUser.fromMap(Map<String, dynamic> map) {
    if (map.isEmpty) {
      throw InvalidAuthUserException(message: 'Map is empty');
    }

    if (map['uuid'] == null) {
      throw InvalidAuthUserException(
        message: 'Map does not contain a uuid',
        object: map,
      );
    }

    try {
      return AuthUser(
        uuid: map['uuid'],
        email: map['email'],
        username: map['username'],
        idToken: map['idToken'],
        isGuest: map['isGuest'],
      );
    } catch (e) {
      throw InvalidAuthUserException(
        message: 'Error while creating AuthUser from map',
        object: map,
      );
    }
  }

  factory AuthUser.fromJson(String source) =>
      AuthUser.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'AuthUser(uuid: $uuid, email: $email, username: $username, isGuest: $isGuest';
    // ', idToken: $idToken)';
  }

  @override
  bool operator ==(covariant AuthUser other) {
    if (identical(this, other)) return true;

    return other.uuid == uuid;
    // && other.email == email &&
    //     other.username == username &&
    //     other.isGuest == isGuest;
  }

  @override
  int get hashCode {
    return uuid.hashCode;
    // return uuid.hashCode ^ email.hashCode ^ username.hashCode ^ isGuest.hashCode;
  }

  /// Create a user from the Firebase Auth 'Get User Data' endpoint (`/lookup`)
  /// response.
  ///
  /// See:
  /// https://firebase.google.com/docs/reference/rest/auth#section-get-account-info
  factory AuthUser.fromFirebaseGetProfileResponse(Map<String, dynamic> map) {
    var userData = map['users'][0];

    return AuthUser(
      uuid: userData['localId'] as String,
      email: userData['email'],
      username: userData['displayName'],
      // TODO: Verify that this is the correct field to use for anonymous users.
      isGuest: userData['providerUserInfo'][0]['providerId'] == 'anonymous',
    );
  }

  /// Create a user from a firestore document.
  factory AuthUser.fromFirestoreDocument(Map<String, dynamic> map,
      {bool getIDToken = false}) {
    Map<String, dynamic>? fields = map['fields'];

    if (fields == null) {
      var exception = DecodingException(
        message: 'The firestore document does not have a "fields" key.',
      );

      print(exception);
      throw exception;
    }

    AuthUser? user;

    try {
      user = AuthUser(
        uuid: fields['uuid']?['stringValue'] as String,
        email: fields['email']?['stringValue'],
        username: fields['username']?['stringValue'],
        isGuest: fields['isGuest']?['booleanValue'],
        idToken: getIDToken ? (fields['idToken']?['stringValue']) : null,
      );
    } catch (e) {
      var exception = DecodingException(
        message: 'Failed to decode firestore document for $AuthUser type with '
            'the following error: $e',
      );

      print(exception);
      throw exception;
    }
    return user;
  }

  // Tojson
  String toJson() => jsonEncode(toMap());
}
