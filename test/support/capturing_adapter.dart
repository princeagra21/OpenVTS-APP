import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// A tiny HttpClientAdapter that captures the last [RequestOptions] passed into Dio.
///
/// This avoids network calls in unit tests and lets us assert headers/paths.
class CapturingAdapter implements HttpClientAdapter {
  RequestOptions? lastRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;

    // Always return 200 with empty JSON.
    final bytes = utf8.encode(jsonEncode(<String, dynamic>{}));
    return ResponseBody.fromBytes(
      bytes,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
