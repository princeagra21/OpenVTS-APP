import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/providers/repository_providers.dart' as legacy_repositories;
import 'package:open_vts/features/map/application/open_vts_map_repository.dart';

final userOpenVtsMapAdapterProvider = Provider<OpenVtsMapRepository>((ref) {
  return UserMapTelemetryAdapter(
    repository: ref.read(legacy_repositories.userVehiclesRepositoryProvider),
  );
});
