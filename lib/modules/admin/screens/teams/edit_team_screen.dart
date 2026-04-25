import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_team_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_teams_repository.dart';
import 'package:fleet_stack/core/repositories/common_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditTeamScreen extends StatefulWidget {
  final AdminTeamListItem team;

  const EditTeamScreen({super.key, required this.team});

  @override
  State<EditTeamScreen> createState() => _EditTeamScreenState();
}

class _EditTeamScreenState extends State<EditTeamScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneNumberController;
  late final TextEditingController _usernameController;

  bool _submitting = false;
  bool _loadingPrefixes = false;
  String _selectedCode = '+91';

  ApiClient? _apiClient;
  AdminTeamsRepository? _repo;
  CommonRepository? _commonRepo;
  CancelToken? _prefixesToken;
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
    _loadPrefixes();
  }

  @override
  void dispose() {
    _prefixesToken?.cancel('Edit team disposed');
    _nameController.dispose();
    _emailController.dispose();
    _phoneNumberController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  ApiClient _apiOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    return _apiClient!;
  }

  AdminTeamsRepository _repoOrCreate() {
    _repo ??= AdminTeamsRepository(api: _apiOrCreate());
    return _repo!;
  }

  CommonRepository _commonRepoOrCreate() {
    _commonRepo ??= CommonRepository(api: _apiOrCreate());
    return _commonRepo!;
  }

  Future<void> _loadPrefixes() async {
    _prefixesToken?.cancel('Reload prefixes');
    final token = CancelToken();
    _prefixesToken = token;

    if (!mounted) return;
    setState(() => _loadingPrefixes = true);

    final res = await _commonRepoOrCreate().getMobilePrefixes(cancelToken: token);
    if (!mounted || token.isCancelled) return;

    res.when(
      success: (items) {
        setState(() {
          _prefixes = items;
          _loadingPrefixes = false;
          if (_selectedCode.trim().isEmpty && items.isNotEmpty) {
            _selectedCode = items.first.code;
          }
        });
      },
      failure: (_) {
        if (!mounted) return;
        setState(() => _loadingPrefixes = false);
      },
    );
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
                              style: GoogleFonts.inter(
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
                          fillColor: cs.surfaceVariant.withOpacity(0.3),
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
                                style: GoogleFonts.inter(
                                  fontSize: fs - 1,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface,
                                ),
                              ),
                              trailing: trailing == null || trailing.isEmpty
                                  ? null
                                  : Text(
                                      trailing,
                                      style: GoogleFonts.inter(
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
    if (_submitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _submitting = true);
    try {
      final result = await _repoOrCreate().updateTeam(
        teamId: widget.team.id,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        mobilePrefix: _selectedCode,
        mobileNumber: _phoneNumberController.text.trim(),
        username: _usernameController.text.trim(),
      );

      if (!mounted) return;
      result.when(
        success: (_) {
          _showSnack('Team member updated');
          Navigator.pop(context, true);
        },
        failure: (err) {
          final msg = err is ApiException ? err.message : err.toString();
          _showSnack(msg);
        },
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                    style: GoogleFonts.roboto(
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
                style: GoogleFonts.roboto(
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
                          loading: _loadingPrefixes,
                          onTap: () async {
                            if (_loadingPrefixes) return;
                            final picked = await _showSearchableSheet<MobilePrefixOption>(
                              title: 'Select Code',
                              items: _prefixes,
                              labelFor: (item) => item.countryCode,
                              trailingFor: (item) => item.code,
                            );
                            if (!mounted || picked == null) return;
                            setState(() => _selectedCode = picked.code);
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
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: cs.onSurface.withOpacity(0.2)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.roboto(
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
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _submitting
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
                            style: GoogleFonts.roboto(
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
      style: GoogleFonts.inter(fontSize: size, fontWeight: FontWeight.w600),
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
          hintStyle: GoogleFonts.inter(
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
                style: GoogleFonts.inter(fontSize: size, color: cs.onSurface),
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
