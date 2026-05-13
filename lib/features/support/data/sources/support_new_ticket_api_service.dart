import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/features/support/data/models/support_new_ticket_dtos.dart';
import 'package:retrofit/retrofit.dart';
import 'package:open_vts/core/api/api_response_normalizer.dart';

part 'support_new_ticket_api_service.g.dart';

@RestApi()
abstract class SupportNewTicketApiService {
  factory SupportNewTicketApiService(Dio dio, {String? baseUrl}) =
      _SupportNewTicketApiService;

  @GET('/admin/users')
  Future<ApiResponse<SupportAssigneeListResponseDto>> getAdminUsers({
    @Query('limit') int limit = 200,
  });

  @GET('/superadmin/adminlist')
  Future<ApiResponse<SupportAssigneeListResponseDto>> getSuperadminAdmins({
    @Query('limit') int limit = 200,
  });

  @POST('/admin/tickets')
  Future<ApiResponse<void>> createAdminUserTicket(
    @Body() CreateSupportTicketRequestDto body,
  );

  @POST('/admin/mytickets')
  Future<ApiResponse<void>> createAdminMyTicket(@Body() Map<String, dynamic> body);

  @POST('/user/tickets')
  Future<ApiResponse<void>> createUserTicket(
    @Body() CreateSupportTicketRequestDto body,
  );

  @POST('/superadmin/support/tickets')
  Future<ApiResponse<void>> createSuperadminTicket(
    @Body() CreateSupportTicketRequestDto body,
  );
}
