import 'package:flutter/material.dart';
import 'package:open_vts/core/models/admin_user_list_item.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/design_system/components/open_vts_components.dart';

class TicketUserSelector extends StatelessWidget {
  const TicketUserSelector({
    super.key,
    required this.selectedUser,
    required this.users,
    required this.loading,
    required this.disabled,
    required this.onSelect,
  });

  final AdminUserListItem? selectedUser;
  final List<AdminUserListItem> users;
  final bool loading;
  final bool disabled;
  final ValueChanged<AdminUserListItem?> onSelect;

  String get _selectedText {
    if (selectedUser == null) return 'Select user';
    if (selectedUser!.fullName.isNotEmpty) return selectedUser!.fullName;
    if (selectedUser!.email.isNotEmpty) return selectedUser!.email;
    return selectedUser!.id;
  }

  Future<AdminUserListItem?> _pickAssignee(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return OpenVtsModal.showBottomSheet<AdminUserListItem>(
      context: context,
      child: Builder(
        builder: (ctx) {
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.7,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Select User',
                  style: AppFonts.roboto(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final item = users[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        title: Text(
                          item.fullName.isNotEmpty ? item.fullName : item.email.isNotEmpty ? item.email : item.id,
                          style: AppFonts.roboto(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          item.email.isNotEmpty ? item.email : item.id,
                          style: AppFonts.roboto(
                            fontSize: 12,
                            color: cs.onSurface.withValues(alpha: 0.65),
                          ),
                        ),
                        onTap: () => Navigator.pop(ctx, item),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User *',
          style: AppFonts.roboto(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        if (loading)
          const LinearProgressIndicator(minHeight: 2)
        else
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: disabled
                ? null
                : () async {
                    final chosen = await _pickAssignee(context);
                    if (chosen != null) {
                      onSelect(chosen);
                    }
                  },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: disabled ? cs.onSurface.withValues(alpha: 0.04) : null,
                border: Border.all(color: cs.outline.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedText,
                      style: AppFonts.roboto(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (!disabled)
                    Icon(
                      Icons.expand_more,
                      color: cs.onSurface.withValues(alpha: 0.65),
                    ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }
}