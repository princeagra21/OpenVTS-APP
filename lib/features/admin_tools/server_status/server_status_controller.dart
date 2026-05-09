import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/features/admin_tools/server_status/server_status_models.dart';
import 'package:open_vts/features/admin_tools/server_status/server_status_repository.dart';

class ServerStatusController extends ChangeNotifier {
  ServerStatusController({
    required this.repository,
  });

  final ServerStatusRepository repository;

  ServerStatusState _state = const ServerStatusState.initial();
  ServerStatusState get state => _state;

  CancelToken? _loadToken;

  @override
  void dispose() {
    _loadToken?.cancel('Controller disposed');
    super.dispose();
  }

  Future<void> loadStatus() async {
    _loadToken?.cancel('Reload status');
    final token = CancelToken();
    _loadToken = token;

    _state = _state.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      final result = await repository.getServerStatus(cancelToken: token);
      result.when(
        success: (status) {
          _state = _state.copyWith(
            status: status,
            isLoading: false,
            lastUpdated: DateTime.now(),
          );
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
        errorMessage: 'Failed to load server status',
        isLoading: false,
      );
    }
    notifyListeners();
  }

  void clearError() {
    _state = _state.copyWith(errorMessage: null);
    notifyListeners();
  }
}