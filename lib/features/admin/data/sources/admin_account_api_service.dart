import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/features/admin/data/models/admin_account_dtos.dart';
import 'package:retrofit/retrofit.dart';

part 'admin_account_api_service.g.dart';

@RestApi()
abstract class AdminAccountApiService {
  factory AdminAccountApiService(Dio dio, {String? baseUrl}) = _AdminAccountApiService;

  @GET('/admin/users')
  Future<ApiResponse<Map<String, dynamic>>> getUsers({
    @Queries() Map<String, Object?>? query,
  });

  @GET('/admin/users/{userId}')
  Future<ApiResponse<Map<String, dynamic>>> getUserDetails(@Path('userId') String userId);

  @GET('/admin/userlogin/{userId}')
  Future<ApiResponse<Map<String, dynamic>>> loginAsUser(@Path('userId') String userId);

  @PATCH('/admin/users/{userId}')
  Future<ApiResponse<void>> updateUserStatus(
    @Path('userId') String userId,
    @Body() UpdateAdminUserStatusRequestDto body,
  );

  @GET('/admin/linkvehicles/{userId}')
  Future<ApiResponse<Map<String, dynamic>>> getUserLinkedVehicles(@Path('userId') String userId);

  @GET('/admin/linkvehicles')
  Future<ApiResponse<Map<String, dynamic>>> getUserLinkedVehiclesByQuery({
    @Query('userId') required String userId,
  });

  @GET('/admin/unlinkvehicles')
  Future<ApiResponse<Map<String, dynamic>>> getUnlinkedVehicles({
    @Queries() Map<String, Object?>? query,
  });

  @GET('/admin/unlinkvehicles/{userId}')
  Future<ApiResponse<Map<String, dynamic>>> getUnlinkedVehiclesByUser(@Path('userId') String userId);

  @POST('/admin/linkusers/{vehicleId}')
  Future<ApiResponse<void>> assignVehicleToUser(
    @Path('vehicleId') String vehicleId,
    @Body() AdminAssignVehicleRequestDto body,
  );

  @GET('/admin/users/unlinkeddrivers/{userId}')
  Future<ApiResponse<Map<String, dynamic>>> getUserLinkedDrivers(@Path('userId') String userId);

  @GET('/admin/documents/{userId}')
  Future<ApiResponse<Map<String, dynamic>>> getUserDocuments(@Path('userId') String userId);

  @GET('/documenttypes/USER')
  Future<ApiResponse<Map<String, dynamic>>> getDocumentTypes();

  @POST('/admin/uploaddoc')
  Future<ApiResponse<void>> uploadDocument(@Body() FormData form);

  @PATCH('/admin/uploaddoc/{documentId}')
  Future<ApiResponse<void>> updateDocument(
    @Path('documentId') String documentId,
    @Body() FormData form,
  );

  @DELETE('/admin/uploaddoc/{documentId}')
  Future<ApiResponse<void>> deleteDocumentFile(@Path('documentId') String documentId);

  @GET('/admin/tickets')
  Future<ApiResponse<Map<String, dynamic>>> getUserTickets({
    @Queries() Map<String, Object?>? query,
  });

  @GET('/admin/users/{userId}/activitylogs')
  Future<ApiResponse<Map<String, dynamic>>> getUserActivityLogs(
    @Path('userId') String userId, {
    @Queries() Map<String, Object?>? query,
  });

  @GET('/admin/payments')
  Future<ApiResponse<Map<String, dynamic>>> getUserPayments({
    @Queries() Map<String, Object?>? query,
  });

  @POST('/admin/updateuserpassword/{userId}')
  Future<ApiResponse<void>> updateUserPassword(
    @Path('userId') String userId,
    @Body() UpdateAdminUserPasswordRequestDto body,
  );

  @GET('/admin/profile')
  Future<ApiResponse<Map<String, dynamic>>> getMyProfile();

  @PATCH('/admin/profile')
  Future<ApiResponse<Map<String, dynamic>>> updateMyProfile(@Body() AdminProfileUpdateRequestDto body);

  @PATCH('/admin/updatepassword')
  Future<ApiResponse<void>> updatePassword(@Body() UpdateAdminPasswordRequestDto body);

  @POST('/admin/profile/verify/email/request')
  Future<ApiResponse<void>> sendEmailOtp(@Body() AdminOtpRequestDto body);

  @POST('/admin/profile/verify/email/confirm')
  Future<ApiResponse<void>> verifyEmailOtp(@Body() AdminOtpRequestDto body);

  @POST('/admin/profile/verify/whatsapp/request')
  Future<ApiResponse<void>> sendPhoneOtp(@Body() AdminOtpRequestDto body);

  @POST('/admin/profile/verify/whatsapp/confirm')
  Future<ApiResponse<void>> verifyPhoneOtp(@Body() AdminOtpRequestDto body);

  @PATCH('/admin/companydetails/{companyId}')
  Future<ApiResponse<Map<String, dynamic>>> updateCompanyDetails(
    @Path('companyId') String companyId,
    @Body() AdminCompanyUpdateRequestDto body,
  );

  @POST('/admin/upload')
  Future<ApiResponse<Map<String, dynamic>>> uploadAdminFile(@Body() FormData form);

  @GET('/admin/linkvehicles/{userId}')
  Future<ApiResponse<Map<String, dynamic>>> getLinkedVehicles(
    @Path('userId') String userId, {
    @Queries() Map<String, Object?>? query,
  });

  @POST('/admin/payments/renew')
  Future<ApiResponse<void>> renewVehicles(@Body() AdminRenewVehiclesRequestDto body);
}
