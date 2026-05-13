import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/di/admin_operations_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_calendar_event_item.dart';

class AdminCalendarState {
  const AdminCalendarState({
    this.monthEvents = const <AdminCalendarEventItem>[],
    this.dayEvents = const <AdminCalendarEventItem>[],
    this.isLoadingMonth = false,
    this.isLoadingDay = false,
    this.error,
  });

  final List<AdminCalendarEventItem> monthEvents;
  final List<AdminCalendarEventItem> dayEvents;
  final bool isLoadingMonth;
  final bool isLoadingDay;
  final AppError? error;

  AdminCalendarState copyWith({
    List<AdminCalendarEventItem>? monthEvents,
    List<AdminCalendarEventItem>? dayEvents,
    bool? isLoadingMonth,
    bool? isLoadingDay,
    Object? error = _unchanged,
  }) {
    return AdminCalendarState(
      monthEvents: monthEvents ?? this.monthEvents,
      dayEvents: dayEvents ?? this.dayEvents,
      isLoadingMonth: isLoadingMonth ?? this.isLoadingMonth,
      isLoadingDay: isLoadingDay ?? this.isLoadingDay,
      error: identical(error, _unchanged) ? this.error : error as AppError?,
    );
  }
}

const Object _unchanged = Object();

class AdminCalendarController extends StateNotifier<AdminCalendarState> {
  AdminCalendarController(this._ref) : super(const AdminCalendarState());
  final Ref _ref;

  Future<bool> loadMonth({required String from, required String to}) async {
    state = state.copyWith(isLoadingMonth: true, error: null);
    final result = await _ref.read(getAdminCalendarEventsUseCaseProvider)(from: from, to: to);
    if (!mounted) return false;
    return result.when(
      success: (items) {
        state = state.copyWith(monthEvents: items, isLoadingMonth: false, error: null);
        return true;
      },
      failure: (error) {
        state = state.copyWith(monthEvents: const <AdminCalendarEventItem>[], isLoadingMonth: false, error: error);
        return false;
      },
    );
  }

  Future<bool> loadDay({required String date}) async {
    state = state.copyWith(isLoadingDay: true, error: null);
    final result = await _ref.read(getAdminCalendarEventsUseCaseProvider).day(date: date);
    if (!mounted) return false;
    return result.when(
      success: (items) {
        state = state.copyWith(dayEvents: items, isLoadingDay: false, error: null);
        return true;
      },
      failure: (error) {
        state = state.copyWith(dayEvents: const <AdminCalendarEventItem>[], isLoadingDay: false, error: error);
        return false;
      },
    );
  }
}
