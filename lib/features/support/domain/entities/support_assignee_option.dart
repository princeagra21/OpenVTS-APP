class SupportAssigneeOption {
  const SupportAssigneeOption({
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
}
