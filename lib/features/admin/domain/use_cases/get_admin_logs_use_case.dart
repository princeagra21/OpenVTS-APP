import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_log_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_operations_repository.dart';

class GetAdminLogsUseCase {
  const GetAdminLogsUseCase(this._repository);
  final AdminOperationsRepository _repository;

  Future<Result<List<AdminLogItem>, AppError>> call({String? search, String? level, int? page, int? limit, String? from, String? to}) {
    return _repository.getLogs(search: search, level: level, page: page, limit: limit, from: from, to: to);
  }
}
