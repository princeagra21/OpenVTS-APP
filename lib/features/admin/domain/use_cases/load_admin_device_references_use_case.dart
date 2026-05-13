import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/admin/domain/entities/admin_device_references.dart';
import 'package:open_vts/features/admin/domain/repositories/admin_device_repository.dart';

class LoadAdminDeviceReferencesUseCase {
  const LoadAdminDeviceReferencesUseCase(this._repository);

  final AdminDeviceRepository _repository;

  Future<Result<AdminDeviceReferences, AppError>> call({bool quickSims = false}) async {
    final types = await _repository.getDeviceTypes();
    final sims = quickSims ? await _repository.getQuickSimCards() : await _repository.getSims();
    final providers = await _repository.getSimProviders();
    final error = types.errorOrNull ?? sims.errorOrNull ?? providers.errorOrNull;
    if (error != null) return Result.failure(error);
    return Result.success(AdminDeviceReferences(
      deviceTypes: types.valueOrNull ?? const [],
      sims: sims.valueOrNull ?? const [],
      providers: providers.valueOrNull ?? const [],
    ));
  }
}
