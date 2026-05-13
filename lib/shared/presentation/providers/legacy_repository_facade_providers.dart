/// Transitional repository access for allowlisted legacy presentation screens.
///
/// Do not use this in migrated Riverpod screens. It exists so direct imports of
/// legacy repository bridge files can be blocked by the
/// architecture guard while the remaining legacy screens are migrated in later
/// phases.
export 'package:open_vts/core/providers/repository_providers.dart';
export 'package:open_vts/core/providers/legacy_repository_adapter_providers.dart';
