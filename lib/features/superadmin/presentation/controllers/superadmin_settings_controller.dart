import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/superadmin/di/superadmin_settings_providers.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_settings.dart';

class SuperadminSettingsState {
  const SuperadminSettingsState({this.settings, this.isLoading = false, this.isSaving = false, this.errorMessage});
  final SuperadminSettingsData? settings;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  SuperadminSettingsState copyWith({SuperadminSettingsData? settings, bool? isLoading, bool? isSaving, Object? errorMessage = _unchanged}) => SuperadminSettingsState(
    settings: settings ?? this.settings,
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
  );
}
const Object _unchanged = Object();
final superadminSettingsControllerProvider = StateNotifierProvider.autoDispose<SuperadminSettingsController, SuperadminSettingsState>((ref) => SuperadminSettingsController(ref));
class SuperadminSettingsController extends StateNotifier<SuperadminSettingsState> {
  SuperadminSettingsController(this._ref) : super(const SuperadminSettingsState());
  final Ref _ref;
  Future<void> load(String adminId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _ref.read(getSuperadminSettingsUseCaseProvider)(adminId);
    if (!mounted) return;
    result.when(success: (settings) => state = state.copyWith(settings: settings, isLoading: false, errorMessage: null), failure: (error) => state = state.copyWith(isLoading: false, errorMessage: _message(error, fallback: "Couldn't load settings.")));
  }
  Future<bool> save(String adminId, SuperadminSettingsData settings) async {
    if (state.isSaving) return false;
    state = state.copyWith(isSaving: true, errorMessage: null);
    final result = await _ref.read(updateSuperadminSettingsUseCaseProvider)(adminId, settings);
    if (!mounted) return false;
    return result.when(success: (saved) { state = state.copyWith(settings: saved, isSaving: false, errorMessage: null); return true; }, failure: (error) { state = state.copyWith(isSaving: false, errorMessage: _message(error, fallback: "Couldn't save settings.")); return false; });
  }
  String _message(Object error, {required String fallback}) => error is AppError && error.message.trim().isNotEmpty ? error.message : fallback;
}
