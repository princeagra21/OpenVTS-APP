import 'package:open_vts/features/admin/presentation/controllers/add_team_controller.dart';
import 'package:open_vts/features/reference_data/domain/entities/reference_options.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class AddTeamScreen extends ConsumerStatefulWidget {
  const AddTeamScreen({super.key});

  @override
  ConsumerState<AddTeamScreen> createState() => _AddTeamScreenState();
}

class _AddTeamScreenState extends ConsumerState<AddTeamScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _showPassword = false;
  String _selectedCode = '+91';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
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
    final formState = ref.read(addTeamControllerProvider);
    if (formState.isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await ref.read(addTeamControllerProvider.notifier).submit(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          mobilePrefix: _selectedCode,
          mobileNumber: _phoneNumberController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    if (ok) {
      _showSnack('Team member created');
      Navigator.pop(context, true);
      return;
    }

    _showSnack(ref.read(addTeamControllerProvider).errorMessage ?? 'Couldn\'t create team member.');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final formState = ref.watch(addTeamControllerProvider);
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
                    'Add New Team Member',
                    style: AppFonts.inter(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
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
                'Fill the details and click save.',
                style: AppFonts.inter(
                  fontSize: helperSize,
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _fieldLabel(context, 'Full Name*', labelSize),
                        const SizedBox(height: 8),
                        _textField(
                          context,
                          controller: _nameController,
                          hint: 'John Doe',
                          icon: Icons.person_rounded,
                          fontSize: inputSize,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        _fieldLabel(context, 'Email*', labelSize),
                        const SizedBox(height: 8),
                        _textField(
                          context,
                          controller: _emailController,
                          hint: 'john@example.com',
                          icon: Icons.email_rounded,
                          fontSize: inputSize,
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel(context, 'Code', labelSize),
                                  const SizedBox(height: 8),
                                  formState.isLoadingPrefixes
                                      ? SizedBox(
                                          height: 56,
                                          child: _loadingField(context),
                                        )
                                      : InkWell(
                                          onTap: _pickPrefix,
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          child: Container(
                                            height: 56,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                            ),
                                            decoration: BoxDecoration(
                                              color: cs.surface,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: cs.outline.withOpacity(0.3),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.flag_outlined,
                                                  color: cs.primary,
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    _selectedCode,
                                                    style: AppFonts.inter(
                                                      fontSize: inputSize,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                      color: cs.onSurface,
                                                    ),
                                                  ),
                                                ),
                                                Icon(
                                                  Icons.keyboard_arrow_down_rounded,
                                                  color: cs.onSurface
                                                      .withOpacity(0.6),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel(context, 'Mobile', labelSize),
                                  const SizedBox(height: 8),
                                  _textField(
                                    context,
                                    controller: _phoneNumberController,
                                    hint: '9876543210',
                                    icon: Icons.phone_rounded,
                                    fontSize: inputSize,
                                    keyboardType: TextInputType.phone,
                                    validator: (v) => v == null || v.trim().isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _fieldLabel(context, 'Username*', labelSize),
                        const SizedBox(height: 8),
                        _textField(
                          context,
                          controller: _usernameController,
                          hint: 'masana1',
                          icon: Icons.alternate_email_rounded,
                          fontSize: inputSize,
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        _fieldLabel(context, 'Password*', labelSize),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: !_showPassword,
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Required' : null,
                          style: AppFonts.inter(
                            fontSize: inputSize,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                          decoration: _inputDecoration(
                            context,
                            hint: '••••••',
                            prefixIcon: Icon(
                              Icons.lock_rounded,
                              color: cs.primary,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  updateLocalUiState(this, () => _showPassword = !_showPassword),
                              icon: Icon(
                                _showPassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: cs.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 96),
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
                    onPressed: formState.isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.onSurface.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppFonts.inter(
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
                    onPressed: formState.isSubmitting ? null : _submit,
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
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(cs.onPrimary),
                            ),
                          )
                        : Text(
                            'Save',
                            style: AppFonts.inter(
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

  Future<void> _pickPrefix() async {
    final formState = ref.read(addTeamControllerProvider);
    if (formState.isLoadingPrefixes) return;
    final prefixes = formState.prefixes;
    if (prefixes.isEmpty) {
      _showSnack('No mobile prefixes available.');
      return;
    }

    final picked = await _showSearchableSheet<MobilePrefixOption>(
      title: 'Select Mobile Prefix',
      items: prefixes,
      labelFor: (item) => '${item.code} (${item.countryCode})',
      trailingFor: (item) => item.countryCode,
    );

    if (!mounted || picked == null) return;
    updateLocalUiState(this, () {
      _selectedCode = picked.code;
    });
  }

  Widget _fieldLabel(BuildContext context, String label, double fontSize) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      label,
      style: AppFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: cs.onSurface,
      ),
    );
  }

  Widget _loadingField(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withOpacity(0.3)),
      ),
      alignment: Alignment.center,
      child: SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: cs.surface,
      hintText: hint,
      hintStyle: AppFonts.inter(
        color: cs.onSurface.withOpacity(0.6),
      ),
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.outline.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: cs.primary, width: 2),
      ),
    );
  }

  Widget _textField(
    BuildContext context, {
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required double fontSize,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    Widget? suffixIcon,
  }) {
    final cs = Theme.of(context).colorScheme;
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: AppFonts.inter(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: cs.onSurface,
      ),
      decoration: _inputDecoration(
        context,
        hint: hint,
        prefixIcon: Icon(icon, color: cs.primary),
        suffixIcon: suffixIcon,
      ),
    );
  }
}

