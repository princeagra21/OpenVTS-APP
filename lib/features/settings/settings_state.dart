import 'package:flutter/foundation.dart';
import 'package:open_vts/core/services/push_notifications_service.dart';

enum VerifyChannel { email, whatsapp }

@immutable
class SettingsViewState {
  const SettingsViewState({
    this.errorShown = false,
    this.pushActionLoading = false,
    this.emailOtpLoading = false,
    this.whatsappOtpLoading = false,
    this.pushState,
  });

  final bool errorShown;
  final bool pushActionLoading;
  final bool emailOtpLoading;
  final bool whatsappOtpLoading;
  final PushDeviceState? pushState;

  SettingsViewState copyWith({
    bool? errorShown,
    bool? pushActionLoading,
    bool? emailOtpLoading,
    bool? whatsappOtpLoading,
    PushDeviceState? pushState,
  }) {
    return SettingsViewState(
      errorShown: errorShown ?? this.errorShown,
      pushActionLoading: pushActionLoading ?? this.pushActionLoading,
      emailOtpLoading: emailOtpLoading ?? this.emailOtpLoading,
      whatsappOtpLoading: whatsappOtpLoading ?? this.whatsappOtpLoading,
      pushState: pushState ?? this.pushState,
    );
  }
}
