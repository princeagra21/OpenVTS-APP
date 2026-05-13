import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/user/di/user_landmark_providers.dart';
import 'package:open_vts/features/user/domain/entities/create_user_landmark_input.dart';
import 'package:open_vts/features/user/domain/entities/update_user_landmark_input.dart';
import 'package:open_vts/features/user/domain/entities/user_landmark_form_state.dart';
import 'package:open_vts/features/user/domain/entities/user_landmark_item.dart';

class UserLandmarkState {
  const UserLandmarkState({
    this.landmarks = const <UserLandmarkItem>[],
    this.selectedLandmark,
    this.form = const UserLandmarkFormState(),
    this.isLoading = false,
    this.isSaving = false,
    this.isDeleting = false,
    this.errorMessage,
    this.effect,
  });

  final List<UserLandmarkItem> landmarks;
  final UserLandmarkItem? selectedLandmark;
  final UserLandmarkFormState form;
  final bool isLoading;
  final bool isSaving;
  final bool isDeleting;
  final String? errorMessage;
  final UserLandmarkEffect? effect;

  List<LatLng> get drawnPoints => form.drawnPoints;
  UserLandmarkShape get selectedShape => form.selectedShape;
  double get radius => form.radiusMeters;

  UserLandmarkState copyWith({
    List<UserLandmarkItem>? landmarks,
    Object? selectedLandmark = _unchanged,
    UserLandmarkFormState? form,
    bool? isLoading,
    bool? isSaving,
    bool? isDeleting,
    Object? errorMessage = _unchanged,
    Object? effect = _unchanged,
  }) {
    return UserLandmarkState(
      landmarks: landmarks ?? this.landmarks,
      selectedLandmark: identical(selectedLandmark, _unchanged) ? this.selectedLandmark : selectedLandmark as UserLandmarkItem?,
      form: form ?? this.form,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isDeleting: isDeleting ?? this.isDeleting,
      errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
      effect: identical(effect, _unchanged) ? this.effect : effect as UserLandmarkEffect?,
    );
  }
}

class UserLandmarkEffect {
  const UserLandmarkEffect._(this.message, this.isError);
  final String message;
  final bool isError;

  const UserLandmarkEffect.success(String message) : this._(message, false);
  const UserLandmarkEffect.error(String message) : this._(message, true);
}

const Object _unchanged = Object();

final userLandmarkControllerProvider = StateNotifierProvider.autoDispose<UserLandmarkController, UserLandmarkState>((ref) => UserLandmarkController(ref));

class UserLandmarkController extends StateNotifier<UserLandmarkState> {
  UserLandmarkController(this._ref) : super(const UserLandmarkState());
  final Ref _ref;

