import 'package:open_vts/features/admin/domain/entities/admin_team_list_item.dart';
import 'package:open_vts/features/admin/presentation/controllers/admin_team_form_controller.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class EditTeamScreen extends ConsumerStatefulWidget {
  final AdminTeamListItem team;

  const EditTeamScreen({super.key, required this.team});

  @override
  ConsumerState<EditTeamScreen> createState() => _EditTeamScreenState();
}

class _EditTeamScreenState extends ConsumerState<EditTeamScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _usernameController;

  String _selectedCode = '+91';
  List<MobilePrefixOption> _prefixes = const [];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.team.fullName);
    _emailController = TextEditingController(text: widget.team.email);
    _phoneNumberController = TextEditingController(text: widget.team.mobileNumber);
    _usernameController = TextEditingController(text: widget.team.username);
    final initialCode = widget.team.mobilePrefix.trim();
    if (initialCode.isNotEmpty) {
      _selectedCode = initialCode;
    }
    Future.microtask(() => ref.read(adminTeamFormControllerProvider.notifier).loadPrefixes());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _usernameController.dispose();
    super.dispose();
  }


  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<T?> _showSearchableSheet<T>({
    required String title,
    required List<T> items,
    required String Function(T item) labelFor,
    String Function(T item)? trailingFor,
  }) {
    final cs = Theme.of(context).colorScheme;
    final searchController = TextEditingController();
    String query = '';
    final width = MediaQuery.of(context).size.width;
    final fs = AdaptiveUtils.getTitleFontSize(width);

    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.72,
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final filtered = items.where((item) {
                  final text = labelFor(item).toLowerCase();
                  return text.contains(query.toLowerCase());
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
                              style: AppFonts.inter(
                                fontSize: fs,
                                fontWeight: FontWeight.w700,
                                color: cs.onSurface,
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
                              child: Icon(Icons.close, size: 18, color: cs.primary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchController,
                        onChanged: (value) => setSheetState(() => query = value),
                        decoration: InputDecoration(
                          hintText: 'Search',
                          filled: true,
                          fillColor: cs.surfaceContainerHighest.withOpacity(0.3),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: cs.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 4),
                          itemBuilder: (_, index) {
                            final item = filtered[index];
                            final trailing =
                                trailingFor == null ? null : trailingFor(item);
                            return ListTile(
                              title: Text(
                                labelFor(item),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppFonts.inter(
                                  fontSize: fs - 1,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                              trailing: trailing == null || trailing.isEmpty
                                  ? null
                                  : Text(
                                      trailing,
                                      style: AppFonts.inter(
                                        fontSize: fs - 2,
                                        color: cs.onSurface.withOpacity(0.6),
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
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final formState = ref.read(adminTeamFormControllerProvider);
    if (formState.isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await ref.read(adminTeamFormControllerProvider.notifier).updateTeam(
          teamId: widget.team.id,
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          mobilePrefix: _selectedCode,
          mobileNumber: _phoneNumberController.text.trim(),
          username: _usernameController.text.trim(),
        );
    if (!mounted) return;
    if (ok) {
      _showSnack('Team member updated');
      Navigator.pop(context, true);
    } else {
      final message = ref.read(adminTeamFormControllerProvider).errorMessage?.trim();
      _showSnack(message == null || message.isEmpty ? "Couldn't update team." : message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final formState = ref.watch(adminTeamFormControllerProvider);
    final isSubmitting = formState.isSubmitting;
    final isLoadingPrefixes = formState.isLoadingPrefixes;
    _prefixes = formState.prefixes;
    final double w = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(w);
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(w);
    final double labelSize = AdaptiveUtils.getTitleFontSize(w) - 2;
    final double inputSize = AdaptiveUtils.getTitleFontSize(w) - 1;
    final double helperSize = AdaptiveUtils.getTitleFontSize(w) - 2;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: hp + 6, vertical: hp),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Team Member',
                    style: AppFonts.roboto(
                      fontSize: titleSize,
                      height: 20 / 16,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
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
                      child: Icon(Icons.close_rounded, size: 18, color: cs.onPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Update team member details and click save.',
                style: AppFonts.roboto(
                  fontSize: helperSize,
                  height: 16 / 12,
                  fontWeight: FontWeight.w500,
                  color: cs.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.only(
                      bottom: AdaptiveUtils.getBottomBarHeight(w) + 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Label(label: 'Full Name*', size: labelSize),
                        const SizedBox(height: 8),
                        _Field(
                          controller: _nameController,
                          hint: 'John Doe',
                          icon: Icons.person_outline,
                          size: inputSize,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        _Label(label: 'Email*', size: labelSize),
                        const SizedBox(height: 8),
                        _Field(
                          controller: _emailController,
                          hint: 'john@example.com',
                          icon: Icons.email_outlined,
                          size: inputSize,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        _Label(label: 'Code', size: labelSize),
                        const SizedBox(height: 8),
                        _Select(
                          value: _selectedCode,
                          icon: Icons.flag_outlined,
                          size: inputSize,
                          loading: isLoadingPrefixes,
                          onTap: () async {
                            if (isLoadingPrefixes) return;
                            final picked = await _showSearchableSheet<MobilePrefixOption>(
                              title: 'Select Code',
                              items: _prefixes,
                              labelFor: (item) => item.countryCode,
                              trailingFor: (item) => item.code,
                            );
                            if (!mounted || picked == null) return;
                            updateLocalUiState(this, () => _selectedCode = picked.code);
                          },
                        ),
                        const SizedBox(height: 16),
                        _Label(label: 'Mobile', size: labelSize),
                        const SizedBox(height: 8),
                        _Field(
                          controller: _phoneNumberController,
                          hint: '9876543210',
                          icon: Icons.phone_outlined,
                          size: inputSize,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        _Label(label: 'Username*', size: labelSize),
                        const SizedBox(height: 8),
                        _Field(
                          controller: _usernameController,
                          hint: 'masana1',
                          icon: Icons.account_circle_outlined,
                          size: inputSize,
                          validator: (v) =>
                              (v == null || v.trim().isEmpty) ? 'Required' : null,
                        ),
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
                    onPressed: isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.onSurface.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppFonts.roboto(
                        fontSize: AdaptiveUtils.getTitleFontSize(w),
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
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
                    onPressed: isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isSubmitting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(cs.onPrimary),
                            ),
                          )
                        : Text(
                            'Save',
                            style: AppFonts.roboto(
                              fontSize: AdaptiveUtils.getTitleFontSize(w),
                              fontWeight: FontWeight.w600,
                              color: cs.onPrimary,
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

class _Label extends StatelessWidget {
  final String label;
  final double size;

  const _Label({required this.label, required this.size});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppFonts.inter(fontSize: size, fontWeight: FontWeight.w600),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final double size;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.size,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 55,
      child: TextFormField(
        controller: controller,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: AppFonts.inter(
            color: cs.onSurface.withOpacity(0.6),
            fontSize: size,
          ),
          prefixIcon: Icon(icon, color: cs.primary),
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
    );
  }
}

class _Select extends StatelessWidget {
  final String value;
  final IconData icon;
  final double size;
  final bool loading;
  final VoidCallback onTap;

  const _Select({
    required this.value,
    required this.icon,
    required this.size,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
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
                style: AppFonts.inter(fontSize: size, color: cs.onSurface),
              ),
            ),
            if (loading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              )
            else
              Icon(Icons.arrow_drop_down, color: cs.primary),
          ],
        ),
      ),
    );
  }
}

