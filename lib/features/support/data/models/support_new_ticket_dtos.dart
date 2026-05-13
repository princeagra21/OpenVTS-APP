import 'package:dio/dio.dart';
import 'package:open_vts/core/utils/file_picker_helper.dart';
import 'package:open_vts/features/support/domain/entities/support_models.dart';

class SupportAssigneeDto {
  const SupportAssigneeDto({
    required this.id,
    required this.name,
    required this.role,
    this.email,
    this.phone,
    this.subtitle,
  });

  final String id;
  final String name;
  final String role;
  final String? email;
  final String? phone;
  final String? subtitle;

  factory SupportAssigneeDto.fromJson(Map<String, dynamic> json) {
    final id = _s(
      json['id'] ??
          json['_id'] ??
          json['userId'] ??
          json['adminId'] ??
          json['uid'],
    );
    final name = _firstNonEmpty([
      json['name'],
      json['fullName'],
      json['displayName'],
      json['username'],
      json['email'],
      id,
    ]);
    final email = _nullable(json['email'] ?? json['emailAddress']);
    final phone = _nullable(json['phone'] ?? json['mobile'] ?? json['mobileNumber']);
    final role = _firstNonEmpty([json['role'], json['type'], '']);
    final subtitle = _nullable(json['companyName'] ?? json['subtitle'] ?? email ?? phone);
    return SupportAssigneeDto(
      id: id,
      name: name,
      role: role,
      email: email,
      phone: phone,
      subtitle: subtitle,
    );
  }
}

class SupportAssigneeListResponseDto {
  const SupportAssigneeListResponseDto(this.items);

  final List<SupportAssigneeDto> items;

  factory SupportAssigneeListResponseDto.fromJson(Object? json) {
    return SupportAssigneeListResponseDto(
      _extractList(json)
          .map((item) => SupportAssigneeDto.fromJson(_jsonMap(item)))
          .where((item) => item.id.isNotEmpty)
          .toList(),
    );
  }
}

class CreateSupportTicketRequestDto {
  const CreateSupportTicketRequestDto._(this.values);

  final Map<String, dynamic> values;

  factory CreateSupportTicketRequestDto.adminUserTicket(
    SupportCreateTicketDraft draft,
  ) {
    final userId = (draft.userId ?? '').trim();
    final title = draft.title.trim();
    return CreateSupportTicketRequestDto._(<String, dynamic>{
      'fromUserId': userId,
      'userId': userId,
      'title': title,
      'subject': title,
      'category': (draft.category ?? 'SERVER').trim(),
      'priority': (draft.priority ?? 'MEDIUM').trim(),
      'message': draft.message.trim(),
    });
  }

  factory CreateSupportTicketRequestDto.adminMyTicket(
    SupportCreateTicketDraft draft,
  ) {
    return CreateSupportTicketRequestDto._(<String, dynamic>{
      'title': draft.title.trim(),
      'category': (draft.category ?? 'SERVER').trim(),
      'priority': (draft.priority ?? 'MEDIUM').trim(),
      'message': draft.message.trim(),
    });
  }

  factory CreateSupportTicketRequestDto.userTicket(
    SupportCreateTicketDraft draft,
  ) {
    return CreateSupportTicketRequestDto._(<String, dynamic>{
      'title': draft.title.trim(),
      'category': (draft.category ?? 'GENERAL').trim(),
      'priority': (draft.priority ?? 'MEDIUM').trim(),
      'message': draft.message.trim(),
    });
  }

  factory CreateSupportTicketRequestDto.superadminTicket(
    SupportCreateTicketDraft draft,
  ) {
    final payload = <String, dynamic>{
      'message': draft.message.trim(),
      'priority': (draft.priority ?? 'MEDIUM').trim(),
      'category': (draft.category ?? 'GENERAL').trim(),
    };
    final subject = draft.title.trim();
    final adminId = (draft.adminId ?? '').trim();
    if (subject.isNotEmpty) payload['subject'] = subject;
    if (adminId.isNotEmpty) payload['adminId'] = adminId;
    return CreateSupportTicketRequestDto._(payload);
  }

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(values);

  Object toBody({required bool multipart, List<PickedFilePayload> attachments = const []}) {
    if (!multipart || attachments.isEmpty) return toJson();
    return FormData.fromMap(<String, dynamic>{
      ...values,
      'attachments': attachments
          .map((file) => MultipartFile.fromBytes(file.bytes, filename: file.filename))
          .toList(),
    });
  }
}

List<Object?> _extractList(Object? raw) {
  if (raw is List) return raw;
  var map = _jsonMap(raw);
  for (var depth = 0; depth < 5; depth++) {
    for (final key in const [
      'userslist',
      'users',
      'admins',
      'items',
      'rows',
      'results',
      'data',
    ]) {
      final value = map[key];
      if (value is List) return value;
    }
    final next = map['data'];
    if (next is Map && !identical(next, map)) {
      map = _jsonMap(next);
      continue;
    }
    break;
  }
  return const [];
}

Map<String, dynamic> _jsonMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value.cast());
  return <String, dynamic>{};
}

String _s(Object? value) => value?.toString().trim() ?? '';

String _firstNonEmpty(List<Object?> values) {
  for (final value in values) {
    final text = _s(value);
    if (text.isNotEmpty) return text;
  }
  return '';
}

String? _nullable(Object? value) {
  final text = _s(value);
  return text.isEmpty ? null : text;
}
