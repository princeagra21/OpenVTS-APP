import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';

class AdminAccountRawDto {
  const AdminAccountRawDto(this.json);

  final Map<String, Object?> json;

  factory AdminAccountRawDto.fromJson(Map<String, Object?> json) {
    return AdminAccountRawDto(Map<String, Object?>.unmodifiable(json));
  }
}

class UpdateAdminUserStatusRequestDto {
  const UpdateAdminUserStatusRequestDto({required this.isActive});

  final bool isActive;

  Map<String, Object?> toJson() => <String, Object?>{'isActive': isActive};
}

class UpdateAdminPasswordRequestDto {
  const UpdateAdminPasswordRequestDto({
    required this.currentPassword,
    required this.newPassword,
  });

  final String currentPassword;
  final String newPassword;

  Map<String, Object?> toJson() => <String, Object?>{
        'currentPassword': currentPassword.trim(),
        'newPassword': newPassword.trim(),
      };
}

class UpdateAdminUserPasswordRequestDto {
  const UpdateAdminUserPasswordRequestDto({required this.newPassword});

  final String newPassword;

  Map<String, Object?> toJson() => <String, Object?>{
        'newPassword': newPassword,
      };
}

class AdminOtpRequestDto {
  const AdminOtpRequestDto({this.otp});

  final String? otp;

  Map<String, Object?> toJson() => <String, Object?>{
        if (otp != null) 'otp': otp!.trim(),
      };
}

class AdminProfileUpdateRequestDto {
  const AdminProfileUpdateRequestDto(this.values);

  final Map<String, Object?> values;

  Map<String, Object?> toJson() => Map<String, Object?>.from(values);
}

class AdminCompanyUpdateRequestDto {
  const AdminCompanyUpdateRequestDto(this.values);

  final Map<String, Object?> values;

  Map<String, Object?> toJson() => Map<String, Object?>.from(values);
}

class AdminAssignVehicleRequestDto {
  const AdminAssignVehicleRequestDto({required this.userId});

  final String userId;

  Map<String, Object?> toJson() => <String, Object?>{
        'userId': int.tryParse(userId.trim()) ?? userId.trim(),
      };
}

class AdminRenewVehiclesRequestDto {
  const AdminRenewVehiclesRequestDto({
    required this.userId,
    required this.vehicleIds,
    required this.paymentMode,
  });

  final String userId;
  final List<int> vehicleIds;
  final String paymentMode;

  Map<String, Object?> toJson() => <String, Object?>{
        'userId': int.tryParse(userId.trim()) ?? userId.trim(),
        'vehicleIds': vehicleIds,
        'paymentMode': paymentMode,
      };
}

class AdminUploadFileRequestDto {
  const AdminUploadFileRequestDto({
    required this.type,
    required this.bytes,
    required this.filename,
    this.contentType,
  });

  final String type;
  final Uint8List bytes;
  final String filename;
  final String? contentType;

  FormData toFormData() {
    final mediaType = contentType == null || contentType!.trim().isEmpty
        ? null
        : MediaType.parse(contentType!.trim());
    return FormData.fromMap(<String, dynamic>{
      'type': type,
      'file': MultipartFile.fromBytes(
        bytes,
        filename: filename,
        contentType: mediaType,
      ),
    });
  }
}

class AdminUploadDocumentRequestDto {
  const AdminUploadDocumentRequestDto({
    required this.associateType,
    required this.associateId,
    required this.docTypeId,
    required this.title,
    required this.fileBytes,
    required this.filename,
    this.description,
    this.tags,
    this.expiryAt,
    this.isVisible = true,
    this.contentType,
  });

  final String associateType;
  final String associateId;
  final int docTypeId;
  final String title;
  final Uint8List fileBytes;
  final String filename;
  final String? description;
  final String? tags;
  final String? expiryAt;
  final bool isVisible;
  final String? contentType;

  FormData toFormData() {
    final mediaType = contentType == null || contentType!.trim().isEmpty
        ? null
        : MediaType.parse(contentType!.trim());
    return FormData.fromMap(<String, dynamic>{
      'title': title,
      'docTypeId': docTypeId.toString(),
      'description': description?.trim().isNotEmpty == true ? description!.trim() : '',
      'tags': tags?.trim().isNotEmpty == true ? tags!.trim() : '',
      'AssociateType': associateType,
      'associateId': associateId,
      if (expiryAt != null && expiryAt!.trim().isNotEmpty) 'expiryAt': expiryAt,
      'isVisible': isVisible,
      'File': MultipartFile.fromBytes(
        fileBytes,
        filename: filename,
        contentType: mediaType,
      ),
    });
  }
}

class AdminUpdateDocumentRequestDto {
  const AdminUpdateDocumentRequestDto({
    this.docTypeId,
    this.title,
    this.description,
    this.tags,
    this.expiryAt,
    this.isVisible,
    this.fileBytes,
    this.filename,
    this.contentType,
  });

  final int? docTypeId;
  final String? title;
  final String? description;
  final String? tags;
  final String? expiryAt;
  final bool? isVisible;
  final Uint8List? fileBytes;
  final String? filename;
  final String? contentType;

  FormData toFormData() {
    final mediaType = contentType == null || contentType!.trim().isEmpty
        ? null
        : MediaType.parse(contentType!.trim());
    return FormData.fromMap(<String, dynamic>{
      if (title != null) 'title': title!.trim(),
      if (docTypeId != null) 'docTypeId': docTypeId.toString(),
      if (description != null) 'description': description!.trim(),
      if (tags != null) 'tags': tags!.trim(),
      if (expiryAt != null && expiryAt!.trim().isNotEmpty) 'expiryAt': expiryAt,
      if (isVisible != null) 'isVisible': isVisible,
      if (fileBytes != null && filename != null)
        'File': MultipartFile.fromBytes(
          fileBytes!,
          filename: filename!,
          contentType: mediaType,
        ),
    });
  }
}
