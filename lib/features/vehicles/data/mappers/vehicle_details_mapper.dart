import 'package:open_vts/core/api/api_response_normalizer.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_details.dart';

class VehicleDetailsMapper {
  const VehicleDetailsMapper();

  VehicleDetails fromResponse(Object? response) {
    final payload = ApiResponseNormalizer.mapPayloadOf(
      response,
      preferredKeys: const ['vehicle', 'details', 'item'],
    );
    return VehicleDetails(payload.isEmpty ? response : payload);
  }
}
