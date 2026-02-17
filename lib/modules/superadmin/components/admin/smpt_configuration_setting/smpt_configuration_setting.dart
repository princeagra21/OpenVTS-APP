// screens/settings/smtp_config_settings_screen.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SmtpConfigSettingsScreen extends StatelessWidget {
  const SmtpConfigSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "SMTP Configuration",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [const SmtpConfigHeader(), const SizedBox(height: 24)],
        ),
      ),
    );
  }
}

class SmtpConfigHeader extends StatefulWidget {
  const SmtpConfigHeader({super.key});

  @override
  State<SmtpConfigHeader> createState() => _SmtpConfigHeaderState();
}

class _SmtpConfigHeaderState extends State<SmtpConfigHeader> {
  // Postman-confirmed endpoints:
  // - GET /superadmin/smtpsettings
  // - PATCH /superadmin/smtpsettings
  // - POST /superadmin/testsmtp
  // Also present in collection (not used here): GET/PATCH /superadmin/smtpconfig/1.
  bool smtpEnabled = true;
  bool tlsEnabled = true;

  final TextEditingController _hostController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _fromEmailController = TextEditingController();
  final TextEditingController _fromNameController = TextEditingController(
    text: 'FleetStack',
  );
  final TextEditingController _replyToController = TextEditingController();

  bool _loading = false;
  bool _saving = false;
  bool _testing = false;
  bool _loadErrorShown = false;
  bool _saveErrorShown = false;
  bool _testErrorShown = false;
  DateTime? _lastSaveAt;

  CancelToken? _loadToken;
  CancelToken? _saveToken;
  CancelToken? _testToken;

  ApiClient? _apiClient;
  SuperadminRepository? _repo;

  SuperadminRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= SuperadminRepository(api: _apiClient!);
    return _repo!;
  }

  @override
  void initState() {
    super.initState();
    _loadSmtp();
  }

  @override
  void dispose() {
    _loadToken?.cancel('SMTP screen disposed');
    _saveToken?.cancel('SMTP screen disposed');
    _testToken?.cancel('SMTP screen disposed');
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _fromEmailController.dispose();
    _fromNameController.dispose();
    _replyToController.dispose();
    super.dispose();
  }

  Object? _pickRaw(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      if (map.containsKey(key) && map[key] != null) return map[key];
    }
    return null;
  }

  String _pickString(Map<String, dynamic> map, List<String> keys) {
    final value = _pickRaw(map, keys);
    return value == null ? '' : value.toString().trim();
  }

  bool? _pickBool(Map<String, dynamic> map, List<String> keys) {
    final value = _pickRaw(map, keys);
    if (value == null) return null;
    if (value is bool) return value;
    final s = value.toString().trim().toLowerCase();
    if (s == 'true' || s == '1' || s == 'yes') return true;
    if (s == 'false' || s == '0' || s == 'no') return false;
    return null;
  }

  Future<void> _loadSmtp() async {
    _loadToken?.cancel('Reload smtp settings');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final res = await _repoOrCreate().getSmtpConfig(cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (map) {
          setState(() {
            _loading = false;
            _loadErrorShown = false;

            final isActive = _pickBool(map, ['isActive', 'enabled', 'active']);
            if (isActive != null) smtpEnabled = isActive;

            final type = _pickString(map, ['type', 'encryption']);
            if (type.isNotEmpty) {
              final t = type.toLowerCase();
              tlsEnabled = t.contains('ssl') || t.contains('tls');
            }

            final host = _pickString(map, ['host', 'smtpHost']);
            if (host.isNotEmpty) _hostController.text = host;

            final port = _pickString(map, ['port', 'smtpPort']);
            if (port.isNotEmpty) _portController.text = port;

            final username = _pickString(map, ['username', 'user']);
            if (username.isNotEmpty) _usernameController.text = username;

            final password = _pickString(map, ['password', 'appPassword']);
            if (password.isNotEmpty) _passwordController.text = password;

            final email = _pickString(map, [
              'email',
              'fromEmail',
              'senderEmail',
            ]);
            if (email.isNotEmpty) _fromEmailController.text = email;

            final senderName = _pickString(map, ['senderName', 'fromName']);
            if (senderName.isNotEmpty) _fromNameController.text = senderName;

            final replyTo = _pickString(map, ['replyTo', 'replyToEmail']);
            if (replyTo.isNotEmpty) _replyToController.text = replyTo;
          });
        },
        failure: (err) {
          setState(() => _loading = false);
          if (_loadErrorShown) return;
          _loadErrorShown = true;
          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load SMTP settings.'
              : "Couldn't load SMTP settings. Showing fallback values.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
      if (_loadErrorShown) return;
      _loadErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Couldn't load SMTP settings. Showing fallback values.",
          ),
        ),
      );
    }
  }

  Future<bool> _saveSmtp({bool showSuccess = true}) async {
    if (_saving) return false;

    final now = DateTime.now();
    final last = _lastSaveAt;
    if (last != null && now.difference(last).inMilliseconds < 800) {
      return false;
    }
    _lastSaveAt = now;

    _saveToken?.cancel('Retry smtp save');
    final token = CancelToken();
    _saveToken = token;

    if (!mounted) return false;
    setState(() => _saving = true);

    final payload = <String, dynamic>{
      'type': tlsEnabled ? 'SSL' : 'NONE',
      'host': _hostController.text.trim(),
      'senderName': _fromNameController.text.trim(),
      'port': _portController.text.trim(),
      'email': _fromEmailController.text.trim(),
      'replyTo': _replyToController.text.trim(),
      'username': _usernameController.text.trim(),
      'password': _passwordController.text,
      'isActive': smtpEnabled.toString(),
    };

    try {
      final res = await _repoOrCreate().updateSmtpConfig(
        payload,
        cancelToken: token,
      );
      if (!mounted) return false;

      return res.when(
        success: (_) {
          setState(() {
            _saving = false;
            _saveErrorShown = false;
          });
          if (showSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Saved')));
          }
          return true;
        },
        failure: (err) {
          setState(() => _saving = false);
          if (!_saveErrorShown) {
            _saveErrorShown = true;
            final msg =
                (err is ApiException &&
                    (err.statusCode == 401 || err.statusCode == 403))
                ? 'Not authorized to save SMTP settings.'
                : "Couldn't save SMTP settings.";
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(msg)));
          }
          return false;
        },
      );
    } catch (_) {
      if (!mounted) return false;
      setState(() => _saving = false);
      if (!_saveErrorShown) {
        _saveErrorShown = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't save SMTP settings.")),
        );
      }
      return false;
    }
  }

  Future<void> _toggleAndPersist({
    required bool currentValue,
    required bool nextValue,
    required ValueChanged<bool> setLocalValue,
  }) async {
    if (_saving) return;
    setState(() => setLocalValue(nextValue));
    final ok = await _saveSmtp(showSuccess: false);
    if (!ok && mounted) {
      setState(() => setLocalValue(currentValue));
    }
  }

  Future<void> _sendTestEmail() async {
    if (_testing || _saving) return;

    _testToken?.cancel('Retry smtp test');
    final token = CancelToken();
    _testToken = token;

    if (!mounted) return;
    setState(() => _testing = true);

    final email = _fromEmailController.text.trim().isNotEmpty
        ? _fromEmailController.text.trim()
        : _usernameController.text.trim();

    try {
      final res = await _repoOrCreate().sendTestSmtp(
        email: email,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (_) {
          setState(() {
            _testing = false;
            _testErrorShown = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Test email sent')));
        },
        failure: (err) {
          setState(() => _testing = false);
          if (_testErrorShown) return;
          _testErrorShown = true;
          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to send test email.'
              : "Couldn't send test email.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _testing = false);
      if (_testErrorShown) return;
      _testErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't send test email.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // TOP BUTTONS (Save & Test)
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ElevatedButton.icon(
                  onPressed: _saving
                      ? null
                      : () => _saveSmtp(showSuccess: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: EdgeInsets.symmetric(
                      horizontal: hp + 2,
                      vertical: hp - 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: SizedBox(
                    width: AdaptiveUtils.getIconSize(width),
                    height: AdaptiveUtils.getIconSize(width),
                    child: _saving
                        ? CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary,
                            ),
                          )
                        : Icon(
                            Icons.save_outlined,
                            color: colorScheme.onPrimary,
                            size: AdaptiveUtils.getIconSize(width),
                          ),
                  ),
                  label: Text(
                    "Save Configuration",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _testing ? null : _sendTestEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    padding: EdgeInsets.symmetric(
                      horizontal: hp + 2,
                      vertical: hp - 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: SizedBox(
                    width: AdaptiveUtils.getIconSize(width),
                    height: AdaptiveUtils.getIconSize(width),
                    child: _testing
                        ? CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.onPrimary,
                            ),
                          )
                        : Icon(
                            Icons.email_outlined,
                            color: colorScheme.onPrimary,
                            size: AdaptiveUtils.getIconSize(width),
                          ),
                  ),
                  label: Text(
                    "Send Test Email",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // TITLE
          Text(
            "SMTP Configuration",
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getTitleFontSize(width),
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withOpacity(0.87),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Configure your email server settings",
            style: GoogleFonts.inter(
              fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
              fontWeight: FontWeight.w800,
              color: colorScheme.onSurface.withOpacity(0.9),
            ),
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),

          const SizedBox(height: 24),

          // Enable SMTP Service
          _buildSection(
            context: context,
            icon: Icons.email_rounded,
            title: "Enable SMTP Service",
            subtitle: "SMTP service is active and will send emails",
            trailing: Transform.scale(
              scale: 0.7,
              child: Switch(
                value: smtpEnabled,
                activeColor: colorScheme.onPrimary,
                activeTrackColor: colorScheme.primary,
                inactiveThumbColor: colorScheme.onPrimary,
                inactiveTrackColor: colorScheme.primary.withOpacity(0.3),
                onChanged: _saving
                    ? null
                    : (v) => _toggleAndPersist(
                        currentValue: smtpEnabled,
                        nextValue: v,
                        setLocalValue: (value) => smtpEnabled = value,
                      ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Configure Your SMTP Server
          _buildSection(
            context: context,
            icon: Icons.settings_rounded,
            title: "Configure Your SMTP Server",
            subtitle:
                "Enter your custom SMTP server details below to send system emails and notifications.",
          ),

          const SizedBox(height: 24),

          // SMTP Server Configuration Fields
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
              border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputField(
                  context,
                  label: "SMTP HOST",
                  hint: "e.g., smtp.gmail.com",
                  controller: _hostController,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  context,
                  label: "SMTP PORT",
                  hint: "Common: 587, 465, 25",
                  controller: _portController,
                ),
                const SizedBox(height: 8),
                Text(
                  "Common: 587, 465, 25",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 24),

                // TLS/SSL Switch
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Use TLS/SSL Encryption",
                        style: GoogleFonts.inter(
                          fontSize:
                              AdaptiveUtils.getSubtitleFontSize(width) - 3,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                      Transform.scale(
                        scale: 0.7,
                        child: Switch(
                          value: tlsEnabled,
                          activeColor: colorScheme.onPrimary,
                          activeTrackColor: colorScheme.primary,
                          inactiveThumbColor: colorScheme.onPrimary,
                          inactiveTrackColor: colorScheme.primary.withOpacity(
                            0.3,
                          ),
                          onChanged: _saving
                              ? null
                              : (v) => _toggleAndPersist(
                                  currentValue: tlsEnabled,
                                  nextValue: v,
                                  setLocalValue: (value) => tlsEnabled = value,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildInputField(
                  context,
                  label: "USERNAME / EMAIL",
                  hint:
                      "SMTP authentication username (usually your email address)",
                  controller: _usernameController,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  context,
                  label: "PASSWORD / APP PASSWORD",
                  hint: "For Gmail/Google Workspace, use an App Password",
                  obscureText: true,
                  controller: _passwordController,
                ),
                const SizedBox(height: 8),
                Text(
                  "For Gmail/Google Workspace, use an App Password",
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sender Information
          _buildSection(
            context: context,
            icon: Icons.person_rounded,
            title: "Sender Information",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInputField(
                  context,
                  label: "FROM EMAIL ADDRESS",
                  hint:
                      "This email address will appear as the sender for all system emails",
                  controller: _fromEmailController,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  context,
                  label: "FROM NAME",
                  hint:
                      "Display name that will appear alongside the email address",
                  controller: _fromNameController,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  context,
                  label: "REPLY-TO EMAIL (Optional)",
                  hint:
                      "Email address where replies should be sent (if different from sender)",
                  controller: _replyToController,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Widget? child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: AdaptiveUtils.getTitleFontSize(width) + 5,
                color: colorScheme.primary.withOpacity(0.87),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface.withOpacity(0.87),
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
          if (child != null) ...[const SizedBox(height: 16), child],
        ],
      ),
    );
  }

  Widget _buildInputField(
    BuildContext context, {
    required String label,
    required String hint,
    required TextEditingController controller,
    bool obscureText = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: AdaptiveUtils.getTitleFontSize(width),
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface.withOpacity(0.87),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          obscureText: obscureText,
          controller: controller,
          style: GoogleFonts.inter(
            color: colorScheme.onSurface,
            fontSize: AdaptiveUtils.getTitleFontSize(width),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: colorScheme.onSurface.withOpacity(0.6),
              fontSize: AdaptiveUtils.getTitleFontSize(width),
            ),
            filled: true,
            fillColor: Colors.transparent,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.outline.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