  Future<void> loadLandmarks() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, errorMessage: null, effect: null);
    final result = await _ref.read(getUserLandmarksUseCaseProvider)();
    if (!mounted) return;
    result.when(
      success: (landmarks) {
        state = state.copyWith(
          landmarks: landmarks,
          selectedLandmark: _selectedOrNull(landmarks, state.selectedLandmark?.id),
          isLoading: false,
          errorMessage: null,
        );
      },
      failure: (error) {
        final message = _message(error, "Couldn't load landmarks.");
        state = state.copyWith(isLoading: false, errorMessage: message, effect: UserLandmarkEffect.error(message));
      },
    );
  }

  Future<bool> createLandmark(CreateUserLandmarkInput input) async {
    if (state.isSaving) return false;
    if (!input.canPersist) {
      const message = 'Landmark geometry is incomplete.';
      state = state.copyWith(errorMessage: message, effect: UserLandmarkEffect.error(message));
      return false;
    }
    state = state.copyWith(isSaving: true, errorMessage: null, effect: null);
    final result = await _ref.read(createUserLandmarkUseCaseProvider)(input);
    if (!mounted) return false;
    return result.when(
      success: (landmark) {
        state = state.copyWith(
          landmarks: _upsert(state.landmarks, landmark),
          selectedLandmark: landmark,
          isSaving: false,
          form: state.form.copyWith(drawnPoints: input.points, selectedShape: input.shape, radiusMeters: input.radiusMeters),
          effect: const UserLandmarkEffect.success('Landmark saved'),
        );
        return true;
      },
      failure: (error) {
        final message = _message(error, "Couldn't save landmark.");
        state = state.copyWith(isSaving: false, errorMessage: message, effect: UserLandmarkEffect.error(message));
        return false;
      },
    );
  }

  Future<bool> updateLandmark(UpdateUserLandmarkInput input) async {
    if (state.isSaving) return false;
    if (!input.canPersist) {
      const message = 'Landmark geometry is incomplete.';
      state = state.copyWith(errorMessage: message, effect: UserLandmarkEffect.error(message));
      return false;
    }
    state = state.copyWith(isSaving: true, errorMessage: null, effect: null);
    final result = await _ref.read(updateUserLandmarkUseCaseProvider)(input);
    if (!mounted) return false;
    return result.when(
      success: (landmark) {
        state = state.copyWith(
          landmarks: _upsert(state.landmarks, landmark),
          selectedLandmark: landmark,
          isSaving: false,
          form: state.form.copyWith(drawnPoints: input.points, selectedShape: input.shape, radiusMeters: input.radiusMeters),
          effect: const UserLandmarkEffect.success('Landmark updated'),
        );
        return true;
      },
      failure: (error) {
        final message = _message(error, "Couldn't update landmark.");
        state = state.copyWith(isSaving: false, errorMessage: message, effect: UserLandmarkEffect.error(message));
        return false;
      },
    );
  }

  Future<bool> deleteLandmark(String id) async {
    if (state.isDeleting) return false;
    final normalized = id.trim();
    if (normalized.isEmpty) return false;
    state = state.copyWith(isDeleting: true, errorMessage: null, effect: null);
    final result = await _ref.read(deleteUserLandmarkUseCaseProvider)(normalized);
    if (!mounted) return false;
    return result.when(
      success: (_) {
        final next = state.landmarks.where((item) => item.id != normalized).toList(growable: false);
        state = state.copyWith(
          landmarks: next,
          selectedLandmark: state.selectedLandmark?.id == normalized ? null : state.selectedLandmark,
          isDeleting: false,
          effect: const UserLandmarkEffect.success('Landmark deleted'),
        );
        return true;
      },
      failure: (error) {
        final message = _message(error, "Couldn't delete landmark.");
        state = state.copyWith(isDeleting: false, errorMessage: message, effect: UserLandmarkEffect.error(message));
        return false;
      },
    );
  }

  void selectLandmark(String id) {
    state = state.copyWith(selectedLandmark: _selectedOrNull(state.landmarks, id));
  }

  void setDrawnPoints(List<LatLng> points) {
    state = state.copyWith(form: state.form.copyWith(drawnPoints: List<LatLng>.unmodifiable(points)));
  }

  void setSelectedShape(UserLandmarkShape shape) {
    state = state.copyWith(form: state.form.copyWith(selectedShape: shape));
  }

  void setRadius(double radiusMeters) {
    state = state.copyWith(form: state.form.copyWith(radiusMeters: radiusMeters));
  }

  void clearEffect() {
    state = state.copyWith(effect: null);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  UserLandmarkItem? _selectedOrNull(List<UserLandmarkItem> landmarks, String? id) {
    final normalized = id?.trim() ?? '';
    if (normalized.isEmpty) return null;
    for (final item in landmarks) {
      if (item.id == normalized) return item;
    }
    return null;
  }

  List<UserLandmarkItem> _upsert(List<UserLandmarkItem> landmarks, UserLandmarkItem landmark) {
    if (landmark.id.trim().isEmpty) return <UserLandmarkItem>[landmark, ...landmarks];
    final index = landmarks.indexWhere((item) => item.id == landmark.id);
    if (index == -1) return <UserLandmarkItem>[landmark, ...landmarks];
    final next = List<UserLandmarkItem>.from(landmarks);
    next[index] = landmark;
    return next;
  }

  String _message(Object error, String fallback) => error is AppError && error.message.trim().isNotEmpty ? error.message : fallback;
}
