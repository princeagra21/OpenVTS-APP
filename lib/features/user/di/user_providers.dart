import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/providers/core_providers.dart';
import 'package:open_vts/core/providers/repository_providers.dart' as legacy_repositories;
import 'package:open_vts/core/session/session_service.dart';
import 'package:open_vts/features/user/data/repositories/user_home_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_repository_impl.dart';
import 'package:open_vts/features/user/data/repositories/user_transactions_repository.dart';
import 'package:open_vts/features/user/data/repositories/user_share_track_links_repository.dart';
import 'package:open_vts/features/user/data/sources/user_retrofit_service.dart';
import 'package:open_vts/features/user/domain/entities/user_fleet_status_summary.dart';
import 'package:open_vts/features/user/domain/entities/user_recent_alert_item.dart';
import 'package:open_vts/features/user/domain/entities/user_top_asset_item.dart';
import 'package:open_vts/features/user/domain/entities/user_transactions_page.dart';
import 'package:open_vts/features/user/domain/repositories/user_repository.dart';
import 'package:open_vts/features/user/domain/use_cases/get_user_dashboard_use_case.dart';

final userApiServiceProvider = Provider<UserApiService>((ref) {
  return UserApiService(ref.watch(dioProvider));
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepositoryImpl(api: ref.watch(userApiServiceProvider));
});

final getUserDashboardUseCaseProvider = Provider<GetUserDashboardUseCase>((ref) {
  return GetUserDashboardUseCase(ref.watch(userRepositoryProvider));
});

final userSessionServiceProvider = Provider<SessionService>((ref) {
  return ref.read(legacy_repositories.sessionServiceProvider);
});

class UserDashboardGatewaySnapshot {
  const UserDashboardGatewaySnapshot({
    required this.fleetStatus,
    required this.recentAlerts,
    required this.topAssets,
    required this.hasFailure,
    this.errorMessage,
  });

  final UserFleetStatusSummary? fleetStatus;
  final List<UserRecentAlertItem>? recentAlerts;
  final List<UserTopAssetItem>? topAssets;
  final bool hasFailure;
  final String? errorMessage;
}

class UserDashboardGateway {
  const UserDashboardGateway(this._repository);

  final UserHomeRepository _repository;

  Future<UserDashboardGatewaySnapshot> load({
    UserFleetStatusSummary? currentFleetStatus,
    List<UserRecentAlertItem>? currentRecentAlerts,
    List<UserTopAssetItem>? currentTopAssets,
  }) async {
    UserFleetStatusSummary? nextFleet = currentFleetStatus;
    List<UserRecentAlertItem>? nextAlerts = currentRecentAlerts;
    List<UserTopAssetItem>? nextTopAssets = currentTopAssets;

    var hasFailure = false;
    String? errorMessage;

    void captureFailure(String fallback) {
      hasFailure = true;
      errorMessage ??= fallback;
    }

    final fleetRes = await _repository.getFleetStatus();
    fleetRes.when(
      success: (data) => nextFleet = data,
      failure: (_) => captureFailure("Couldn't load fleet status."),
    );

    final alertsRes = await _repository.getRecentAlerts();
    alertsRes.when(
      success: (data) => nextAlerts = data,
      failure: (_) => captureFailure("Couldn't load recent alerts."),
    );

    final topAssetsRes = await _repository.getTopPerformingAssets();
    topAssetsRes.when(
      success: (data) => nextTopAssets = data,
      failure: (_) => captureFailure("Couldn't load top performing assets."),
    );

    return UserDashboardGatewaySnapshot(
      fleetStatus: nextFleet,
      recentAlerts: nextAlerts,
      topAssets: nextTopAssets,
      hasFailure: hasFailure,
      errorMessage: errorMessage,
    );
  }
}

final userDashboardGatewayProvider = Provider<UserDashboardGateway>((ref) {
  return UserDashboardGateway(
    ref.read(legacy_repositories.userHomeRepositoryAdapterProvider),
  );
});

class UserTransactionsAccess {
  const UserTransactionsAccess(this._repository);

  final UserTransactionsRepository _repository;

  Future<UserTransactionsPage> getTransactions({
    String? query,
    String? status,
    int page = 1,
    int limit = 100,
  }) async {
    final result = await _repository.getTransactions(
      query: query,
      status: status,
      page: page,
      limit: limit,
    );
    return result.when(
      success: (data) => data,
      failure: (error) => throw error,
    );
  }
}

final userTransactionsAccessProvider = Provider<UserTransactionsAccess>((ref) {
  return UserTransactionsAccess(
    ref.read(legacy_repositories.userTransactionsRepositoryProvider),
  );
});


final userShareTrackLinksAccessProvider = Provider<UserShareTrackLinksRepository>((ref) {
  return ref.read(legacy_repositories.userShareTrackLinksRepositoryAdapterProvider);
});
