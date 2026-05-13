import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/providers/core_providers.dart' as core;

/// Feature-level data providers should depend on this typed Dio provider
/// instead of importing the broad legacy core provider barrel.
final appDioProvider = Provider<Dio>((ref) {
  return ref.watch(core.dioProvider);
});
