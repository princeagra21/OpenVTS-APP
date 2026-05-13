import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_operations_repository.dart';

class SendAdminNotificationUseCase {
  const SendAdminNotificationUseCase(this._repository);
  final AdminOperationsRepository _repository;

  Future<Result<void, AppError>> call({required String channel, required List<String> userIds, String? subject, required String message}) {
    return _repository.sendNotification(channel: channel, userIds: userIds, subject: subject, message: message);
  }
}
