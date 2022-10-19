// ignore_for_file: public_member_api_docs, sort_constructors_first, no_leading_underscores_for_local_identifiers
// String? uuid = Uuid().v4();
// AppUser? creator;
// DateTime? creationDate;
// DateTime? dueDate;
// String? title;
// String? description;
// Label? label;
// List<AppUser>? assignedUsers;

import 'dart:convert';

import 'package:googleapis/firestore/v1.dart';
import 'package:sample_auth_server/exceptions/exceptions.dart';
import 'package:sample_auth_server/models/auth_user.dart';
import 'package:sample_auth_server/models/label.dart';
import 'package:sample_auth_server/models/responses/payload.dart';

class Issue extends Payload {
  String? uuid;
  AuthUser? creator;
  DateTime? creationDate;
  DateTime? dueDate;
  String? title;
  String? description;
  List<AuthUser>? assignedUsers;
  Label? label;
  Issue({
    this.uuid,
    this.creator,
    this.creationDate,
    this.dueDate,
    this.title,
    this.description,
    this.assignedUsers,
    this.label,
  });

  @override
  Map<String, dynamic> toMap() {
    try {
      // var map = <String, dynamic>{};

      // if (uuid != null) map['uuid'] = uuid;
      // if (creator != null) map['creator'] = creator!.toMap();
      // if (creationDate != null) map['creationDate'] = creationDate;
      // if (dueDate != null) map['dueDate'] = dueDate;
      // if (title != null) map['title'] = title;
      // if (description != null) map['description'] = description;
      // if (assignedUsers != null) {
      //   map['assignedUsers'] = assignedUsers!.map((e) => e.toMap()).toList();
      // }
      // if (label != null) map['label'] = label!.toMap();

      // return map;

      return <String, dynamic>{
        'uuid': uuid,
        'creator': creator?.toMap(),
        'creationDate': creationDate?.millisecondsSinceEpoch,
        'dueDate': dueDate?.millisecondsSinceEpoch,
        'title': title,
        'description': description,
        'assignedUsers': assignedUsers?.map((x) => x.toMap()).toList(),
        'label': label?.toMap(),
      };
    } catch (e) {
      var message = 'Error while converting Issue to Map: $e';
      throw EncodingException(message: message, object: this);
    }
  }

