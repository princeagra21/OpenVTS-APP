import 'dart:typed_data';

import 'package:open_vts/core/utils/request_control.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_document_type.dart';
import 'package:open_vts/core/api/legacy_transport_provider.dart';
import 'package:open_vts/core/api/api_result.dart';
import 'package:open_vts/features/admin/data/repositories/admin_users_repository.dart';
import 'package:open_vts/features/superadmin/data/repositories/superadmin_repository.dart';

abstract class DocumentRepositoryAdapter {
  Future<Result<List<SuperadminDocumentType>>> getDocumentTypes({
    CancelToken? cancelToken,
  });

  Future<Result<void>> uploadDocument({
    required String associateType,
    required String associateId,
    required int docTypeId,
    required String title,
    required Uint8List fileBytes,
    required String filename,
    String? description,
    String? tags,
    String? expiryAt,
    bool isVisible,
    String? contentType,
    CancelToken? cancelToken,
  });

  Future<Result<void>> updateDocument({
    required String documentId,
    int? docTypeId,
    String? title,
    String? description,
    String? tags,
    String? expiryAt,
    bool? isVisible,
    Uint8List? fileBytes,
    String? filename,
    String? contentType,
    CancelToken? cancelToken,
  });
}

class AdminDocumentRepositoryAdapter implements DocumentRepositoryAdapter {
  AdminDocumentRepositoryAdapter({dynamic api})
    : _repo = AdminUsersRepository(api: api ?? sharedLegacyTransport());

  final AdminUsersRepository _repo;

  @override
  Future<Result<List<SuperadminDocumentType>>> getDocumentTypes({
    CancelToken? cancelToken,
  }) {
    return _repo.getDocumentTypes(cancelToken: cancelToken);
  }

  @override
  Future<Result<void>> uploadDocument({
    required String associateType,
    required String associateId,
    required int docTypeId,
    required String title,
    required Uint8List fileBytes,
    required String filename,
    String? description,
    String? tags,
    String? expiryAt,
    bool isVisible = true,
    String? contentType,
    CancelToken? cancelToken,
  }) {
    return _repo.uploadDocument(
      associateType: associateType,
      associateId: associateId,
      docTypeId: docTypeId,
      title: title,
      fileBytes: fileBytes,
      filename: filename,
      description: description,
      tags: tags,
      expiryAt: expiryAt,
      isVisible: isVisible,
      contentType: contentType,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Result<void>> updateDocument({
    required String documentId,
    int? docTypeId,
    String? title,
    String? description,
    String? tags,
    String? expiryAt,
    bool? isVisible,
    Uint8List? fileBytes,
    String? filename,
    String? contentType,
    CancelToken? cancelToken,
  }) {
    return _repo.updateDocument(
      documentId: documentId,
      docTypeId: docTypeId,
      title: title,
      description: description,
      tags: tags,
      expiryAt: expiryAt,
      isVisible: isVisible,
      fileBytes: fileBytes,
      filename: filename,
      contentType: contentType,
      cancelToken: cancelToken,
    );
  }
}

class SuperadminDocumentRepositoryAdapter implements DocumentRepositoryAdapter {
  SuperadminDocumentRepositoryAdapter({dynamic api})
    : _repo = SuperadminRepository(api: api ?? sharedLegacyTransport());

  final SuperadminRepository _repo;

  @override
  Future<Result<List<SuperadminDocumentType>>> getDocumentTypes({
    CancelToken? cancelToken,
  }) {
    return _repo.getDocumentTypes(cancelToken: cancelToken);
  }

  @override
  Future<Result<void>> uploadDocument({
    required String associateType,
    required String associateId,
    required int docTypeId,
    required String title,
    required Uint8List fileBytes,
    required String filename,
    String? description,
    String? tags,
    String? expiryAt,
    bool isVisible = true,
    String? contentType,
    CancelToken? cancelToken,
  }) {
    return _repo.uploadDocument(
      associateType: associateType,
      associateId: associateId,
      docTypeId: docTypeId,
      title: title,
      fileBytes: fileBytes,
      filename: filename,
      description: description,
      tags: tags,
      expiryAt: expiryAt,
      isVisible: isVisible,
      contentType: contentType,
      cancelToken: cancelToken,
    );
  }

  @override
  Future<Result<void>> updateDocument({
    required String documentId,
    int? docTypeId,
    String? title,
    String? description,
    String? tags,
    String? expiryAt,
    bool? isVisible,
    Uint8List? fileBytes,
    String? filename,
    String? contentType,
    CancelToken? cancelToken,
  }) {
    return _repo.updateDocument(
      documentId: documentId,
      docTypeId: docTypeId,
      title: title,
      description: description,
      tags: tags,
      expiryAt: expiryAt,
      isVisible: isVisible,
      fileBytes: fileBytes,
      filename: filename,
      contentType: contentType,
      cancelToken: cancelToken,
    );
  }
}
