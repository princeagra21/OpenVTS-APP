import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_document_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_account_repository.dart';

class GetAdminUserDocumentsUseCase {
  const GetAdminUserDocumentsUseCase(this._repository);

  final AdminAccountRepository _repository;

  Future<Result<List<AdminDocumentItem>, AppError>> call(String userId) {
    return _repository.getUserDocuments(userId);
  }
}
