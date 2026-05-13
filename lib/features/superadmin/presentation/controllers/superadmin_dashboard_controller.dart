import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/superadmin/domain/use_cases/superadmin_core_gateway_use_cases.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_recent_transaction.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_recent_user.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_recent_vehicle.dart';

class SuperadminDashboardState {
  const SuperadminDashboardState({
    this.recentVehicles = const <SuperadminRecentVehicle>[],
    this.recentTransactions = const <SuperadminRecentTransaction>[],
    this.recentUsers = const <SuperadminRecentUser>[],
    this.isLoadingVehicles = false,
    this.isLoadingTransactions = false,
    this.isLoadingUsers = false,
    this.vehiclesError,
    this.transactionsError,
    this.usersError,
  });

  final List<SuperadminRecentVehicle> recentVehicles;
  final List<SuperadminRecentTransaction> recentTransactions;
  final List<SuperadminRecentUser> recentUsers;
  final bool isLoadingVehicles;
  final bool isLoadingTransactions;
  final bool isLoadingUsers;
  final AppError? vehiclesError;
  final AppError? transactionsError;
  final AppError? usersError;

  SuperadminDashboardState copyWith({
    List<SuperadminRecentVehicle>? recentVehicles,
    List<SuperadminRecentTransaction>? recentTransactions,
    List<SuperadminRecentUser>? recentUsers,
    bool? isLoadingVehicles,
    bool? isLoadingTransactions,
    bool? isLoadingUsers,
    Object? vehiclesError = _unchanged,
    Object? transactionsError = _unchanged,
    Object? usersError = _unchanged,
  }) {
    return SuperadminDashboardState(
      recentVehicles: recentVehicles ?? this.recentVehicles,
      recentTransactions: recentTransactions ?? this.recentTransactions,
      recentUsers: recentUsers ?? this.recentUsers,
      isLoadingVehicles: isLoadingVehicles ?? this.isLoadingVehicles,
      isLoadingTransactions: isLoadingTransactions ?? this.isLoadingTransactions,
      isLoadingUsers: isLoadingUsers ?? this.isLoadingUsers,
      vehiclesError: identical(vehiclesError, _unchanged)
          ? this.vehiclesError
          : vehiclesError as AppError?,
      transactionsError: identical(transactionsError, _unchanged)
          ? this.transactionsError
          : transactionsError as AppError?,
      usersError: identical(usersError, _unchanged)
          ? this.usersError
          : usersError as AppError?,
    );
  }
}

const Object _unchanged = Object();

class SuperadminDashboardController
    extends StateNotifier<SuperadminDashboardState> {
  SuperadminDashboardController(this._dashboardUseCase)
      : super(const SuperadminDashboardState());

  final GetSuperadminDashboardGatewayUseCase _dashboardUseCase;
  bool _initialLoadInFlight = false;
  bool _hasLoadedInitial = false;

  Future<void> loadInitial({bool force = false}) async {
    if (_initialLoadInFlight) return;
    if (_hasLoadedInitial && !force) return;

    _initialLoadInFlight = true;
    try {
      await Future.wait<void>([
        loadRecentVehicles(),
        loadRecentTransactions(),
        loadRecentUsers(),
      ]);
      _hasLoadedInitial = true;
    } finally {
      _initialLoadInFlight = false;
    }
  }

  Future<void> refreshAll() => loadInitial(force: true);

  Future<void> loadRecentVehicles() async {
    state = state.copyWith(isLoadingVehicles: true, vehiclesError: null);
    final result = await _dashboardUseCase.getRecentVehicles();
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(
        recentVehicles: items,
        isLoadingVehicles: false,
        vehiclesError: null,
      ),
      failure: (error) => state = state.copyWith(
        isLoadingVehicles: false,
        vehiclesError: error,
      ),
    );
  }

  Future<void> loadRecentTransactions() async {
    state = state.copyWith(
      isLoadingTransactions: true,
      transactionsError: null,
    );
    final result = await _dashboardUseCase.getRecentTransactions(limit: 5);
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(
        recentTransactions: items,
        isLoadingTransactions: false,
        transactionsError: null,
      ),
      failure: (error) => state = state.copyWith(
        isLoadingTransactions: false,
        transactionsError: error,
      ),
    );
  }

  Future<void> loadRecentUsers() async {
    state = state.copyWith(isLoadingUsers: true, usersError: null);
    final result = await _dashboardUseCase.getRecentUsers();
    if (!mounted) return;
    result.when(
      success: (items) => state = state.copyWith(
        recentUsers: items,
        isLoadingUsers: false,
        usersError: null,
      ),
      failure: (error) => state = state.copyWith(
        isLoadingUsers: false,
        usersError: error,
      ),
    );
  }
}
