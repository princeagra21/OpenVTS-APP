import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/admin_tools/application/server_status/server_status_repository.dart';
import 'package:open_vts/features/admin_tools/domain/entities/server_status.dart';

class ServerStatusController extends StateNotifier<ServerStatusState> {
  ServerStatusController({required ServerStatusRepository repository})
      : _repository = repository,
        super(const ServerStatusState.initial());

  final ServerStatusRepository _repository;
  int _loadVersion = 0;

  Future<void> loadStatus() async {
    if (state.isLoading) return;
    final version = ++_loadVersion;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _repository.getServerStatus();
      if (!mounted || version != _loadVersion) return;
      result.when(
        success: (status) {
          state = state.copyWith(
            status: status,
            isLoading: false,
            lastUpdated: DateTime.now(),
          );
        },
        failure: (error) {
          state = state.copyWith(
            errorMessage: error.toString(),
            isLoading: false,
          );
        },
      );
    } catch (_) {
      if (!mounted || version != _loadVersion) return;
      state = state.copyWith(
        errorMessage: 'Failed to load server status',
        isLoading: false,
      );
    }
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}
