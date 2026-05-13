// Transitional result facade for legacy presentation controllers.
//
// New migrated flows should prefer typed feature UI states backed by
// Result<T, AppError> in core/utils/result.dart. This file exists only to avoid
// importing the low-level legacy transport result path from presentation.
export 'legacy_transport_result.dart';
