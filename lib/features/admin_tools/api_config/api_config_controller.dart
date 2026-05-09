import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/core/network/result.dart';
import 'package:open_vts/core/repositories/api_config_repository.dart';
import 'package:open_vts/features/admin_tools/api_config/api_config_models.dart';

class ApiConfigController extends ChangeNotifier {
  ApiConfigController({required this.repository});

  final ApiConfigRepository repository;

  ApiConfigState _state = const ApiConfigState.initial();
  ApiConfigState get state => _state;

  CancelToken? _loadToken;
  CancelToken? _saveToken;
  CancelToken? _testToken;

  @override
  void dispose() {
    _loadToken?.cancel('Controller disposed');
    _saveToken?.cancel('Controller disposed');
    _testToken?.cancel('Controller disposed');
    super.dispose();
  }

  Future<void> loadConfig() async {
    _loadToken?.cancel('Reload config');
    final token = CancelToken();
    _loadToken = token;

    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      final result = await repository.getSoftwareConfig(cancelToken: token);
      result.when(
        success: (configMap) {
          final config = ApiConfigModel.fromMap(configMap);
          _state = _state.copyWith(config: config, isLoading: false);
        },
        failure: (error) {
          _state = _state.copyWith(
            errorMessage: error.toString(),
            isLoading: false,
          );
        },
      );
    } catch (e) {
      _state = _state.copyWith(
        errorMessage: 'Failed to load config',
        isLoading: false,
      );
    }
    notifyListeners();
  }

  Future<void> saveConfig() async {
    _saveToken?.cancel('Save config');
    final token = CancelToken();
    _saveToken = token;

    _state = _state.copyWith(isSaving: true, errorMessage: null);
    notifyListeners();

    try {
      final payload = _state.config.toMap();
      final result = await repository.updateSoftwareConfig(
        payload,
        cancelToken: token,
      );
      result.when(
        success: (_) {
          _state = _state.copyWith(isSaving: false, lastSaveAt: DateTime.now());
        },
        failure: (error) {
          _state = _state.copyWith(
            errorMessage: error.toString(),
            isSaving: false,
          );
        },
      );
    } catch (e) {
      _state = _state.copyWith(
        errorMessage: 'Failed to save config',
        isSaving: false,
      );
    }
    notifyListeners();
  }

  void updateConfig(ApiConfigModel newConfig) {
    _state = _state.copyWith(config: newConfig);
    notifyListeners();
  }

  Future<void> testConnection(String service) async {
    _testToken?.cancel('Test $service');
    final token = CancelToken();
    _testToken = token;

    _state = _state.copyWith(
      testStates: {..._state.testStates, service: true},
      errorMessage: null,
    );
    notifyListeners();

    final result = repository.unavailableTestApi();
    result.when(
      success: (_) {
        _state = _state.copyWith(
          testStates: {..._state.testStates, service: false},
        );
      },
      failure: (error) {
        _state = _state.copyWith(
          testStates: {..._state.testStates, service: false},
          errorMessage: error.toString(),
        );
      },
    );
    notifyListeners();
  }

  void clearError() {
    _state = _state.copyWith(errorMessage: null);
    notifyListeners();
  }
}
