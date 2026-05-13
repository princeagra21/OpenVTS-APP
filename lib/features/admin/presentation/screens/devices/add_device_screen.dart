import 'package:open_vts/features/admin/presentation/controllers/add_device_controller.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class AddDeviceScreen extends ConsumerStatefulWidget {
  const AddDeviceScreen({super.key});

  @override
  ConsumerState<AddDeviceScreen> createState() => _AddDeviceScreenState();
}

class _AddDeviceScreenState extends ConsumerState<AddDeviceScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _imeiController = TextEditingController();

  String? _selectedDeviceTypeLabel;
  String? _selectedSimLabel;
  bool _loadErrorShown = false;

  @override
  void dispose() {
    _imeiController.dispose();
    super.dispose();
  }

  void _showLoadErrorOnce(String message) {
    if (_loadErrorShown || !mounted) return;
    _loadErrorShown = true;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _deviceTypeIdFromLabel(AddDeviceFormState state, String label) {
    final match = state.deviceTypes.where((e) => e.name.trim() == label).toList();
    if (match.isEmpty) return '';
    return match.first.id.trim();
  }

  String _simIdFromLabel(AddDeviceFormState state, String label) {
    final match = state.sims.where((e) => e.label.trim() == label).toList();
    if (match.isEmpty) return '';
    return match.first.id.trim();
  }

  Future<void> _submit() async {
    final state = ref.read(addDeviceControllerProvider);
    if (state.isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final imei = _imeiController.text.trim();
    final typeLabel = (_selectedDeviceTypeLabel ?? '').trim();

    if (typeLabel.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select device type.')),
      );
      return;
    }

    final typeId = _deviceTypeIdFromLabel(state, typeLabel);
    if (typeId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected device type is invalid.')),
      );
      return;
    }

    final simLabel = (_selectedSimLabel ?? '').trim();
    final simId = simLabel.isEmpty ? null : _simIdFromLabel(state, simLabel);

    final ok = await ref.read(addDeviceControllerProvider.notifier).submit(
          imei: imei,
          deviceTypeId: typeId,
          simId: simId == null || simId.isEmpty ? null : simId,
        );
    if (!mounted) return;

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Device added.')),
      );
      Navigator.pop(context, true);
      return;
    }

    final message = ref.read(addDeviceControllerProvider).errorMessage ?? 'Couldn\'t add device.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w);
    final formState = ref.watch(addDeviceControllerProvider);

    ref.listen<AddDeviceFormState>(addDeviceControllerProvider, (previous, next) {
      final message = next.errorMessage;
      if (message != null && message.isNotEmpty && !next.isSubmitting) {
        _showLoadErrorOnce(message);
      }
    });

    final deviceTypeLabels = formState.deviceTypes
        .map((e) => e.name.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final simLabels = formState.sims
        .map((e) => e.label.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    if (_selectedDeviceTypeLabel != null && !deviceTypeLabels.contains(_selectedDeviceTypeLabel)) {
      _selectedDeviceTypeLabel = null;
    }
    if (_selectedSimLabel != null && !simLabels.contains(_selectedSimLabel)) {
      _selectedSimLabel = null;
    }

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
                  Text(
                    'Add New Device',
                    style: AppFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: formState.isSubmitting ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        StylishTextField(
                          label: 'IMEI',
                          hint: 'Enter IMEI number',
                          controller: _imeiController,
                          prefixIcon: Icons.device_hub_rounded,
                          validator: (v) {
                            final value = (v ?? '').trim();
                            if (value.isEmpty) return 'Required';
                            return null;
                          },
                          width: w,
                        ),
                        const SizedBox(height: 16),
                        if (formState.isLoading)
                          _dropdownShimmer(label: 'Select device type', width: w)
                        else
                          StylishDropdown(
                            label: 'Select device type',
                            hint: deviceTypeLabels.isEmpty ? '—' : 'Select device type',
                            value: _selectedDeviceTypeLabel,
                            items: deviceTypeLabels,
                            onChanged: deviceTypeLabels.isEmpty
                                ? null
                                : (v) => updateLocalUiState(this, () => _selectedDeviceTypeLabel = v),
                            width: w,
                          ),
                        const SizedBox(height: 16),
                        if (formState.isLoading)
                          _dropdownShimmer(label: 'Select SIM (optional)', width: w)
                        else
                          StylishDropdown(
                            label: 'Select SIM (optional)',
                            hint: simLabels.isEmpty ? '—' : 'Select SIM',
                            value: _selectedSimLabel,
                            items: simLabels,
                            onChanged: simLabels.isEmpty
                                ? null
                                : (v) => updateLocalUiState(this, () => _selectedSimLabel = v),
                            width: w,
                          ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: formState.isSubmitting ? null : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(color: cs.primary.withOpacity(0.2)),
                                  ),
                                ),
                                child: Text('Cancel', style: AppFonts.inter(fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: (formState.isSubmitting || formState.isLoading) ? null : _submit,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(36),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                ),
                                child: formState.isSubmitting
                                    ? const SizedBox(
                                        height: 16,
                                        child: Center(child: AppShimmer(width: 88, height: 14, radius: 7)),
                                      )
                                    : Text('Add Device', style: AppFonts.inter(fontWeight: FontWeight.w600)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdownShimmer({required String label, required double width}) {
    final fs = AdaptiveUtils.getTitleFontSize(width);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppFonts.inter(fontWeight: FontWeight.w600, fontSize: fs)),
        const SizedBox(height: 8),
        const AppShimmer(width: double.infinity, height: 55, radius: 16),
      ],
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
        Text(label, style: AppFonts.inter(fontWeight: FontWeight.w600, fontSize: fs)),
        const SizedBox(height: 8),
        SizedBox(
          height: 55,
          child: TextFormField(
            controller: controller,
            validator: validator,
            decoration: InputDecoration(
              fillColor: cs.surface,
              filled: true,
              hintText: hint,
              hintStyle: AppFonts.inter(color: cs.onSurface.withOpacity(0.6), fontSize: fs),
              prefixIcon: Icon(prefixIcon, color: cs.primary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: cs.outline.withOpacity(0.3)),
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

class StylishDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final String? value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final double width;

  const StylishDropdown({
    super.key,
    required this.label,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fs = AdaptiveUtils.getTitleFontSize(width);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppFonts.inter(fontWeight: FontWeight.w600, fontSize: fs)),
        const SizedBox(height: 8),
        SizedBox(
          height: 55,
          child: DropdownButtonFormField<String>(
            iconEnabledColor: cs.primary,
            iconDisabledColor: cs.primary,
            focusColor: cs.surface,
            initialValue: value,
            hint: Text(hint, style: AppFonts.inter(color: cs.onSurface.withOpacity(0.6), fontSize: fs)),
            decoration: InputDecoration(
              fillColor: cs.surface,
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: cs.outline.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: cs.primary, width: 2),
              ),
            ),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
