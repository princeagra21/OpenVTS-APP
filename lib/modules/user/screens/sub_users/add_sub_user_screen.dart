import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/common_repository.dart';
import 'package:fleet_stack/core/repositories/user_subusers_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AddSubUserScreen extends StatefulWidget {
  const AddSubUserScreen({super.key});

  @override
  State<AddSubUserScreen> createState() => _AddSubUserScreenState();
}

class _AddSubUserScreenState extends State<AddSubUserScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isActive = true;
  bool _obscurePassword = true;
  bool _loadingRefs = false;
  bool _saving = false;
  bool _loadErrorShown = false;

  List<MobilePrefixOption> _prefixes = const <MobilePrefixOption>[];
  String? _selectedPrefix;

  ApiClient? _api;
  CommonRepository? _commonRepo;
  UserSubUsersRepository? _subUsersRepo;
  CancelToken? _refsToken;
  CancelToken? _saveToken;

  @override
  void initState() {
    super.initState();
    _loadPrefixes();
  }

  @override
  void dispose() {
    _refsToken?.cancel('Add sub-user disposed');
    _saveToken?.cancel('Add sub-user disposed');
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  CommonRepository _commonOrCreate() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _commonRepo ??= CommonRepository(api: _api!);
    return _commonRepo!;
  }

  UserSubUsersRepository _subUsersOrCreate() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _subUsersRepo ??= UserSubUsersRepository(api: _api!);
    return _subUsersRepo!;
  }

  Future<void> _loadPrefixes() async {
    _refsToken?.cancel('Reload mobile prefixes');
    final token = CancelToken();
    _refsToken = token;

    if (!mounted) return;
    setState(() => _loadingRefs = true);

    try {
      final res = await _commonOrCreate().getMobilePrefixes(cancelToken: token);
      if (!mounted || token.isCancelled) return;
      res.when(
        success: (items) {
          String? selected;
          for (final item in items) {
            if (item.countryCode == 'IN') {
              selected = item.code.replaceFirst('++', '+');
              break;
            }
          }
          selected ??= items.isNotEmpty
              ? items.first.code.replaceFirst('++', '+')
              : null;

          setState(() {
            _prefixes = items;
            _selectedPrefix = selected;
            _loadingRefs = false;
            _loadErrorShown = false;
          });
        },
        failure: (error) {
          setState(() => _loadingRefs = false);
          if (_loadErrorShown) return;
          _loadErrorShown = true;
          var msg = "Couldn't load mobile prefixes.";
          if (error is ApiException && error.message.trim().isNotEmpty) {
            msg = error.message;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRefs = false);
      if (_loadErrorShown) return;
      _loadErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load mobile prefixes.")),
      );
    }
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_formKey.currentState!.validate()) return;
    if ((_selectedPrefix ?? '').trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mobile prefix is required.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _saving = true);

    _saveToken?.cancel('Restart add sub-user');
    final token = CancelToken();
    _saveToken = token;

    final payload = <String, dynamic>{
      'name': _nameController.text.trim(),
      'username': _usernameController.text.trim(),
      'email': _emailController.text.trim(),
      'mobilePrefix': (_selectedPrefix ?? '').replaceFirst('++', '+').trim(),
      'mobileNumber': _mobileController.text
          .replaceAll(RegExp(r'\D'), '')
          .trim(),
      'password': _passwordController.text.trim(),
      'isActive': _isActive,
    };

    try {
      final res = await _subUsersOrCreate().createSubUser(
        payload,
        cancelToken: token,
      );
      if (!mounted || token.isCancelled) return;

      res.when(
        success: (_) {
          Navigator.pop(context, true);
        },
        failure: (error) {
          if (!mounted) return;
          setState(() => _saving = false);
          var msg = "Couldn't add sub-user.";
          if (error is ApiException && error.message.trim().isNotEmpty) {
            msg = error.message;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't add sub-user.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(width) * 1.2;
    final double titleSize = AdaptiveUtils.getSubtitleFontSize(width);
    final double labelSize = AdaptiveUtils.getTitleFontSize(width);

    InputDecoration inputDecoration(String hint, IconData icon) {
      return InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: cs.onSurface.withOpacity(0.5),
          fontSize: labelSize,
        ),
        prefixIcon: Icon(icon, color: cs.primary),
        filled: true,
        fillColor: cs.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
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

    Widget fieldLabel(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: labelSize,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Sub-user',
                    style: GoogleFonts.inter(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        fieldLabel('Name *'),
                        TextFormField(
                          controller: _nameController,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Required'
                              : null,
                          decoration: inputDecoration(
                            'Enter name',
                            Icons.person_outline,
                          ),
                        ),
                        const SizedBox(height: 16),
                        fieldLabel('Username *'),
                        TextFormField(
                          controller: _usernameController,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Required'
                              : null,
                          decoration: inputDecoration(
                            'Enter username',
                            Icons.alternate_email,
                          ),
                        ),
                        const SizedBox(height: 16),
                        fieldLabel('Email *'),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Required'
                              : null,
                          decoration: inputDecoration(
                            'Enter email',
                            Icons.email_outlined,
                          ),
                        ),
                        const SizedBox(height: 16),
                        fieldLabel('Mobile Prefix *'),
                        if (_loadingRefs)
                          const AppShimmer(
                            width: double.infinity,
                            height: 56,
                            radius: 16,
                          )
                        else
                          DropdownButtonFormField<String>(
                            initialValue: _selectedPrefix,
                            decoration: inputDecoration(
                              'Select prefix',
                              Icons.flag_outlined,
                            ),
                            items: _prefixes
                                .map(
                                  (item) => DropdownMenuItem<String>(
                                    value: item.code.replaceFirst('++', '+'),
                                    child: Text(
                                      '${item.countryCode} ${item.code.replaceFirst('++', '+')}',
                                      style: GoogleFonts.inter(
                                        fontSize: labelSize,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (value) =>
                                setState(() => _selectedPrefix = value),
                            validator: (value) =>
                                (value == null || value.trim().isEmpty)
                                ? 'Required'
                                : null,
                          ),
                        const SizedBox(height: 16),
                        fieldLabel('Mobile Number *'),
                        TextFormField(
                          controller: _mobileController,
                          keyboardType: TextInputType.phone,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Required'
                              : null,
                          decoration: inputDecoration(
                            'Enter mobile number',
                            Icons.phone_outlined,
                          ),
                        ),
                        const SizedBox(height: 16),
                        fieldLabel('Password *'),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          validator: (value) =>
                              (value == null || value.trim().isEmpty)
                              ? 'Required'
                              : null,
                          decoration:
                              inputDecoration(
                                'Enter password',
                                Icons.lock_outline,
                              ).copyWith(
                                suffixIcon: IconButton(
                                  onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword,
                                  ),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: cs.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ),
                        ),
                        const SizedBox(height: 16),
                        SwitchListTile.adaptive(
                          value: _isActive,
                          onChanged: (value) =>
                              setState(() => _isActive = value),
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                            'Active',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            'Allow this sub-user to sign in immediately',
                            style: GoogleFonts.inter(
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(40),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saving ? null : _save,
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(40),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: _saving
                                    ? const AppShimmer(
                                        width: 84,
                                        height: 16,
                                        radius: 8,
                                      )
                                    : Text(
                                        'Add Sub-user',
                                        style: GoogleFonts.inter(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
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
