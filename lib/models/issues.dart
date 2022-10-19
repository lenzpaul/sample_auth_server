import 'dart:collection';
import 'dart:convert';

import 'package:sample_auth_server/models/issue.dart';
import 'package:sample_auth_server/models/responses/payload.dart';

/// {@template issues}
/// A convenience wrapper for a list of [Issue]s.
///
/// Includes a method to convert the list of [Issue]s to a [Payload].
///
/// [toJson] returns a JSON representation of the list of [Issue]s in the
/// [Payload] object under the `issues` key.
/// {@endtemplate}
class Issues extends Payload with ListMixin<Issue> {
  /// {@macro issues}
  Issues({List<Issue>? list}) : _list = list ?? <Issue>[];

  List<Issue> _list;

  // @override
  // void add(Issue element) => _list.add(element);

  /// Convert the list of [Issue]s to a JSON string.
  ///
  /// ```json
  /// {
  ///   "issues": [
  ///     {
  ///       "title": "1",
  ///       "description": "1",
  ///       ...
  ///     },
  ///     {
  ///      "title": "2",
  ///      "description": "2",
  ///      ...
  ///     }
  ///   ]
  /// }
  /// ```
  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'issues': _list.map((Issue x) => x.toMap()).toList(),
    };
  }

  /// Convert the list of [Issue]s to a JSON string.
  @override
  String toJson() {
    return jsonEncode(toMap());
  }

  @override
  void add(Issue element) => _list.add(element);

  @override
  int get length => _list.length;

  @override
  set length(int newLength) => _list.length = newLength;

  @override
  Issue operator [](int index) => _list[index];

  @override
  void operator []=(int index, Issue value) => _list[index] = value;
}
