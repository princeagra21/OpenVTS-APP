// GENERATED CODE - DO NOT MODIFY BY HAND
part of 'settings_state.dart';

mixin _$SettingsState {}

class _Initial implements SettingsState { const _Initial(); }
class _Loading implements SettingsState { const _Loading(); }
class _Loaded implements SettingsState { const _Loaded({required this.settings}); final SettingsSnapshot settings; }
class _Saving implements SettingsState { const _Saving(); }
class _Error implements SettingsState { const _Error(this.error); final AppError error; }
