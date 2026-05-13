import 'package:open_vts/features/vehicles/domain/entities/device_type_option.dart';
import 'package:open_vts/features/vehicles/domain/entities/sim_option.dart';
import 'package:open_vts/features/vehicles/domain/entities/sim_provider_option.dart';

class AdminDeviceReferences {
  const AdminDeviceReferences({
    this.deviceTypes = const <DeviceTypeOption>[],
    this.sims = const <SimOption>[],
    this.providers = const <SimProviderOption>[],
  });

  final List<DeviceTypeOption> deviceTypes;
  final List<SimOption> sims;
  final List<SimProviderOption> providers;
}
