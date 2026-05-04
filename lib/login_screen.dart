// login_screen.dart
import 'dart:async';

import 'package:animations/animations.dart';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/api_base_url_config.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/auth_repository.dart';
import 'package:fleet_stack/core/services/push_notifications_service.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/config/server_configuration_sheet.dart';
import 'package:fleet_stack/core/utils/app_logo.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isForgot = false;
  bool _isForgotSubmitting = false;
  bool _isLoggingIn = false;
  bool _obscurePassword = true;
  String? _forgotPasswordMessage;

  CancelToken? _loginToken;
  ApiClient? _api;
  AuthRepository? _authRepo;

  Future<void> _syncApiClientBaseUrl() async {
    final effectiveBaseUrl = ApiBaseUrlConfig.instance.effectiveBaseUrl;
    if (_api != null) {
      _api!.updateBaseUrl(effectiveBaseUrl);
      return;
    }
  }

  Future<void> _openServerConfiguration() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ServerConfigurationSheet(),
    );

    if (!mounted || result == null) return;

    await _syncApiClientBaseUrl();

    final message = switch (result) {
      'saved' => 'Server configuration saved',
      'reset' => 'Server configuration reset to default',
      _ => null,
    };
    if (message != null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
    }
  }

  AuthRepository _repoOrCreate() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _authRepo ??= AuthRepository(
      api: _api!,
      tokenStorage: TokenStorage.defaultInstance(),
    );
    return _authRepo!;
  }

  String? _targetPathForRole(String? backendRole) {
    final normalized = (backendRole ?? '').trim().toLowerCase();
    if (normalized.contains('super')) return '/superadmin/home';
    if (normalized.contains('admin')) return '/admin/home';
    if (normalized.contains('user')) return '/user/home';
    if (normalized.contains('driver')) return null;
    return null;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitForgotPassword() async {
    if (_isForgotSubmitting) return;

    final identifier = _emailController.text.trim();
    if (identifier.isEmpty) {
      _showSnack('Please enter your email or username.');
      return;
    }

    _loginToken?.cancel('Retry forgot password');
    final token = CancelToken();
    _loginToken = token;

    if (!mounted) return;
    setState(() {
      _isForgotSubmitting = true;
      _forgotPasswordMessage = null;
    });

    try {
      final message = await _repoOrCreate().forgotPassword(
        identifier,
        cancelToken: token,
      );
      if (!mounted) return;
      setState(() {
        _isForgotSubmitting = false;
        _forgotPasswordMessage = message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _isForgotSubmitting = false);
      final message = error is ApiException && error.message.trim().isNotEmpty
          ? error.message
          : 'Unable to send reset link. Please try again.';
      _showSnack(message);
    }
  }

  Future<void> _handlePushAfterLogin() async {
    final service = PushNotificationsService.instance;
    final shouldPrompt = await service.shouldPromptAfterLogin();
    if (!mounted) return;

    if (!shouldPrompt) {
      unawaited(service.syncOnAppStart());
      return;
    }

    final enable = await showDialog<bool>(
      context: context,
      builder: (_) => const _EnableNotificationsDialog(),
    );
    if (!mounted) return;

    if (enable == true) {
      final result = await service.enable();
      if (!mounted) return;
      result.when(
        success: (_) {},
        failure: (error) {
          final message =
              error is ApiException && error.message.trim().isNotEmpty
              ? error.message
              : 'Push notifications could not be enabled.';
          _showSnack(message);
        },
      );
      return;
    }

    await service.markPromptDeclined();
  }

  Future<void> _submitLogin() async {
    if (_isLoggingIn) return;

    final identifier = _emailController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.trim().isEmpty) {
      _showSnack('Please enter email and password.');
      return;
    }

    _loginToken?.cancel('Retry login');
    final token = CancelToken();
    _loginToken = token;

    if (!mounted) return;
    setState(() => _isLoggingIn = true);

    try {
      final res = await _repoOrCreate().loginWithContext(
        identifier: identifier,
        password: password,
        cancelToken: token,
      );

      if (!mounted) return;

      res.when(
        success: (ctx) async {
          final target = _targetPathForRole(ctx.role);
          if (target == null) {
            await TokenStorage.defaultInstance().clear();
            if (!mounted) return;
            setState(() => _isLoggingIn = false);
            _showSnack('This account role is not supported in this app.');
            return;
          }

          await _handlePushAfterLogin();
          if (!mounted) return;
          setState(() => _isLoggingIn = false);
          context.go(target);
        },
        failure: (error) {
          setState(() => _isLoggingIn = false);
          final message =
              (error is ApiException &&
                  (error.statusCode == 401 || error.statusCode == 403))
              ? 'Invalid credentials.'
              : (error is ApiException && error.message.trim().isNotEmpty)
              ? error.message
              : 'Login failed. Please try again.';
          _showSnack(message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoggingIn = false);
      _showSnack('Login failed. Please try again.');
    }
  }

  @override
  void dispose() {
    _loginToken?.cancel('LoginScreen disposed');
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Reusable minimal InputDecoration
  InputDecoration _minimalDecoration(
    BuildContext context, {
    String? hint,
    bool isPassword = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: colorScheme.onSurface.withOpacity(0.5),
        fontSize: AdaptiveUtils.getTitleFontSize(
          MediaQuery.of(context).size.width,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIconConstraints: const BoxConstraints(minWidth: 48),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      suffixIcon: isPassword
          ? IconButton(
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: colorScheme.primary,
              ),
            )
          : null,
    );
  }

  Widget _buildLoginForm(ColorScheme colorScheme, double labelSize) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoAsset = AppLogo.assetFor(context);

    Widget inputField({
      required String label,
      required TextEditingController controller,
      required String hint,
      required IconData icon,
      TextInputType? keyboardType,
      bool obscure = false,
      bool password = false,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: labelSize,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: isDark ? colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: obscure,
              style: GoogleFonts.inter(
                fontSize: labelSize,
                color: colorScheme.onSurface,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  color: colorScheme.onSurface.withValues(alpha: 0.45),
                  fontSize: labelSize,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                prefixIcon: Icon(icon, color: colorScheme.onSurface.withValues(alpha: 0.7)),
                suffixIcon: password
                    ? IconButton(
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      )
                    : null,
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            onPressed: _openServerConfiguration,
            tooltip: 'Server configuration',
            icon: Icon(Icons.settings_rounded, color: colorScheme.onSurface),
          ),
        ),
        const SizedBox(height: 30),
        Center(
          child: Image.asset(
            logoAsset,
            width: (MediaQuery.of(context).size.width * 0.5).clamp(160, 230),
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) {
              final alt = isDark
                  ? 'assets/images/logos/open_vts_logo_dark.png'
                  : 'assets/images/logos/open_vts_logo_light.png';
              return Image.asset(
                alt,
                width: (MediaQuery.of(context).size.width * 0.5).clamp(160, 230),
                fit: BoxFit.contain,
                gaplessPlayback: true,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/image/logo.png',
                  width: (MediaQuery.of(context).size.width * 0.42).clamp(120, 180),
                  fit: BoxFit.contain,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 30),
        const SizedBox(height: 10),
        inputField(
          label: 'Email or Username',
          controller: _emailController,
          hint: 'Enter your email',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 18),
        inputField(
          label: 'Password',
          controller: _passwordController,
          hint: 'Enter your password',
          icon: Icons.lock_outline,
          obscure: _obscurePassword,
          password: true,
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _isForgot = true;
              });
            },
            child: Text(
              "Forgot Password?",
              style: GoogleFonts.inter(
                fontSize: labelSize - 2,
                color: colorScheme.onSurface.withValues(alpha: 0.75),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          child: GestureDetector(
            onTap: _isLoggingIn ? null : _submitLogin,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: _isLoggingIn
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        const SizedBox(width: 24),
                        Expanded(
                          child: Text(
                            "Login",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: labelSize + 1,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildForgotForm(ColorScheme colorScheme, double labelSize) {
    if (_forgotPasswordMessage != null) {
      return _buildCheckEmailView(colorScheme, labelSize);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with Close
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Forgot Password',
              style: GoogleFonts.inter(
                fontSize: labelSize + 4,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            GestureDetector(
          onTap: () {
            setState(() {
              _isForgot = false;
              _forgotPasswordMessage = null;
            });
          },
              child: Icon(
                Icons.close,
                size: 28,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your email to reset',
          style: GoogleFonts.inter(
            fontSize: labelSize - 2,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 32),

        // Email Field
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.text,
          style: GoogleFonts.inter(
            fontSize: labelSize,
            color: colorScheme.onSurface,
          ),
          decoration: _minimalDecoration(
            context,
            hint: "Email or username",
          ).copyWith(
            prefixIcon: Icon(
              Icons.email_outlined,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Buttons
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isForgot = false;
                    _forgotPasswordMessage = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
                      "Cancel",
                      style: GoogleFonts.inter(
                        fontSize: labelSize,
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: _isForgotSubmitting ? null : _submitForgotPassword,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: _isForgotSubmitting
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Text(
                            "Proceed",
                            style: GoogleFonts.inter(
                              fontSize: labelSize,
                              color: colorScheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCheckEmailView(ColorScheme colorScheme, double labelSize) {
    final message =
        _forgotPasswordMessage ??
        'If an account with that identifier exists, a password reset link has been sent.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Check Your Email',
              style: GoogleFonts.inter(
                fontSize: labelSize + 4,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isForgot = false;
                  _forgotPasswordMessage = null;
                });
              },
              child: Icon(
                Icons.close,
                size: 28,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          message,
          style: GoogleFonts.inter(
            fontSize: labelSize - 1,
            color: colorScheme.onSurface.withOpacity(0.75),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.primary.withValues(alpha: 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.mark_email_read_outlined, color: colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'We have sent instructions if the account exists.',
                style: GoogleFonts.inter(
                  fontSize: labelSize - 1,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        GestureDetector(
          onTap: () {
            setState(() {
              _isForgot = false;
              _forgotPasswordMessage = null;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                'Back to Sign In',
                style: GoogleFonts.inter(
                  fontSize: labelSize,
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double labelSize = AdaptiveUtils.getTitleFontSize(w);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: isDark ? colorScheme.background : Colors.white,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 16),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: PageTransitionSwitcher(
                        duration: const Duration(milliseconds: 500),
                        transitionBuilder: (child, animation, secondaryAnimation) {
                          return SharedAxisTransition(
                            animation: animation,
                            secondaryAnimation: secondaryAnimation,
                            transitionType: SharedAxisTransitionType.horizontal,
                            child: child,
                          );
                        },
                        child: _isForgot
                            ? Container(
                                key: const ValueKey('forgot'),
                                margin: const EdgeInsets.only(top: 60),
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: _buildForgotForm(colorScheme, labelSize),
                              )
                            : Container(
                                key: const ValueKey('login'),
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildLoginForm(colorScheme, labelSize),
                              ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EnableNotificationsDialog extends StatelessWidget {
  const _EnableNotificationsDialog();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications_active_outlined,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Enable notifications?',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'You can turn this on now and change it later from Notifications.',
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: colorScheme.onSurface.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.onSurface,
                      side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.2),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Not now',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Enable',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
