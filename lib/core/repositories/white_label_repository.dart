import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fleet_stack/core/models/white_label_branding.dart';
import 'package:fleet_stack/core/network/result.dart';
import 'package:fleet_stack/core/network/api_client.dart';

class WhiteLabelRepository {
  final ApiClient api;

  const WhiteLabelRepository({required this.api});

  // Postman-confirmed endpoints:
  // - GET /superadmin/whitelabel
  // - PATCH /superadmin/whitelabel (form-data keys: customDomain, primaryColor,
  //   logoLightUrl, logoDarkUrl, faviconUrl)
  // - POST /superadmin/upload/2 (form-data keys: type, file)

  Future<Result<WhiteLabelBranding>> getWhiteLabelBranding({
    CancelToken? cancelToken,
  }) async {
    final res = await api.get(
      '/superadmin/whitelabel',
      cancelToken: cancelToken,
    );
    return res.when(
      success: (data) {
        final map = _extractMap(data);
        return Result.ok(WhiteLabelBranding(map));
      },
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<WhiteLabelBranding>> updateWhiteLabelBranding({
    required String customDomain,
    String? primaryColor,
    String? faviconUrl,
    String? logoLightUrl,
    String? logoDarkUrl,
    CancelToken? cancelToken,
  }) async {
    final fields = <String, dynamic>{
      'customDomain': customDomain,
      if (primaryColor != null && primaryColor.trim().isNotEmpty)
        'primaryColor': primaryColor,
      if (logoLightUrl != null && logoLightUrl.trim().isNotEmpty)
        'logoLightUrl': logoLightUrl,
      if (logoDarkUrl != null && logoDarkUrl.trim().isNotEmpty)
        'logoDarkUrl': logoDarkUrl,
      if (faviconUrl != null && faviconUrl.trim().isNotEmpty)
        'faviconUrl': faviconUrl,
    };

    final res = await api.patch(
      '/superadmin/whitelabel',
      data: FormData.fromMap(fields),
      cancelToken: cancelToken,
      options: Options(contentType: 'multipart/form-data'),
    );
    return res.when(
      success: (data) => Result.ok(WhiteLabelBranding(_extractMap(data))),
      failure: (err) => Result.fail(err),
    );
  }

  Future<Result<String>> uploadBrandAsset({
    required String type,
    required Uint8List bytes,
    required String filename,
    CancelToken? cancelToken,
  }) async {
    final form = FormData.fromMap({
      'type': type,
      'file': MultipartFile.fromBytes(bytes, filename: filename),
    });

    final res = await api.post(
      '/superadmin/upload/2',
      data: form,
      cancelToken: cancelToken,
      options: Options(contentType: 'multipart/form-data'),
    );

    return res.when(
      success: (data) {
        final map = _extractMap(data);
        final url = _s(
          map['url'] ??
              map['fileUrl'] ??
              map['path'] ??
              map['location'] ??
              map['data'],
        );
        return Result.ok(url);
      },
      failure: (err) => Result.fail(err),
    );
  }

  Map<String, dynamic> _extractMap(Object? data) {
    if (data is Map<String, dynamic>) {
      final nested = data['data'];
      if (nested is Map<String, dynamic>) return nested;
      if (nested is Map) return Map<String, dynamic>.from(nested.cast());
      return data;
    }
    if (data is Map) return Map<String, dynamic>.from(data.cast());
    return const <String, dynamic>{};
  }

  String _s(Object? v) => v == null ? '' : v.toString();
}
