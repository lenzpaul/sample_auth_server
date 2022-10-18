// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dotenv/dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as shelf_io;

/// Serves [handler] on [InternetAddress.anyIPv4] using the port returned by
/// [listenPort].
///
/// The returned [Future] will complete using [terminateRequestFuture] after
/// closing the server.
Future<void> serveHandler(shelf.Handler handler) async {
  final port = listenPort();

  final server = await shelf_io.serve(
    handler,
    InternetAddress.anyIPv4, // Allows external connections
    port,
  );
  print('Serving at http://${server.address.host}:${server.port}');

  await terminateRequestFuture();

  await server.close();
}

/// Returns the port to listen on from environment variable or uses the default
/// `8080`.
///
/// See https://cloud.google.com/run/docs/reference/container-contract#port
int listenPort() => int.parse(getEnvVar('PORT') ?? '8080');

/// Returns a [Future] that completes when the process receives a
/// [ProcessSignal] requesting a shutdown.
///
/// [ProcessSignal.sigint] is listened to on all platforms.
///
/// [ProcessSignal.sigterm] is listened to on all platforms except Windows.
Future<void> terminateRequestFuture() {
  final completer = Completer<bool>.sync();

  // sigIntSub is copied below to avoid a race condition - ignoring this lint
  // ignore: cancel_subscriptions
  StreamSubscription? sigIntSub, sigTermSub;

  Future<void> signalHandler(ProcessSignal signal) async {
    print('Received signal $signal - closing');

    final subCopy = sigIntSub;
    if (subCopy != null) {
      sigIntSub = null;
      await subCopy.cancel();
      sigIntSub = null;
      if (sigTermSub != null) {
        await sigTermSub!.cancel();
        sigTermSub = null;
      }
      completer.complete(true);
    }
  }

  sigIntSub = ProcessSignal.sigint.watch().listen(signalHandler);

  // SIGTERM is not supported on Windows. Attempting to register a SIGTERM
  // handler raises an exception.
  if (!Platform.isWindows) {
    sigTermSub = ProcessSignal.sigterm.watch().listen(signalHandler);
  }

  return completer.future;
}

/// Returns a [Future] that completes with the
/// [Project ID](https://cloud.google.com/resource-manager/docs/creating-managing-projects#identifying_projects)
/// for the current Google Cloud Project.
///
/// First, if an environment variable with a name in
/// [gcpProjectIdEnvironmentVariables] exists, that is returned.
/// (The list is checked in order.) This is useful for local development.
///
/// If no such environment variable exists, then we assume the code is running
/// on Google Cloud and
/// [Project metadata](https://cloud.google.com/compute/docs/metadata/default-metadata-values#project_metadata)
/// is queried for the Project ID.
Future<String> currentProjectId() async {
  for (var envKey in gcpProjectIdEnvironmentVariables) {
    // final value = Platform.environment[envKey];
    final value = getEnvVar(envKey);
    if (value != null) return value;
  }
  const host = 'http://metadata.google.internal/';
  final url = Uri.parse('$host/computeMetadata/v1/project/project-id');

  try {
    final response = await http.get(
      url,
      headers: {'Metadata-Flavor': 'Google'},
    );

    if (response.statusCode != 200) {
      throw HttpException(
        '${response.body} (${response.statusCode})',
        uri: url,
      );
    }

    return response.body;
  } on SocketException {
    stderr.writeln(
      '''
Could not connect to $host.
If not running on Google Cloud, one of these environment variables must be set
to the target Google Project ID:
${gcpProjectIdEnvironmentVariables.join('\n')}
''',
    );
    rethrow;
  }
}

/// A set of typical environment variables that are likely to represent the
/// current Google Cloud project ID.
///
/// For context, see:
/// * https://cloud.google.com/functions/docs/env-var
/// * https://cloud.google.com/compute/docs/gcloud-compute#default_project
/// * https://github.com/GoogleContainerTools/gcp-auth-webhook/blob/08136ca171fe5713cc70ef822c911fbd3a1707f5/server.go#L38-L44
///
/// Note: these are ordered starting from the most current/canonical to least.
/// (At least as could be determined at the time of writing.)
const gcpProjectIdEnvironmentVariables = {
  'GCP_PROJECT',
  'GCLOUD_PROJECT',
  'CLOUDSDK_CORE_PROJECT',
  'GOOGLE_CLOUD_PROJECT',
};

