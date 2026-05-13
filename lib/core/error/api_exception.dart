/// Presentation-safe API exception facade.
///
/// The concrete exception still lives in the low-level API layer while the app
/// is migrated to typed domain errors. UI code should import this facade, not
/// `core/api/*`.
export 'package:open_vts/core/api/api_exception.dart';
