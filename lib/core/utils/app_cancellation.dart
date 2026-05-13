import 'package:dio/dio.dart' show CancelToken;

/// UI-facing cancellation handle used during the migration away from Dio types.
///
/// Presentation code may create and cancel this handle without importing Dio or
/// knowing about transport-layer details. Because it extends Dio's CancelToken,
/// legacy repositories that still accept CancelToken continue to work until
/// their cancellation ownership is moved fully into controllers/use cases.
class AppCancellationHandle extends CancelToken {
  AppCancellationHandle();
}
