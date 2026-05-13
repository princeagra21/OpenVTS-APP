import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('architecture guard blocks hidden presentation API facades', () {
    final source = File('tools/architecture_guard.py').readAsStringSync();

    expect(source, contains('core/services/api_gateway.dart'));
    expect(source, contains('core/services/common_repository_facade.dart'));
    expect(source, contains('core/application/legacy_backend_client.dart'));
    expect(source, contains('core/providers/core_providers.dart'));
    expect(source, contains('LegacyBackendClient appears in presentation'));
    expect(source, contains('backendClientProvider appears in presentation'));
    expect(source, contains('Presentation imports application repository barrel'));
    expect(source, contains('Application repository barrel exports data implementation'));
    expect(source, contains('Direct repository implementation type still appears in presentation'));

    expect(source, contains('core/providers/repository_providers.dart'));
    expect(source, contains('Direct repository provider usage still appears in presentation'));
    expect(source, contains('transitional shared repository bridge'));
    expect(source, contains('legacy_repositories.dart'));
    expect(source, contains('ApiGateway appears in presentation'));
    expect(source, contains('apiGatewayProvider appears in presentation'));
    expect(source, contains('CommonRepository appears in presentation'));
  });

  test('OpenVTS map screen no longer polls legacy getMapTelemetry directly', () {
    final source = File(
      'lib/features/map/presentation/open_vts_map/open_vts_map_screen.dart',
    ).readAsStringSync();

    expect(source, contains('mapTelemetryNotifierProvider'));
    expect(source, isNot(contains('getMapTelemetry(')));
    expect(source, isNot(contains('Timer.periodic')));
  });
}
