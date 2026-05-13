import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/config/app_config.dart';
import 'package:open_vts/core/observability/noop_observability_service.dart';
import 'package:open_vts/core/observability/observability_service.dart';
import 'package:open_vts/core/observability/production_observability_service.dart';

final observabilityConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromDartDefine();
});

final observabilityServiceProvider = Provider<ObservabilityService>((ref) {
  final config = ref.watch(observabilityConfigProvider);
  if (config.isProduction) {
    return ProductionObservabilityService();
  }
  if (!config.enableObservability) {
    return const NoopObservabilityService();
  }
  return ProductionObservabilityService();
});
