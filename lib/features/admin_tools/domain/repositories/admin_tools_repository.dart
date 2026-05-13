import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/utils/result.dart';

/// Domain boundary for AdminTools feature use cases.
///
/// Concrete legacy implementations still live in data/repositories while
/// presentation must depend on use cases/providers instead of data classes.
abstract interface class AdminToolsRepository {
  Future<Result<Object?, AppError>> loadResource(String resourceKey);
}
