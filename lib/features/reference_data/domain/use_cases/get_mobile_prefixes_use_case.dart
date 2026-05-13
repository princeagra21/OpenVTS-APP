import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';
import 'package:open_vts/features/reference_data/domain/repositories/reference_data_repository.dart';

class GetMobilePrefixesUseCase {
  const GetMobilePrefixesUseCase(this._repository);
  final ReferenceDataRepository _repository;
  Future<Result<List<MobilePrefixOption>, AppError>> call() => _repository.getMobilePrefixes();
}
