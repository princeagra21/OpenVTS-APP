import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/map/application/open_vts_map_repository.dart';

/// Scoped repository adapter for legacy OpenVTS map operations that are not yet
/// migrated into dedicated map use cases.
///
/// Role map entry screens override this provider with the correct adapter. The
/// map screen itself no longer receives repositories through widget fields.
final openVtsMapRepositoryProvider = Provider<OpenVtsMapRepository>((ref) {
  throw StateError('OpenVtsMapRepository provider was not overridden.');
});
