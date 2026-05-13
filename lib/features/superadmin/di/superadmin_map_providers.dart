import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/providers/repository_providers.dart' as legacy_repositories;
import 'package:open_vts/features/map/application/open_vts_map_repository.dart';

/// Superadmin-owned map adapter provider.
///
/// Presentation wrappers depend on this feature DI provider instead of reading
/// legacy repository facade providers directly.
final superadminOpenVtsMapAdapterProvider = Provider<OpenVtsMapRepository>((ref) {
  return SuperadminMapTelemetryAdapter(
    repository: ref.read(legacy_repositories.superadminRepositoryProvider),
  );
});