  factory Issue.fromMap(Map<String, dynamic> map) {
    return Issue(
      uuid: map['uuid'] != null ? map['uuid'] as String : null,
      creator: map['creator'] != null
          ? AuthUser.fromMap(map['creator'] as Map<String, dynamic>)
          : null,
      creationDate: map['creationDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['creationDate'] as int)
          : null,
      dueDate: map['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'] as int)
          : null,
      title: map['title'] != null ? map['title'] as String : null,
      description:
          map['description'] != null ? map['description'] as String : null,
      assignedUsers: map['assignedUsers'] != null
          ? List<AuthUser>.from(
              map['assignedUsers'].map((user) => AuthUser.fromMap(user)))
          : null,
      // assignedUsers: map['assignedUsers'] != null
      //     ? List<AuthUser>.from(
      //         (map['assignedUsers'] as List<int>).map<AuthUser?>(
      //           (x) => AuthUser.fromMap(x as Map<String, dynamic>),
      //         ),
      //       )
      //     : null,
      label: map['label'] != null
          ? Label.fromMap(map['label'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  String toJson() {
    try {
      return json.encode(toMap());
    } catch (e) {
      var message = 'Error while converting Issue to JSON: $e';
      throw EncodingException(message: message, object: this);
    }
  }

  factory Issue.fromJson(String source) =>
      Issue.fromMap(json.decode(source) as Map<String, dynamic>);

  factory Issue.fromFirestoreDocument(Map<String, dynamic> map) {
    Issue? issue;

    try {
      final fields = map['fields'] as Map<String, dynamic>;
      final _uuid = (map['name'] as String?)?.split('/').last;
      // title is in format: {stringValue: 'title_of_issue'}, with a single entry.
      final _title = (fields['title'] as Map<String, dynamic>?)
          ?.entries
          .single
          .value as String?;
      // description is in format: {stringValue: 'description_of_issue'}, with a
      // single entry.
      final _description = (fields['description'] as Map<String, dynamic>?)
          ?.entries
          .single
          .value as String?;

      // dueDate is in format: {timestampValue: '2021-08-01T00:00:00.000000Z'},
      // with a single entry.
      //
      // Note that we need to convert the timestampValue to a DateTime object.
      // final _dueDateAsDateTime = _dueDate != null ? DateTime.parse(_dueDate) : null;

      final _dueDateAsString = (fields['dueDate'] as Map<String, dynamic>?)
          ?.entries
          .single
          .value as String?;
      final _dueDate =
          _dueDateAsString != null ? DateTime.parse(_dueDateAsString) : null;

      final creationDateAsString =
          (fields['creationDate'] as Map<String, dynamic>?)
              ?.entries
              .single
              .value as String?;
      final creationDate = creationDateAsString != null
          ? DateTime.parse(creationDateAsString)
          : null;
      // label is in format:
      // ```json
      // {
      //    "mapValue":{
      //       "fields":{
      //          "uuid":{
      //             "stringValue":"uuid"
      //          },
      //          "name":{
      //             "stringValue":"name"
      //          },
      //          "description":{
      //             "stringValue":"description"
      //          },
      //          "color":{
      //             "stringValue":"EB4034"
      //          }
      //       }
      //    }
      // }
      //
      //
      final _labelMap = (fields['label'] as Map<String, dynamic>?)
          ?.entries
          .single
          .value as Map<String, dynamic>?;

      // 'fields' map for the label
      final _label =
          _labelMap != null ? Label.fromFirestoreRestResponse(_labelMap) : null;

      final _creatorMap = (fields['creator'] as Map<String, dynamic>?)
          ?.entries
          .single
          .value as Map<String, dynamic>?;

      final creator = _creatorMap != null
          ? AuthUser.fromFirestoreDocument(
              _creatorMap,
              getIDToken: true,
            )
          : null;

      // `assignedUsers` key is in format:

      // ```json
      // "assignedUsers": {
      //   "arrayValue": {
      //     "values": [
      //       {
      //         "mapValue": {
      //           "fields": {
      //             "email": {
      //               "stringValue": "a@a.ca"
      //             },
      //             "isGuest": {
      //               "booleanValue": false
      //             },
      //             "username": {
      //               "stringValue": "allo"
      //             },
      //             "uid": {
      //               "stringValue": "123"
      //             },
      //             "sample_null_value": {
      //               "nullValue": null
      //             },
      //             "idToken": {
      //               "stringValue": "12345"
      //             }
      //           }
      //         }
      //       }
      //     ]
      //   }
      // }
      // ```
      final _assignedUsersMap =
          (fields['assignedUsers'] as Map<String, dynamic>?)
              ?.entries
              .single
              .value as Map<String, dynamic>?;

      final _assignedUsers = _assignedUsersMap != null
          ? List<AuthUser>.from(
              (_assignedUsersMap['values'] as List<dynamic>).map<AuthUser?>(
                (x) => AuthUser.fromFirestoreDocument(
                  x['mapValue'] as Map<String, dynamic>,
                  getIDToken: true,
                ),
              ),
            )
          : null;

      issue = Issue()
        ..uuid = _uuid
        ..title = _title
        ..description = _description
        ..dueDate = _dueDate
        ..label = _label
        ..creator = creator
        ..creationDate = creationDate
        ..assignedUsers = _assignedUsers;
    } catch (e) {
      var exception = DecodingException(
        message:
            'Error decoding issue from firestore document : ${e.toString()}',
        object: map,
      );

      print(exception);
      throw exception;
    }
    return issue;
  }

  /// To firestore [Document]
  ///
  /// Note that we need to convert the [DateTime] object to a [Timestamp] object.

  // Map<String, dynamic> toFirestoreFields() {
  //   return {
  //     'title': {'stringValue': title},
  //     'description': {'stringValue': description},
  //     'dueDate': {'timestampValue': dueDate?.toIso8601String()},
  //     'label': {'mapValue': label?.toFirestoreFields()},
  //     'creator': {'mapValue': creator?.toFirestoreFields()},
  //     'creationDate': {'timestampValue': creationDate?.toIso8601String()},
  //     'assignedUsers': {
  //       'arrayValue': {
  //         'values': assignedUsers
  //             ?.map((e) => {'mapValue': e.toFirestoreFields()})
  //             .toList()
  //       }
  //     },
  //   };
  // }

  // Document toFirestoreDocument() {
  //   return Document(
  //     name: 'projects/$projectId/databases/(default)/documents/issues/$uuid',
  //     fields: {
  //       'title': {
  //         'stringValue': title,
  //       },
  //       'description': {
  //         'stringValue': description,
  //       },
  //       'dueDate': {
  //         'timestampValue': Timestamp.fromDate(dueDate!),
  //       },
  //       'label': {
  //         'mapValue': label!.toFirestoreDocument().fields,
  //       },
  //       'creator': {
  //         'mapValue': creator!.toFirestoreDocument().fields,
  //       },
  //       'creationDate': {
  //         'timestampValue': Timestamp.fromDate(creationDate!),
  //       },
  //       'assignedUsers': {
  //         'arrayValue': {
  //           'values': assignedUsers!.map(
  //             (user) {
  //               return {
  //                 'mapValue': user.toFirestoreDocument().fields,
  //               };
  //             },
  //           ).toList(),
  //         },
  //       },
  //     },
  //   );
  // }
}