/// Returns the value of the environment variable with the given [key].
///
/// If [useDotEnv] is `true`, we use the `dotenv` package to load the value from
/// the `.env` file if it exists. This is useful for local development and
/// debugging in VS Code, for example.
String? getEnvVar(String key, {useDotEnv = false}) {
  // [isInDebugMode] is  `true` when debugging in VS Code.
  //
  // VS Code does not easily support loading environment variables. So when
  // debugging in VS Code, we use the dotenv package to load the environment
  // variables from the .env file, if it exists.
  if (useDotEnv || isInDebugMode) {
    var env = DotEnv(includePlatformEnvironment: true)..load();
    return env[key];
  }

  return Platform.environment[key];
}

/// Checks if Dart is running in debug mode. Useful for debugging in VS Code,
/// for example.
///
/// Evaluates to `true` if running in debug mode in VS Code.
///
/// Evaluates to `false` in *most* other cases.
///
/// * VS Code `debug`: `true`
/// * VS Code `run`: `false`
/// * `dart run`: `false`
/// * `dart run --no-enable-asserts`: `false`
/// * `dart run --enable-asserts`: `true`
/// * `dart compile exe`: `false`
bool get isInDebugMode {
  // Assume we're in production mode
  bool _inDebugMode = false;

  // Assert expressions are only evaluated during development. They are ignored
  // in production. Therefore, this code will only turn `inDebugMode` to true
  // in our development environments!
  assert(_inDebugMode = true);

  // if (_inDebugMode) {
  //   print('isInDebugMode: Running in debug mode');
  // } else {
  //   print('isInDebugMode: Running in release mode');
  // }

  return _inDebugMode;
}

/// Checks if Dart is running in debug mode. Similar to [isInDebugMode].
///
/// * VS Code `debug`: `true`
/// * VS Code `run`: `true`
/// * `dart run`: `true`
/// * `dart run --no-enable-asserts`: `true`
/// * `dart run --enable-asserts`: `true`
/// * `dart compile exe`: `false`
bool get runningInDebugMode {
  bool _isReleaseMode = bool.fromEnvironment('dart.vm.product');
  // // Check if dart is running in debug mode
  // if (_isReleaseMode) {
  //   print('runningInDebugMode: Running in release mode');
  // } else {
  //   print('runningInDebugMode: Running in debug mode');
  // }
  return !_isReleaseMode;
}

/// Encode the [object] as multiline JSON with 2 space indentation.
String prettyJsonEncode(Object? object) =>
    JsonEncoder.withIndent(' ').convert(object).trim();

/// 'content-type': 'application/json',
Map<String, String> get jsonContentTypeHeader => {
      HttpHeaders.contentTypeHeader: ContentType.json.toString(),
    };

/// Decode a JWT token and return the payload.
Map<String, dynamic> decodeJwt(String token) {
  Map<String, dynamic> tokenMap = JwtDecoder.decode(token);

  print('tokenMap: ${prettyJsonEncode(tokenMap)}');

  return tokenMap;
}

/// Check if the JWT token is expired.
bool isJwtExpired(String token) => JwtDecoder.isExpired(token);

// TODO: Helper method to Verify the JWT token using the public key
// from the JWKS endpoint.

// See:
// * https://firebase.google.com/docs/auth/admin/verify-id-tokens#verify_id_tokens_using_a_third-party_jwt_library
// * https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com
// 'iss' should == 'https://securetoken.google.com/$_projectId'
/// Verify the JWT token.
///
/// Returns `true` if the token is valid.
///
///
/// Currently, this method only verifies whether the token is expired.
bool verifyJwt(String token) {
  bool tokenIsValid = false;

  try {
    tokenIsValid = !isJwtExpired(token);
  } catch (e) {
    print('verifyJwt: Error: $e');
    tokenIsValid = false;
  }

  return tokenIsValid;
}
