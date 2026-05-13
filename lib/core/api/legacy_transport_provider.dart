import 'package:open_vts/core/api/api_client_provider.dart';
import 'package:open_vts/core/api/legacy_api_transport.dart';

/// Compatibility access to the shared legacy transport.
///
/// New repositories should depend on Dio/Retrofit services through Riverpod DI.
/// This helper exists only for old role-adapter seams that still need the
/// initialized transport while they are being migrated behind typed services.
LegacyApiTransport sharedLegacyTransport() => ApiClientProvider.shared();
