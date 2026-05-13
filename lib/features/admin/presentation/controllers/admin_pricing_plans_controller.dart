import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/di/admin_operations_providers.dart';
import 'package:open_vts/features/admin/domain/entities/pricing_plan.dart';

class AdminPricingPlansState {
  const AdminPricingPlansState({this.items = const <PricingPlan>[], this.isLoading = false, this.isSubmitting = false, this.error, this.actionError});
  final List<PricingPlan> items;
  final bool isLoading;
  final bool isSubmitting;
  final AppError? error;
  final AppError? actionError;

  AdminPricingPlansState copyWith({List<PricingPlan>? items, bool? isLoading, bool? isSubmitting, Object? error = _unchanged, Object? actionError = _unchanged}) {
    return AdminPricingPlansState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: identical(error, _unchanged) ? this.error : error as AppError?,
      actionError: identical(actionError, _unchanged) ? this.actionError : actionError as AppError?,
    );
  }
}

const Object _unchanged = Object();

class AdminPricingPlansController extends StateNotifier<AdminPricingPlansState> {
  AdminPricingPlansController(this._ref) : super(const AdminPricingPlansState());
  final Ref _ref;

  Future<bool> load() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _ref.read(getAdminPricingPlansUseCaseProvider)();
    if (!mounted) return false;
    return result.when(
      success: (items) {
        state = state.copyWith(items: items, isLoading: false, error: null);
        return true;
      },
      failure: (error) {
        state = state.copyWith(items: const <PricingPlan>[], isLoading: false, error: error);
        return false;
      },
    );
  }

  Future<bool> create({required String name, required int durationDays, required num price, required String currency}) async {
    state = state.copyWith(isSubmitting: true, actionError: null);
    final result = await _ref.read(createAdminPricingPlanUseCaseProvider)(name: name, durationDays: durationDays, price: price, currency: currency);
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(isSubmitting: false, actionError: null);
        return true;
      },
      failure: (error) {
        state = state.copyWith(isSubmitting: false, actionError: error);
        return false;
      },
    );
  }
}
