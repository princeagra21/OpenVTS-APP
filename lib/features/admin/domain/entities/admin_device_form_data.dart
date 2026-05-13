import 'package:open_vts/features/vehicles/domain/entities/device_type_option.dart';
import 'package:open_vts/features/vehicles/domain/entities/sim_option.dart';

class AdminDeviceFormData {
  const AdminDeviceFormData({
    required this.deviceTypes,
    required this.sims,
  });

  final List<DeviceTypeOption> deviceTypes;
  final List<SimOption> sims;
}
