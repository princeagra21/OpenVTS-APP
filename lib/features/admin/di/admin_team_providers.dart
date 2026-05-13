import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/network/dio_provider.dart';
import 'package:open_vts/features/admin/data/mappers/admin_team_mapper.dart';
import 'package:open_vts/features/admin/data/repositories/admin_team_repository_impl.dart';
import 'package:open_vts/features/admin/data/sources/admin_team_api_service.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_team_repository.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_team_detail_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/get_admin_teams_use_case.dart';
import 'package:open_vts/features/admin/domain/use_cases/update_admin_team_use_case.dart';

final adminTeamApiServiceProvider = Provider<AdminTeamApiService>((ref) {
  return AdminTeamApiService(ref.watch(appDioProvider));
});

final adminTeamMapperProvider = Provider<AdminTeamMapper>((ref) => const AdminTeamMapper());

final adminTeamRepositoryProvider = Provider<AdminTeamRepository>((ref) {
  return AdminTeamRepositoryImpl(
    api: ref.watch(adminTeamApiServiceProvider),
    mapper: ref.watch(adminTeamMapperProvider),
  );
});

final getAdminTeamsUseCaseProvider = Provider<GetAdminTeamsUseCase>((ref) {
  return GetAdminTeamsUseCase(ref.watch(adminTeamRepositoryProvider));
});

final getAdminTeamDetailUseCaseProvider = Provider<GetAdminTeamDetailUseCase>((ref) {
  return GetAdminTeamDetailUseCase(ref.watch(adminTeamRepositoryProvider));
});

final updateAdminTeamUseCaseProvider = Provider<UpdateAdminTeamUseCase>((ref) {
  return UpdateAdminTeamUseCase(ref.watch(adminTeamRepositoryProvider));
});
