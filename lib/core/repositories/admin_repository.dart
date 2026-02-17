import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/result.dart';
import 'package:http_parser/http_parser.dart';

class AdminRepository {
  final ApiClient api;

  AdminRepository({required this.api});

  /// Multipart upload stub (protected):
  /// POST `/admin/upload` with `type` and `file`.
  ///
  /// UI should provide `bytes`+`filename` (e.g., via `file_picker`) to avoid `dart:io`
  /// and keep this compatible with mobile + web builds.
  ///
  /// See `lib/core/utils/file_picker_helper.dart` for a small helper you can use.
  Future<Result<Object?>> uploadAdminFile({
    required String type,
    required Uint8List bytes,
    required String filename,
    String? contentType,
    CancelToken? cancelToken,
  }) async {
    final MediaType? mediaType =
        (contentType == null || contentType.trim().isEmpty)
        ? null
        : MediaType.parse(contentType);

    final form = FormData.fromMap({
      'type': type,
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: mediaType,
      ),
    });

    final res = await api.post(
      '/admin/upload',
      data: form,
      cancelToken: cancelToken,
      options: Options(
        contentType: 'multipart/form-data',
        headers: const {
          // Let Dio set boundaries; keep JSON headers out for multipart.
          'Accept': 'application/json',
        },
      ),
    );

    return res.when(
      success: (data) => Result.ok(data),
      failure: (err) => Result.fail(err),
    );
  }
}
