import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/features/admin_tools/domain/entities/server_overall_status.dart';

class ServerOverallStatusMapper {
  const ServerOverallStatusMapper();

  ServerOverallStatus fromResponse(Object? response) {
    final payload = ApiResponseNormalizer.mapPayloadOf(
      response,
      preferredKeys: const ['system', 'status', 'server'],
    );
    return ServerOverallStatus(payload.isEmpty ? response : payload);
  }
}
