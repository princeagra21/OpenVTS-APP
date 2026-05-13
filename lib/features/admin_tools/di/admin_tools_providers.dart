import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/providers/core_providers.dart';
import 'package:open_vts/core/providers/legacy_repository_adapter_providers.dart';
import 'package:open_vts/features/admin_tools/application/server_status/server_status_repository.dart';
import 'package:open_vts/features/admin_tools/presentation/api_config/api_config_controller.dart';
import 'package:open_vts/features/admin_tools/presentation/api_config/api_config_models.dart';
import 'package:open_vts/features/admin_tools/presentation/server_status/server_status_controller.dart';
import 'package:open_vts/features/admin_tools/domain/entities/server_status.dart';

final serverStatusRepositoryProvider = Provider<ServerStatusRepository>((ref) {
  return ServerStatusRepository(api: ref.watch(legacyApiTransportProvider));
});

final serverStatusControllerProvider = StateNotifierProvider.autoDispose<ServerStatusController, ServerStatusState>((ref) {
  return ServerStatusController(repository: ref.watch(serverStatusRepositoryProvider));
});

final apiConfigControllerProvider = StateNotifierProvider.autoDispose<ApiConfigController, ApiConfigState>((ref) {
  return ApiConfigController(repository: ref.watch(apiConfigRepositoryAdapterProvider));
});
