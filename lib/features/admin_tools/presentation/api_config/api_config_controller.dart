import 'package:open_vts/features/admin_tools/data/repositories/api_config_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/admin_tools/presentation/api_config/api_config_models.dart';

class ApiConfigController extends StateNotifier<ApiConfigState> {
  ApiConfigController({required ApiConfigRepository repository})
      : _repository = repository,
        super(const ApiConfigState.initial());

  final ApiConfigRepository _repository;
  int _loadVersion = 0;
  int _saveVersion = 0;

  Future<void> loadConfig() async {
    if (state.isLoading) return;
    final version = ++_loadVersion;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final result = await _repository.getSoftwareConfig();
      if (!mounted || version != _loadVersion) return;
      result.when(
        success: (configMap) {
          state = state.copyWith(
            config: ApiConfigModel.fromMap(configMap),
            isLoading: false,
          );
        },
        failure: (error) {
          state = state.copyWith(errorMessage: error.toString(), isLoading: false);
        },
      );
    } catch (_) {
      if (!mounted || version != _loadVersion) return;
      state = state.copyWith(errorMessage: 'Failed to load config', isLoading: false);
    }
  }

  Future<void> saveConfig() async {
    if (state.isSaving) return;
    final version = ++_saveVersion;
    state = state.copyWith(isSaving: true, errorMessage: null);

    try {
      final result = await _repository.updateSoftwareConfig(state.config.toMap());
      if (!mounted || version != _saveVersion) return;
      result.when(
        success: (_) {
          state = state.copyWith(isSaving: false, lastSaveAt: DateTime.now());
        },
        failure: (error) {
          state = state.copyWith(errorMessage: error.toString(), isSaving: false);
        },
      );
    } catch (_) {
      if (!mounted || version != _saveVersion) return;
      state = state.copyWith(errorMessage: 'Failed to save config', isSaving: false);
    }
  }

  void updateConfig(ApiConfigModel newConfig) {
    state = state.copyWith(config: newConfig);
  }

  Future<void> testConnection(String service) async {
    if (state.testStates[service] == true) return;
    state = state.copyWith(
      testStates: {...state.testStates, service: true},
      errorMessage: null,
    );
    final result = _repository.unavailableTestApi();
    result.when(
      success: (_) {
        state = state.copyWith(testStates: {...state.testStates, service: false});
      },
      failure: (error) {
        state = state.copyWith(
          testStates: {...state.testStates, service: false},
          errorMessage: error.toString(),
        );
      },
    );
  }

  void clearError() => state = state.copyWith(errorMessage: null);
}
