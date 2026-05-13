import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/user/di/user_notification_providers.dart';
import 'package:open_vts/features/user/domain/entities/user_notification_preferences.dart';

class UserNotificationSettingsState {
  const UserNotificationSettingsState({
    this.preferences,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.effect,
  });

  final UserNotificationPreferences? preferences;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final UserNotificationSettingsEffect? effect;

  List<UserNotificationPreferenceItem> get items => preferences?.items ?? const <UserNotificationPreferenceItem>[];

  UserNotificationSettingsState copyWith({
    UserNotificationPreferences? preferences,
    bool? isLoading,
    bool? isSubmitting,
    Object? errorMessage = _unchanged,
    Object? effect = _unchanged,
  }) {
    return UserNotificationSettingsState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
      effect: identical(effect, _unchanged) ? this.effect : effect as UserNotificationSettingsEffect?,
    );
  }
}

class UserNotificationSettingsEffect {
  const UserNotificationSettingsEffect._(this.message, this.isError);
  final String message;
  final bool isError;

  const UserNotificationSettingsEffect.success(String message) : this._(message, false);
  const UserNotificationSettingsEffect.error(String message) : this._(message, true);
}

const Object _unchanged = Object();

final userNotificationSettingsControllerProvider = StateNotifierProvider.autoDispose<UserNotificationSettingsController, UserNotificationSettingsState>((ref) => UserNotificationSettingsController(ref));

class UserNotificationSettingsController extends StateNotifier<UserNotificationSettingsState> {
  UserNotificationSettingsController(this._ref) : super(const UserNotificationSettingsState());
  final Ref _ref;

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, errorMessage: null, effect: null);
    final result = await _ref.read(getUserNotificationPreferencesUseCaseProvider)();
    if (!mounted) return;
    result.when(
      success: (preferences) => state = state.copyWith(preferences: preferences, isLoading: false),
      failure: (error) {
        final message = _message(error, "Couldn't load notification preferences.");
        state = state.copyWith(isLoading: false, errorMessage: message, effect: UserNotificationSettingsEffect.error(message));
      },
    );
  }

  Future<bool> updatePreferences(UserNotificationPreferences preferences) async {
    if (state.isSubmitting) return false;
    state = state.copyWith(isSubmitting: true, errorMessage: null, effect: null);
    final result = await _ref.read(updateUserNotificationPreferencesUseCaseProvider)(preferences.toUpdatePayload());
    if (!mounted) return false;
    return result.when(
      success: (_) {
        state = state.copyWith(preferences: preferences, isSubmitting: false, effect: const UserNotificationSettingsEffect.success('Notification preferences updated'));
        return true;
      },
      failure: (error) {
        final message = _message(error, "Couldn't update notification preferences.");
        state = state.copyWith(isSubmitting: false, errorMessage: message, effect: UserNotificationSettingsEffect.error(message));
        return false;
      },
    );
  }

  void clearEffect() {
    state = state.copyWith(effect: null);
  }

  String _message(Object error, String fallback) => error is AppError && error.message.trim().isNotEmpty ? error.message : fallback;
}
