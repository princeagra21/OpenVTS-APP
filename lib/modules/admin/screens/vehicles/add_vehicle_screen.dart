import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_user_list_item.dart';
import 'package:fleet_stack/core/models/admin_quick_device.dart';
import 'package:fleet_stack/core/models/vehicle_type.dart';
import 'package:fleet_stack/core/models/pricing_plan.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/repositories/admin_users_repository.dart';
import 'package:fleet_stack/core/repositories/admin_vehicles_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final api = ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final api = ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add vehicle: ${err.toString()}")),
        );
      },
    );
  }

  Future<T?> _showOptionPicker<T>({
    required String title,
    required List<T> items,
    required String Function(T item) labelFor,
  }) async {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) {
        final searchController = TextEditingController();
        String query = '';
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final filtered = items.where((item) {
              return labelFor(item).toLowerCase().contains(query.toLowerCase());
            }).toList();
            return Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                height: MediaQuery.of(ctx).size.height * 0.75,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      onChanged: (value) => setSheetState(() => query = value),
                      decoration: const InputDecoration(
                        hintText: 'Search',
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return ListTile(
                            title: Text(labelFor(item)),
                            onTap: () => Navigator.pop(ctx, item),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
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

  Widget _buildSelectionField(String label, String value, String hint, IconData icon, VoidCallback onTap) {
    final w = MediaQuery.of(context).size.width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: AdaptiveUtils.getTitleFontSize(w))),
        const SizedBox(height: 8),
        _SelectionField(
            value: value.isEmpty ? hint : value,
            icon: icon,
            width: double.infinity,
            onTap: onTap
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w);
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(w);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding * 1.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Add Vehicle",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        "Enter vehicle details to add to fleet.",
                        style: GoogleFonts.inter(
                          fontSize: AdaptiveUtils.getTitleFontSize(w),
                          color: cs.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 24),

              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildSelectionField(
                          "Select User *",
                          _users.any((u) => u.id == selectedUser) ? _users.firstWhere((u) => u.id == selectedUser).fullName : "",
                          "Search user...",
                          Icons.person,
                          _pickUser,
                        ),
                        const SizedBox(height: 16),
                        StylishTextField(
                          label: "Vehicle Name *",
                          hint: "e.g. Red Truck",
                          controller: _nameController,
                          prefixIcon: Icons.directions_car_rounded,
                          validator: (v) => v?.isEmpty == true ? "Required" : null,
                          width: w,
                        ),
                        const SizedBox(height: 16),
                        StylishTextField(
                          label: "Plate No.",
                          hint: "e.g. KA-01-AB-1234",
                          controller: _plateController,
                          prefixIcon: Icons.badge_outlined,
                          width: w,
                        ),
                        const SizedBox(height: 16),
                        StylishTextField(
                          label: "VIN",
                          hint: "Vehicle Identification Number",
                          controller: _vinController,
                          prefixIcon: Icons.info_outline,
                          width: w,
                        ),
                        const SizedBox(height: 16),
                        _buildSelectionField(
                          "Vehicle Type *",
                          selectedVehicleType != null && _vehicleTypes.any((t) => t.id.toString() == selectedVehicleType) ? _vehicleTypes.firstWhere((t) => t.id.toString() == selectedVehicleType).name : "",
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
                          selectedPlan != null && _plans.any((p) => p.id.toString() == selectedPlan) ? _plans.firstWhere((p) => p.id.toString() == selectedPlan).name : "",
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
        child: Container(
          padding: EdgeInsets.fromLTRB(padding * 1.3, 10, padding * 1.3, 10),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(top: BorderSide(color: cs.outline.withOpacity(0.10))),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(color: cs.primary.withOpacity(0.25)),
                    ),
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              SizedBox(width: spacing + 2),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: (_isSubmitting || _isLoading) ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(cs.surface),
                            ),
                          )
                        : Text(
                            "Add Vehicle",
                            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
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

class StylishTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final double width;

  const StylishTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    required this.prefixIcon,
    this.validator,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fs = AdaptiveUtils.getTitleFontSize(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
              fontWeight: FontWeight.w600, fontSize: fs),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 55,
          child: TextFormField(
            controller: controller,
            validator: validator,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                color: cs.onSurface.withOpacity(0.6),
                fontSize: fs,
              ),
              prefixIcon: Icon(prefixIcon, color: cs.primary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    BorderSide(color: cs.outline.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: cs.primary, width: 2),
              ),
            ),
          ),
        ),
      ],
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
                style: GoogleFonts.inter(
                  fontSize: AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width),
                  color: cs.onSurface,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: cs.primary),
          ],
        ),
      ),
    );
  }
}
