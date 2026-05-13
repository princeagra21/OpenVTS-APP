import 'package:open_vts/features/admin/domain/entities/admin_form_options.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_feedback.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_modal.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_search_field.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_text_field.dart';
import 'package:open_vts/core/theme/open_vts_typography.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/admin/presentation/controllers/add_vehicle_controller.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _vinController = TextEditingController();
  final TextEditingController _imeiController = TextEditingController();

  String? selectedUser;
  String? selectedVehicleType;
  String? selectedPlan;

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
      OpenVtsFeedback.warning(context, 'Please fill all required fields');
      return;
    }

    final ok = await ref.read(addVehicleControllerProvider.notifier).submit(
          name: _nameController.text,
          vin: _vinController.text,
          plateNumber: _plateController.text,
          deviceId: _imeiController.text,
          vehicleTypeId: selectedVehicleType!,
          primaryUserId: selectedUser!,
          planId: selectedPlan!,
        );

    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
      return;
    }

    final error = ref.read(addVehicleControllerProvider).errorMessage;
    if (error != null && error.isNotEmpty) {
      OpenVtsFeedback.error(context, 'Failed to add vehicle: $error');
      ref.read(addVehicleControllerProvider.notifier).clearError();
    }
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
    final picked = await _showOptionPicker<AdminFormUserOption>(
      title: 'Select User',
      items: ref.read(addVehicleControllerProvider).users,
      labelFor: (item) => item.fullName,
    );
    if (!mounted || picked == null) return;
    updateLocalUiState(this, () => selectedUser = picked.id);
  }

  Future<void> _pickType() async {
    final picked = await _showOptionPicker<AdminFormVehicleTypeOption>(
      title: 'Select Vehicle Type',
      items: ref.read(addVehicleControllerProvider).vehicleTypes,
      labelFor: (item) => item.name,
    );
    if (!mounted || picked == null) return;
    updateLocalUiState(this, () => selectedVehicleType = picked.id);
  }

  Future<void> _pickDevice() async {
    final picked = await _showOptionPicker<AdminFormQuickDeviceOption>(
      title: 'Select Device (IMEI)',
      items: ref.read(addVehicleControllerProvider).quickDevices,
      labelFor: (item) => item.imei,
    );
    if (!mounted || picked == null) return;
    updateLocalUiState(this, () => _imeiController.text = picked.imei);
  }

  Future<void> _pickPlan() async {
    final picked = await _showOptionPicker<AdminFormPlanOption>(
      title: 'Select Plan',
      items: ref.read(addVehicleControllerProvider).plans,
      labelFor: (item) => '${item.name} (${item.price} ${item.currency})',
    );
    if (!mounted || picked == null) return;
    updateLocalUiState(this, () => selectedPlan = picked.id);
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
    final formState = ref.watch(addVehicleControllerProvider);
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
                    'Add Vehicle',
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
                'Register a new vehicle',
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
                          'Select User *',
                          formState.users.any((u) => u.id == selectedUser)
                              ? formState.users
                                    .firstWhere((u) => u.id == selectedUser)
                                    .fullName
                              : '',
                          'Search user...',
                          Icons.person,
                          _pickUser,
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Vehicle Name *',
                              style: OpenVtsTypography.primary(
                                OpenVtsTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OpenVtsTextField(
                              hintText: 'e.g. Red Truck',
                              controller: _nameController,
                              prefixIcon: Icon(Icons.directions_car_rounded),
                              validator: (v) =>
                                  v?.isEmpty == true ? 'Required' : null,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Plate No.',
                              style: OpenVtsTypography.primary(
                                OpenVtsTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OpenVtsTextField(
                              hintText: 'e.g. KA-01-AB-1234',
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
                              'VIN',
                              style: OpenVtsTypography.primary(
                                OpenVtsTypography.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OpenVtsTextField(
                              hintText: 'Vehicle Identification Number',
                              controller: _vinController,
                              prefixIcon: Icon(Icons.info_outline),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildSelectionField(
                          'Vehicle Type *',
                          selectedVehicleType != null &&
                                  formState.vehicleTypes.any(
                                    (t) =>
                                        t.id == selectedVehicleType,
                                  )
                              ? formState.vehicleTypes
                                    .firstWhere(
                                      (t) =>
                                          t.id ==
                                          selectedVehicleType,
                                    )
                                    .name
                              : '',
                          'Select type',
                          Icons.category,
                          _pickType,
                        ),
                        const SizedBox(height: 16),
                        _buildSelectionField(
                          'Device (IMEI) *',
                          _imeiController.text,
                          'Search by IMEI...',
                          Icons.memory,
                          _pickDevice,
                        ),
                        const SizedBox(height: 16),
                        _buildSelectionField(
                          'Plan *',
                          selectedPlan != null &&
                                  formState.plans.any(
                                    (p) => p.id == selectedPlan,
                                  )
                              ? formState.plans
                                    .firstWhere(
                                      (p) => p.id == selectedPlan,
                                    )
                                    .name
                              : '',
                          'Select subscription plan',
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
                      'Cancel',
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
                    onPressed: (formState.isSubmitting || formState.isLoading) ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: formState.isSubmitting
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
                            'Add Vehicle',
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
