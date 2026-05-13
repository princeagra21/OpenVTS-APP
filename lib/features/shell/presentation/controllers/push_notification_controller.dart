import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/services/push_notifications_service.dart';

class PushNotificationState {
  const PushNotificationState({
    this.deviceState,
    this.isLoading = false,
    this.isUpdating = false,
    this.errorMessage,
  });

  final PushDeviceState? deviceState;
  final bool isLoading;
  final bool isUpdating;
  final String? errorMessage;

  PushNotificationState copyWith({
    PushDeviceState? deviceState,
    bool? isLoading,
    bool? isUpdating,
    Object? errorMessage = _unchanged,
  }) {
    return PushNotificationState(
      deviceState: deviceState ?? this.deviceState,
      isLoading: isLoading ?? this.isLoading,
      isUpdating: isUpdating ?? this.isUpdating,
      errorMessage: identical(errorMessage, _unchanged)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _unchanged = Object();

final pushNotificationControllerProvider = StateNotifierProvider.autoDispose<
    PushNotificationController, PushNotificationState>((ref) {
  return PushNotificationController();
});

class PushNotificationController extends StateNotifier<PushNotificationState> {
  PushNotificationController() : super(const PushNotificationState());

  bool _loadInFlight = false;

  Future<void> load() async {
    if (_loadInFlight) return;
    _loadInFlight = true;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final deviceState = await PushNotificationsService.instance.getStatus();
      if (!mounted) return;
      state = state.copyWith(
        deviceState: deviceState,
        isLoading: false,
        errorMessage: null,
      );
    } catch (_) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: "Couldn't load push notification status.",
      );
    } finally {
      _loadInFlight = false;
    }
  }

  Future<bool> toggle() async {
    final current = state.deviceState;
    if (state.isUpdating || current == null || !current.canShowBanner) {
      return false;
    }

    state = state.copyWith(isUpdating: true, errorMessage: null);
    final result = current.canDisable
        ? await PushNotificationsService.instance.disable()
        : await PushNotificationsService.instance.enable();

    if (!mounted) return false;

    final ok = result.when(
      success: (_) => true,
      failure: (error) {
        final message = error.toString().trim().isNotEmpty
            ? error.toString()
            : "Couldn't update push notifications.";
        state = state.copyWith(isUpdating: false, errorMessage: message);
        return false;
      },
    );

    if (!ok) return false;
    await load();
    if (!mounted) return true;
    state = state.copyWith(isUpdating: false, errorMessage: null);
    return true;
  }
}
