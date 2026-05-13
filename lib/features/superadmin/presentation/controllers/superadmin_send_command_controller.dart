import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/superadmin/di/superadmin_vehicle_providers.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_vehicle.dart';

class SuperadminSendCommandEffect {
  const SuperadminSendCommandEffect({required this.message, required this.isSuccess});

  final String message;
  final bool isSuccess;
}

class SuperadminSendCommandState {
  const SuperadminSendCommandState({
    this.commandOptions = const <SuperadminCommandOption>[],
    this.recentCommands = const <SuperadminSentCommand>[],
    this.selectedCommand = 'Set Geofence',
    this.commandPayload,
    this.confirmBeforeSend = false,
    this.isLoading = false,
    this.isSending = false,
    this.responseMessage,
    this.errorMessage,
    this.effect,
  });

  final List<SuperadminCommandOption> commandOptions;
  final List<SuperadminSentCommand> recentCommands;
  final String selectedCommand;
  final Map<String, Object?>? commandPayload;
  final bool confirmBeforeSend;
  final bool isLoading;
  final bool isSending;
  final String? responseMessage;
  final String? errorMessage;
  final SuperadminSendCommandEffect? effect;

  SuperadminSendCommandState copyWith({
    List<SuperadminCommandOption>? commandOptions,
    List<SuperadminSentCommand>? recentCommands,
    String? selectedCommand,
    Object? commandPayload = _unchanged,
    bool? confirmBeforeSend,
    bool? isLoading,
    bool? isSending,
    Object? responseMessage = _unchanged,
    Object? errorMessage = _unchanged,
    Object? effect = _unchanged,
  }) {
    return SuperadminSendCommandState(
      commandOptions: commandOptions ?? this.commandOptions,
      recentCommands: recentCommands ?? this.recentCommands,
      selectedCommand: selectedCommand ?? this.selectedCommand,
      commandPayload: identical(commandPayload, _unchanged) ? this.commandPayload : commandPayload as Map<String, Object?>?,
      confirmBeforeSend: confirmBeforeSend ?? this.confirmBeforeSend,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      responseMessage: identical(responseMessage, _unchanged) ? this.responseMessage : responseMessage as String?,
      errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
      effect: identical(effect, _unchanged) ? this.effect : effect as SuperadminSendCommandEffect?,
    );
  }
}

const Object _unchanged = Object();

final superadminSendCommandControllerProvider =
    StateNotifierProvider.autoDispose<SuperadminSendCommandController, SuperadminSendCommandState>(
  (ref) => SuperadminSendCommandController(ref),
);

class SuperadminSendCommandController extends StateNotifier<SuperadminSendCommandState> {
  SuperadminSendCommandController(this._ref) : super(const SuperadminSendCommandState());

  final Ref _ref;

  Future<void> loadReferences(String imei) async {
    if (imei.trim().isEmpty || state.isLoading) return;
    state = state.copyWith(isLoading: true, errorMessage: null, effect: null);

    final optionsResult = await _ref.read(getSuperadminCommandOptionsUseCaseProvider)(imei);
    final recentResult = await _ref.read(getSuperadminRecentCommandsUseCaseProvider)(imei);
    if (!mounted) return;

    var next = state.copyWith(isLoading: false);
    var failed = false;
    optionsResult.when(
      success: (items) {
        final selected = _selectAvailableCommand(items, state.selectedCommand);
        next = next.copyWith(commandOptions: items, selectedCommand: selected);
      },
      failure: (error) {
        failed = true;
        next = next.copyWith(errorMessage: _message(error, fallback: "Couldn't load commands."));
      },
    );
    recentResult.when(
      success: (items) => next = next.copyWith(recentCommands: items),
      failure: (error) {
        failed = true;
        next = next.copyWith(errorMessage: next.errorMessage ?? _message(error, fallback: "Couldn't load recent commands."));
      },
    );
    if (failed) {
      next = next.copyWith(
        effect: SuperadminSendCommandEffect(message: next.errorMessage ?? "Couldn't load some command data. Using fallback.", isSuccess: false),
      );
    }
    state = next;
  }

  void selectCommand(String command) {
    state = state.copyWith(selectedCommand: command);
  }

  void updatePayload(Map<String, Object?>? payload) {
    state = state.copyWith(commandPayload: payload);
  }

  void setConfirmBeforeSend(bool value) {
    state = state.copyWith(confirmBeforeSend: value);
  }

  Future<bool> sendCommand(String imei) async {
    if (state.isSending) return false;
    if (imei.trim().isEmpty) {
      state = state.copyWith(
        errorMessage: 'IMEI missing. Cannot send command.',
        effect: const SuperadminSendCommandEffect(message: 'IMEI missing. Cannot send command.', isSuccess: false),
      );
      return false;
    }

    state = state.copyWith(isSending: true, errorMessage: null, responseMessage: null, effect: null);
    final code = _selectedOption()?.code.isNotEmpty == true ? _selectedOption()!.code : state.selectedCommand;
    final result = await _ref.read(sendSuperadminVehicleCommandUseCaseProvider)(
          imei,
          code,
          state.commandPayload,
          state.confirmBeforeSend,
        );
    if (!mounted) return false;

    return result.when(
      success: (_) {
        final message = 'Command sent';
        state = state.copyWith(
          isSending: false,
          responseMessage: message,
          errorMessage: null,
          effect: const SuperadminSendCommandEffect(message: 'Command sent', isSuccess: true),
          recentCommands: <SuperadminSentCommand>[
            SuperadminSentCommand(
              name: state.selectedCommand,
              status: 'sent',
              createdAt: DateTime.now().toIso8601String(),
            ),
            ...state.recentCommands,
          ],
        );
        return true;
      },
      failure: (error) {
        final message = _message(error, fallback: "Couldn't send command.");
        state = state.copyWith(
          isSending: false,
          responseMessage: null,
          errorMessage: message,
          effect: SuperadminSendCommandEffect(message: message, isSuccess: false),
        );
        return false;
      },
    );
  }

  void clearEffect() {
    state = state.copyWith(effect: null);
  }

  SuperadminCommandOption? _selectedOption() {
    for (final option in state.commandOptions) {
      final name = option.name.isNotEmpty ? option.name : option.code;
      if (name == state.selectedCommand) return option;
    }
    return null;
  }

  String _selectAvailableCommand(List<SuperadminCommandOption> options, String current) {
    final names = options.map((e) => e.name.isNotEmpty ? e.name : e.code).where((e) => e.trim().isNotEmpty).toList();
    if (names.contains(current)) return current;
    return names.isNotEmpty ? names.first : current;
  }

  String _message(Object error, {required String fallback}) {
    return error is AppError && error.message.trim().isNotEmpty ? error.message : fallback;
  }
}
