import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_linked_vehicle.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_operations_repository.dart';

class GetAdminPaymentLinkedVehiclesUseCase {
  const GetAdminPaymentLinkedVehiclesUseCase(this._repository);
  final AdminOperationsRepository _repository;

  Future<Result<List<AdminLinkedVehicle>, AppError>> call({required String userId}) {
    return _repository.getLinkedVehicles(userId: userId);
  }
}
