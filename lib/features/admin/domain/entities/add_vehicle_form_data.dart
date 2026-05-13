import 'package:open_vts/features/admin/domain/entities/admin_form_options.dart';

class AddVehicleFormData {
  const AddVehicleFormData({
    required this.users,
    required this.quickDevices,
    required this.vehicleTypes,
    required this.plans,
  });

  final List<AdminFormUserOption> users;
  final List<AdminFormQuickDeviceOption> quickDevices;
  final List<AdminFormVehicleTypeOption> vehicleTypes;
  final List<AdminFormPlanOption> plans;
}
