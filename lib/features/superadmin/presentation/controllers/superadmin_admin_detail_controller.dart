import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/superadmin/di/superadmin_admin_providers.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_admin.dart';

class SuperadminAdminDetailState {
  const SuperadminAdminDetailState({this.detail, this.isLoading = false, this.errorMessage});
  final SuperadminAdminDetail? detail;
  final bool isLoading;
  final String? errorMessage;
  SuperadminAdminDetailState copyWith({SuperadminAdminDetail? detail, bool? isLoading, Object? errorMessage = _unchanged}) {
    return SuperadminAdminDetailState(
      detail: detail ?? this.detail,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
    );
  }
}
const Object _unchanged = Object();
final superadminAdminDetailControllerProvider = StateNotifierProvider.autoDispose.family<SuperadminAdminDetailController, SuperadminAdminDetailState, String>((ref, adminId) {
  return SuperadminAdminDetailController(ref, adminId);
});
class SuperadminAdminDetailController extends StateNotifier<SuperadminAdminDetailState> {
  SuperadminAdminDetailController(this._ref, this._adminId) : super(const SuperadminAdminDetailState());
  final Ref _ref;
  final String _adminId;
  bool _loadInFlight = false;

  Future<void> load() async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final result = await _ref.read(getSuperadminAdminDetailUseCaseProvider)(_adminId);
      if (!mounted) return;
      result.when(
        success: (detail) => state = state.copyWith(detail: detail, isLoading: false, errorMessage: null),
        failure: (error) => state = state.copyWith(isLoading: false, errorMessage: _message(error, fallback: "Couldn't load admin details.")),
      );
    } finally {
      _loadInFlight = false;
    }
  }
  String _message(Object error, {required String fallback}) => error is AppError && error.message.trim().isNotEmpty ? error.message : fallback;
}
