import 'package:flutter/material.dart';
import 'package:open_vts/features/support/support_role_config.dart';

class TicketPrioritySelector extends StatelessWidget {
  const TicketPrioritySelector({
    super.key,
    required this.role,
    required this.selectedPriority,
    required this.onChanged,
  });

  final SupportRole role;
  final String? selectedPriority;
  final ValueChanged<String?> onChanged;

  List<String> get _priorityOptions {
    switch (role) {
      case SupportRole.admin:
        return const <String>['LOW', 'MEDIUM', 'HIGH', 'URGENT'];
      case SupportRole.user:
        return const <String>['LOW', 'MEDIUM', 'HIGH'];
      case SupportRole.superadmin:
        return const <String>['LOW', 'MEDIUM', 'HIGH'];
    }
  }

  String _titleCase(String value) {
    final v = value.trim();
    if (v.isEmpty) return v;
    return v
        .toLowerCase()
        .split(RegExp(r'\s+|_+|-+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DropdownButtonFormField<String>(
        initialValue: selectedPriority,
        decoration: const InputDecoration(labelText: 'Priority'),
        items: _priorityOptions
            .map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(_titleCase(item)),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}
