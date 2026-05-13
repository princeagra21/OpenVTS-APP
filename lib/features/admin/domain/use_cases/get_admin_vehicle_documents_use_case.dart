import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_document_item.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_vehicle_repository.dart';

class GetAdminVehicleDocumentsUseCase {
  const GetAdminVehicleDocumentsUseCase(this._repository);

  final AdminVehicleRepository _repository;

  Future<Result<List<AdminDocumentItem>, AppError>> call(String vehicleId) {
    return _repository.getVehicleDocuments(vehicleId);
  }
}
