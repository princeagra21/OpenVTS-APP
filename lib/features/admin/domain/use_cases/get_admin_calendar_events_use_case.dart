import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_calendar_event_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_operations_repository.dart';

class GetAdminCalendarEventsUseCase {
  const GetAdminCalendarEventsUseCase(this._repository);
  final AdminOperationsRepository _repository;

  Future<Result<List<AdminCalendarEventItem>, AppError>> call({required String from, required String to}) {
    return _repository.getCalendarEvents(from: from, to: to);
  }

  Future<Result<List<AdminCalendarEventItem>, AppError>> day({required String date}) {
    return _repository.getCalendarDayEvents(date: date);
  }
}
