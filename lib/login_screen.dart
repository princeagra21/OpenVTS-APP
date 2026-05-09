import 'package:open_vts/app/router/app_route_paths.dart';
import 'package:open_vts/app/app_container.dart';
// login_screen.dart
import 'dart:async';

import 'package:animations/animations.dart';
import 'package:dio/dio.dart';
import 'package:open_vts/core/config/api_base_url_config.dart';
import 'package:open_vts/core/network/api_exception.dart';
import 'package:open_vts/core/repositories/auth_repository.dart';
import 'package:open_vts/core/config/server_configuration_sheet.dart';
import 'package:open_vts/core/utils/app_logo.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/design_system/components/open_vts_components.dart';
import 'package:open_vts/design_system/theme/open_vts_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

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
  AuthRepository? _authRepo;

  Future<void> _syncApiClientBaseUrl() async {
    final effectiveBaseUrl = ApiBaseUrlConfig.instance.effectiveBaseUrl;
    AppContainer.instance.apiClient.updateBaseUrl(effectiveBaseUrl);
  }

  Future<void> _openServerConfiguration() async {
    final result = await OpenVtsModal.showBottomSheet<String>(
      context: context,
      child: const ServerConfigurationSheet(),
    );

    if (!mounted || result == null) return;

    await _syncApiClientBaseUrl();

    final message = switch (result) {
      'saved' => 'Server configuration saved',
      'reset' => 'Server configuration reset to default',
      _ => null,
    };
    if (message != null) {
      OpenVtsFeedback.success(context, message);
    }
  }

  AuthRepository _repoOrCreate() {
    _authRepo ??= AppContainer.instance.authRepository;
    return _authRepo!;
  }

  String? _targetPathForRole(String? backendRole) {
    final normalized = (backendRole ?? '').trim().toLowerCase();
    if (normalized.contains('super')) return AppRoutePaths.superadminHome;
    if (normalized.contains('admin')) return AppRoutePaths.adminHome;
    if (normalized.contains('user')) return AppRoutePaths.userHome;
    if (normalized.contains('driver')) return null;
    return null;
  }

  void _showSnack(String message) {
    if (!mounted) return;
    OpenVtsFeedback.error(context, message);
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
    final service = AppContainer.instance.pushNotificationsService;
    final shouldPrompt = await service.shouldPromptAfterLogin();
    if (!mounted) return;

    if (!shouldPrompt) {
      unawaited(service.syncOnAppStart());
      return;
    }

    final enable = await OpenVtsModal.showConfirmDialog(
      context: context,
      title: 'Enable notifications?',
      message:
          'You can turn this on now and change it later from Notifications.',
      confirmLabel: 'Enable',
      cancelLabel: 'Not now',
      icon: Icons.notifications_active_outlined,
    );
    if (!mounted) return;

    if (enable) {
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
            await AppContainer.instance.tokenStorage.clear();
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

  Widget _buildLoginForm(ColorScheme colorScheme, double labelSize) {
    final logoAsset = AppLogo.assetFor(context);
    final textTheme = Theme.of(context).textTheme;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Track Without Limits',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            letterSpacing: 0,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Powered by You',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        OpenVtsCard(
          padding: const EdgeInsets.all(24),
          backgroundColor: colorScheme.surface,
          borderColor: colorScheme.outline.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          shadowLevel: OpenVtsCardShadowLevel.strong,
          child: Column(
            children: [
              Image.asset(
                logoAsset,
                width: 380,
                height: 60,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),
              OpenVtsTextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                labelText: 'Email or Username',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: colorScheme.onSurface.withOpacity(0.5),
                  size: 20,
                ),
              ),
              const SizedBox(height: 16),
              OpenVtsTextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                labelText: 'Password',
                prefixIcon: Icon(
                  Icons.lock_outline,
                  color: colorScheme.onSurface.withOpacity(0.5),
                  size: 20,
                ),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: colorScheme.onSurface.withOpacity(0.5),
                    size: 20,
                  ),
                ),
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
                    'Forgot Password?',
                    style: textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              OpenVtsButton(
                label: 'Login',
                loading: _isLoggingIn,
                onPressed: _isLoggingIn ? null : _submitLogin,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildForgotForm(ColorScheme colorScheme, double labelSize) {
    final textTheme = Theme.of(context).textTheme;

    if (_forgotPasswordMessage != null) {
      return _buildCheckEmailView(colorScheme, labelSize);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Reset Password',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            letterSpacing: 0,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your email to receive reset instructions',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        OpenVtsCard(
          padding: const EdgeInsets.all(24),
          backgroundColor: colorScheme.surface,
          borderColor: colorScheme.outline.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          shadowLevel: OpenVtsCardShadowLevel.strong,
          child: Column(
            children: [
              OpenVtsTextField(
                controller: _emailController,
                keyboardType: TextInputType.text,
                labelText: 'Email or Username',
                prefixIcon: Icon(
                  Icons.email_outlined,
                  color: colorScheme.onSurface.withOpacity(0.5),
                  size: 20,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OpenVtsButton(
                      label: 'Cancel',
                      variant: OpenVtsButtonVariant.secondary,
                      onPressed: () {
                        setState(() {
                          _isForgot = false;
                          _forgotPasswordMessage = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OpenVtsButton(
                      label: 'Proceed',
                      loading: _isForgotSubmitting,
                      onPressed: _isForgotSubmitting
                          ? null
                          : _submitForgotPassword,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCheckEmailView(ColorScheme colorScheme, double labelSize) {
    final textTheme = Theme.of(context).textTheme;
    final message =
        _forgotPasswordMessage ??
        'If an account with that identifier exists, a password reset link has been sent.';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Check Your Email',
          style: textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            letterSpacing: 0,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ve sent reset instructions to your email',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 40),
        OpenVtsCard(
          padding: const EdgeInsets.all(24),
          backgroundColor: colorScheme.surface,
          borderColor: colorScheme.outline.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          shadowLevel: OpenVtsCardShadowLevel.strong,
          child: Column(
            children: [
              Text(
                message,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.8),
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withOpacity(0.25),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.mark_email_read_outlined,
                      color: colorScheme.onSurface.withOpacity(0.6),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Check your inbox and spam folder',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OpenVtsButton(
                label: 'Back to Sign In',
                onPressed: () {
                  setState(() {
                    _isForgot = false;
                    _forgotPasswordMessage = null;
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEarthFooter() {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 150,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Outer ring
          ClipPath(
            clipper: _EarthClipper(),
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(
                  color: OpenVtsColors.white.withOpacity(0.8),
                  width: 4,
                ),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Inner image
          ClipPath(
            clipper: _EarthClipper(),
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/images/background-full.png'),
                  fit: BoxFit.cover,
                ),
                shape: BoxShape.circle,
              ),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primary.withOpacity(0.28),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double labelSize = AdaptiveUtils.getTitleFontSize(w);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: OpenVtsColors.background,
        body: Stack(
          children: [
            // Full background image
            Positioned.fill(
              child: Image.asset(
                'assets/images/background-full.png',
                fit: BoxFit.cover,
              ),
            ),
            // Semi-transparent white overlay for premium depth
            Positioned.fill(
              child: Container(color: OpenVtsColors.white.withOpacity(0.75)),
            ),
            // Settings icon
            Positioned(
              top: 18,
              right: 22,
              child: SafeArea(
                child: IconButton(
                  onPressed: _openServerConfiguration,
                  tooltip: 'Server configuration',
                  icon: Icon(
                    Icons.settings_rounded,
                    color: colorScheme.onSurface,
                    size: 24,
                  ),
                ),
              ),
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final h = constraints.maxHeight;
                  final isSmallHeight = h < 700;
                  return SizedBox.expand(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOut,
                          offset: keyboardOpen
                              ? const Offset(0, -0.10)
                              : Offset.zero,
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              SizedBox(
                                height: isSmallHeight ? h * 0.15 : h * 0.20,
                              ),
                              PageTransitionSwitcher(
                                duration: const Duration(milliseconds: 500),
                                transitionBuilder:
                                    (child, animation, secondaryAnimation) {
                                      return SharedAxisTransition(
                                        animation: animation,
                                        secondaryAnimation: secondaryAnimation,
                                        transitionType:
                                            SharedAxisTransitionType.horizontal,
                                        fillColor: OpenVtsColors.transparent,
                                        child: child,
                                      );
                                    },
                                child: _isForgot
                                    ? _buildForgotForm(colorScheme, labelSize)
                                    : Container(
                                        key: const ValueKey('login'),
                                        child: _buildLoginForm(
                                          colorScheme,
                                          labelSize,
                                        ),
                                      ),
                              ),
                              const Spacer(),
                              _buildEarthFooter(),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarthClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Start from bottom left
    path.moveTo(0, size.height);
    // Arc to bottom right (semicircle)
    path.arcToPoint(
      Offset(size.width, size.height),
      radius: Radius.circular(size.width / 2),
      clockwise: false,
    );
    // Line back to bottom left
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
