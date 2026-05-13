class SupportTicketCreateRequestDto {
  const SupportTicketCreateRequestDto({
    required this.subject,
    required this.message,
    this.category,
    this.priority,
  });

  final String subject;
  final String message;
  final String? category;
  final String? priority;

  Map<String, Object?> toJson() => <String, Object?>{
        'subject': subject.trim(),
        'title': subject.trim(),
        'message': message.trim(),
        if ((category ?? '').trim().isNotEmpty) 'category': category!.trim(),
        if ((priority ?? '').trim().isNotEmpty) 'priority': priority!.trim(),
      };
}
