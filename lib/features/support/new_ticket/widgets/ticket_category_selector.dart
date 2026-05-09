import 'package:flutter/material.dart';
import 'package:open_vts/features/support/support_models.dart';

class TicketCategorySelector extends StatelessWidget {
  const TicketCategorySelector({
    super.key,
    required this.role,
    required this.selectedCategory,
    required this.onChanged,
  });

  final SupportRole role;
  final String? selectedCategory;
  final ValueChanged<String?> onChanged;

  List<String> get _categoryOptions {
    switch (role) {
      case SupportRole.admin:
        return const <String>[
          'INSTALLATION',
          'SERVER',
          'BILLING',
          'MAPS',
          'TECHNICAL',
          'GENERAL',
          'OTHER',
        ];
      case SupportRole.user:
        return const <String>[
          'SERVER',
          'NOTIFICATION',
          'INSTALLATION',
          'MAPS',
          'BILLING',
          'OTHERS',
        ];
      case SupportRole.superadmin:
        return const <String>['BILLING', 'TECHNICAL', 'OTHER'];
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
        value: selectedCategory,
        decoration: const InputDecoration(
          labelText: 'Category',
        ),
        items: _categoryOptions
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