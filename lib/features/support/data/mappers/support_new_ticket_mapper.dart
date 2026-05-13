import 'package:open_vts/features/support/data/models/support_new_ticket_dtos.dart';
import 'package:open_vts/features/support/domain/entities/support_assignee_option.dart';
import 'package:open_vts/features/support/domain/config/support_role_config.dart';

class SupportNewTicketMapper {
  const SupportNewTicketMapper();

  SupportAssigneeOption assignee(
    SupportAssigneeDto dto, {
    required SupportRole fallbackRole,
  }) {
    return SupportAssigneeOption(
      id: dto.id,
      name: dto.name.isNotEmpty ? dto.name : dto.email ?? dto.id,
      role: dto.role.isNotEmpty ? dto.role : fallbackRole.name.toUpperCase(),
      email: dto.email,
      phone: dto.phone,
      subtitle: dto.subtitle,
    );
  }
}
