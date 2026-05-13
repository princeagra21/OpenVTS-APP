import 'package:flutter/widgets.dart';

typedef LocalUiMutation = void Function();

/// Centralized escape hatch for state that is intentionally local to a widget.
///
/// ARCHITECTURE GATEWAY GUARD:
/// This helper is permitted only for intentionally local UI state.
/// It must never wrap API loading/data/error state, repository calls, socket
/// processing, session state, permissions, form submission results, or any
/// business workflow. Those states belong in Riverpod controllers/notifiers.
///
/// Use this only for ephemeral UI state such as tab selection, animations,
/// picker/sheet state, map visual toggles, and temporary drawing state.
/// API/business state should live in Riverpod controllers/notifiers.
void updateLocalUiState(State state, LocalUiMutation mutation) {
  if (!state.mounted) return;
  final applyMutation = state.setState;
  applyMutation(mutation);
}
