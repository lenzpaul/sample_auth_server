import 'dart:io';

/// Utility to get commonly used headers for this server.
class HeadersUtil {
  HeadersUtil._();

  /// {'Content-Type': 'application/json'},
  static Map<String, String> contentTypeJson = {
    HttpHeaders.contentTypeHeader: ContentType.json.toString()
  };

  /// {"authorization": "Bearer $token"}
  static Map<String, String> bearerAuthorizationHeader(String token) {
    return Map<String, String>.from(
        {HttpHeaders.authorizationHeader: "Bearer $token"});
  }

  static Map<String, Object> addAll(List<Map<String, Object>> headerMaps) {
    Map<String, Object> m = {};
    for (final map in headerMaps) {
      map.forEach((key, value) {
        m[key] = value;
      });
    }
    return m;
  }
}
