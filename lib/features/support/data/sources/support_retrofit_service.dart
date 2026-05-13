import 'package:dio/dio.dart';
import 'package:open_vts/core/api/api_response.dart';
import 'package:open_vts/features/support/data/models/support_ticket_response.dart';
import 'package:retrofit/retrofit.dart';
import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/features/support/data/models/support_ticket_request_dto.dart';

part 'support_retrofit_service.g.dart';

@RestApi()
abstract class SupportApiService {
  factory SupportApiService(Dio dio, {String? baseUrl}) = _SupportApiService;

  @GET('/support/tickets')
  Future<ApiResponse<SupportTicketListResponse>> getTickets({
    @Query('page') int page = 1,
    @Query('limit') int limit = 20,
    @Query('status') String? status,
  });

  @GET('/support/tickets/{id}')
  Future<ApiResponse<SupportTicketResponse>> getTicket(@Path('id') String id);

  @POST('/support/tickets')
  Future<ApiResponse<SupportTicketResponse>> createTicket(@Body() SupportTicketCreateRequestDto request);
}
