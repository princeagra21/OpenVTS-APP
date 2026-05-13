import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_notification_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_recipient.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_operations_repository.dart';

class GetAdminNotificationsUseCase {
  const GetAdminNotificationsUseCase(this._repository);
  final AdminOperationsRepository _repository;

  Future<Result<List<AdminNotificationItem>, AppError>> call() => _repository.getNotifications();
  Future<Result<void, AppError>> markRead(String id) => _repository.markNotificationRead(id);
  Future<Result<void, AppError>> markAllRead() => _repository.markAllNotificationsRead();
  Future<Result<List<AdminUserRecipient>, AppError>> recipients({String query = ''}) {
    return _repository.searchNotificationRecipients(query: query);
  }
}
