import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/core/error/error_mapper.dart';

class ErrorHandler {
  const ErrorHandler._();

  static AppError normalize(Object error) => AppErrorMapper.fromObject(error);

  static String message(Object error) => normalize(error).message;
}
