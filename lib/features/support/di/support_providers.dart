import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/support/data/repositories/support_repository.dart';
import 'package:open_vts/features/support/domain/config/support_role_config.dart';
import 'package:open_vts/features/support/presentation/controllers/support_controller.dart';

final supportControllerProvider = StateNotifierProvider.autoDispose
    .family<SupportController, SupportState, SupportRoleConfig>((ref, config) {
  return SupportController(
    config: config,
    repository: SupportRepositoryFactory.forRole(config.role),
  );
});
