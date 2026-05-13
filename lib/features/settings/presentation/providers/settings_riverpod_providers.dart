import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/settings/di/settings_providers.dart';
import 'package:open_vts/features/settings/presentation/state/settings_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_riverpod_providers.g.dart';

@riverpod
class SettingsNotifier extends _$SettingsNotifier {
  @override
  SettingsState build() => const SettingsState.initial();

  Future<void> load() async {
    state = const SettingsState.loading();
    final result = await ref.read(getSettingsUseCaseProvider)();
    state = result.when(
      success: (settings) => SettingsState.loaded(settings: settings),
      failure: SettingsState.error,
    );
  }

  Future<void> save(Map<String, Object?> values) async {
    state = const SettingsState.saving();
    final result = await ref.read(updateSettingsUseCaseProvider)(values);
    state = result.when(
      success: (settings) => SettingsState.loaded(settings: settings),
      failure: SettingsState.error,
    );
  }
}
