import 'package:open_vts/core/models/admin_user_list_item.dart';
import 'package:open_vts/core/models/admin_quick_device.dart';
import 'package:open_vts/core/models/vehicle_type.dart';
import 'package:open_vts/core/models/pricing_plan.dart';
import 'package:open_vts/core/repositories/admin_users_repository.dart';
import 'package:open_vts/core/repositories/admin_vehicles_repository.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/design_system/components/open_vts_feedback.dart';
import 'package:open_vts/design_system/components/open_vts_modal.dart';
import 'package:open_vts/design_system/components/open_vts_search_field.dart';
import 'package:open_vts/design_system/components/open_vts_text_field.dart';
import 'package:open_vts/design_system/theme/open_vts_typography.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/core/network/api_client_provider.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _vinController = TextEditingController();
  final TextEditingController _imeiController = TextEditingController();

  String? selectedUser;
  String? selectedVehicleType;
  String? selectedPlan;

  List<AdminUserListItem> _users = [];
  List<AdminQuickDevice> _quickDevices = [];
  List<VehicleType> _vehicleTypes = [];
  List<PricingPlan> _plans = [];
  bool _isLoading = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final api = ApiClientProvider.shared();
    final repo = AdminVehiclesRepository(api: api);

    final usersRes = await AdminUsersRepository(api: api).getUsers(limit: 100);
    final devicesRes = await repo.getQuickDevices();
    final vTypesRes = await repo.getVehicleTypes();
    final plansRes = await repo.getPricingPlans();

    if (!mounted) return;
    usersRes.when(success: (u) => _users = u, failure: (_) {});
    devicesRes.when(success: (d) => _quickDevices = d, failure: (_) {});
    vTypesRes.when(success: (v) => _vehicleTypes = v, failure: (_) {});
    plansRes.when(success: (p) => _plans = p, failure: (_) {});

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _plateController.dispose();
    _vinController.dispose();
    _imeiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedUser == null ||
        _imeiController.text.isEmpty ||
        selectedVehicleType == null ||
        selectedPlan == null) {
      OpenVtsFeedback.warning(context, "Please fill all required fields");
      return;
    }

    setState(() => _isSubmitting = true);

    final api = ApiClientProvider.shared();
    final repo = AdminVehiclesRepository(api: api);

    final result = await repo.createVehicle(
      name: _nameController.text,
      vin: _vinController.text,
      plateNumber: _plateController.text,
      deviceId: _imeiController.text,
      vehicleTypeId: selectedVehicleType!,
      primaryUserId: selectedUser!,
      planId: selectedPlan!,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.when(
      success: (_) {
        Navigator.pop(context, true);
      },
      failure: (err) {
        OpenVtsFeedback.error(
          context,
          "Failed to add vehicle: ${err.toString()}",
        );
      },
    );
  }

  Future<T?> _showOptionPicker<T>({
    required String title,
    required List<T> items,
    required String Function(T item) labelFor,
  }) async {
    final cs = Theme.of(context).colorScheme;
    final searchController = TextEditingController();
    String query = '';

    return OpenVtsModal.showBottomSheet<T>(
      context: context,
      child: Builder(
        builder: (ctx) {
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.72,
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final filtered = items.where((item) {
                  return labelFor(
                    item,
                  ).toLowerCase().contains(query.toLowerCase());
                }).toList();

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: OpenVtsTypography.primary(
                                OpenVtsTypography.headingMedium.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => Navigator.pop(ctx),
                            child: Container(
                              height: 36,
                              width: 36,
                              decoration: BoxDecoration(
                                color: cs.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: cs.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      OpenVtsSearchField(
                        controller: searchController,
                        onChanged: (value) =>
                            setSheetState(() => query = value),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 4),
                          itemBuilder: (_, index) {
                            final item = filtered[index];
                            return ListTile(
                              title: Text(
                                labelFor(item),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: OpenVtsTypography.primary(
                                  OpenVtsTypography.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              onTap: () => Navigator.pop(ctx, item),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Future<void> _pickUser() async {
    final picked = await _showOptionPicker<AdminUserListItem>(
      title: 'Select User',
      items: _users,
      labelFor: (item) => item.fullName,
    );
    if (!mounted || picked == null) return;
    setState(() => selectedUser = picked.id);
  }

  Future<void> _pickType() async {
    final picked = await _showOptionPicker<VehicleType>(
      title: 'Select Vehicle Type',
      items: _vehicleTypes,
      labelFor: (item) => item.name,
    );
    if (!mounted || picked == null) return;
    setState(() => selectedVehicleType = picked.id.toString());
  }

  Future<void> _pickDevice() async {
    final picked = await _showOptionPicker<AdminQuickDevice>(
      title: 'Select Device (IMEI)',
      items: _quickDevices,
      labelFor: (item) => item.imei,
    );
    if (!mounted || picked == null) return;
    setState(() => _imeiController.text = picked.imei);
  }

  Future<void> _pickPlan() async {
    final picked = await _showOptionPicker<PricingPlan>(
      title: 'Select Plan',
      items: _plans,
      labelFor: (item) => "${item.name} (${item.price} ${item.currency})",
    );
    if (!mounted || picked == null) return;
    setState(() => selectedPlan = picked.id.toString());
  }

  Widget _buildSelectionField(
    String label,
    String value,
    String hint,
    IconData icon,
    VoidCallback onTap,
  ) {
    final w = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: OpenVtsTypography.primary(
            OpenVtsTypography.bodyLarge.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 8),
        _SelectionField(
          value: value.isEmpty ? hint : value,
          icon: icon,
          width: double.infinity,
          onTap: onTap,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w);
    final double scale = (w / 420).clamp(0.9, 1.0);
    final double titleSize = 16 * scale;
    final double helperSize = 12 * scale;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: padding + 6,
            vertical: padding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add Vehicle",
                    style: OpenVtsTypography.primary(
                      OpenVtsTypography.headingMedium.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: cs.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                "Register a new vehicle",
                style: OpenVtsTypography.secondary(
                  OpenVtsTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      bottom: AdaptiveUtils.getBottomBarHeight(w) + 32,
                    ),
                    child: Column(
                      children: [
                        _buildSelectionField(
                          "Select User *",
                          _users.any((u) => u.id == selectedUser)
                              ? _users
                                    .firstWhere((u) => u.id == selectedUser)
                                    .fullName
                              : "",
                          "Search user...",
                          Icons.person,
                          _pickUser,
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Vehicle Name *",
                              style: OpenVtsTypography.primary(
                                OpenVtsTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OpenVtsTextField(
                              hintText: "e.g. Red Truck",
                              controller: _nameController,
                              prefixIcon: Icon(Icons.directions_car_rounded),
                              validator: (v) =>
                                  v?.isEmpty == true ? "Required" : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Plate No.",
                              style: OpenVtsTypography.primary(
                                OpenVtsTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OpenVtsTextField(
                              hintText: "e.g. KA-01-AB-1234",
                              controller: _plateController,
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "VIN",
                              style: OpenVtsTypography.primary(
                                OpenVtsTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OpenVtsTextField(
                              hintText: "Vehicle Identification Number",
                              controller: _vinController,
                              prefixIcon: Icon(Icons.info_outline),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSelectionField(
                          "Vehicle Type *",
                          selectedVehicleType != null &&
                                  _vehicleTypes.any(
                                    (t) =>
                                        t.id.toString() == selectedVehicleType,
                                  )
                              ? _vehicleTypes
                                    .firstWhere(
                                      (t) =>
                                          t.id.toString() ==
                                          selectedVehicleType,
                                    )
                                    .name
                              : "",
                          "Select type",
                          Icons.category,
                          _pickType,
                        ),
                        const SizedBox(height: 16),
                        _buildSelectionField(
                          "Device (IMEI) *",
                          _imeiController.text,
                          "Search by IMEI...",
                          Icons.memory,
                          _pickDevice,
                        ),
                        const SizedBox(height: 16),
                        _buildSelectionField(
                          "Plan *",
                          selectedPlan != null &&
                                  _plans.any(
                                    (p) => p.id.toString() == selectedPlan,
                                  )
                              ? _plans
                                    .firstWhere(
                                      (p) => p.id.toString() == selectedPlan,
                                    )
                                    .name
                              : "",
                          "Select subscription plan",
                          Icons.subscriptions,
                          _pickPlan,
                        ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.onSurface.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: OpenVtsTypography.primary(
                        OpenVtsTypography.labelLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_isSubmitting || _isLoading) ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                cs.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            "Add Vehicle",
                            style: OpenVtsTypography.primary(
                              OpenVtsTypography.labelLarge.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onPrimary,
                              ),
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionField extends StatelessWidget {
  final String value;
  final IconData icon;
  final double width;
  final VoidCallback onTap;

  const _SelectionField({
    required this.value,
    required this.icon,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: 55,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withOpacity(0.3)),
          color: cs.surface,
        ),
        child: Row(
          children: [
            Icon(icon, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: OpenVtsTypography.primary(OpenVtsTypography.bodyMedium),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: cs.primary),
          ],
        ),
      ),
    );
  }
}
