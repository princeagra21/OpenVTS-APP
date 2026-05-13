/// Central API request-control facade.
///
/// Application code should import this file instead of importing Dio directly.
/// That keeps low-level HTTP dependency ownership inside `core/api` while still
/// allowing legacy screens and controllers to use cancellation, multipart, and
/// response types during the migration to generated Retrofit services.
export 'package:dio/dio.dart';
