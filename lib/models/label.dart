// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:sample_auth_server/exceptions/exceptions.dart';
import 'package:sample_auth_server/logger.dart';

class Label {
  String? uuid;
  String? name;
  String? description;

  /// The color of the label. This is a hex color code.
  String? color;
  Label({
    this.uuid,
    this.name,
    this.description,
    this.color,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'uuid': uuid,
      'name': name,
      'description': description,
      'color': color,
    };
  }

  factory Label.fromMap(Map<String, dynamic> map) {
    return Label(
      uuid: map['uuid'] != null ? map['uuid'] as String : null,
      name: map['name'] != null ? map['name'] as String : null,
      description:
          map['description'] != null ? map['description'] as String : null,
      color: map['color'] != null ? map['color'] as String : null,
    );
  }

  /// This creates a new label from a JSON response from firestore's REST API.
  ///
  /// The Firestore REST API response looks like this:
  ///
  ///```json
  /// {
  ///   "fields":{
  ///      "name":{
  ///         "stringValue":"urgent"
  ///      },
  ///      "color":{
  ///         "stringValue":"EB4034"
  ///      },
  ///      "uuid":{
  ///         "stringValue":"123456A"
  ///      },
  ///      "description":{
  ///         "stringValue":"issues that are urgent"
  ///      }
  ///   }
  /// }
  ///```
  factory Label.fromFirestoreRestResponse(Map<String, dynamic> map) {
    Map<String, dynamic>? fields = map['fields'];

    Label? label;

    try {
      label = Label(
        uuid: fields?['uuid']?['stringValue'] as String?,
        name: fields?['name']?['stringValue'] as String?,
        description: fields?['description']?['stringValue'] as String?,
        color: fields?['color']?['stringValue'] as String?,
      );
    } catch (e) {
      var exception = DecodingException(message: e.toString());
      ServerLogger.log(exception.toString(), level: ServerLogLevel.error);
      throw exception;
    }

    return label;
  }

  String toJson() => json.encode(toMap());

  factory Label.fromJson(String source) =>
      Label.fromMap(json.decode(source) as Map<String, dynamic>);
}
