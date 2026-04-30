// components/auth/login_screen.dart
import 'package:animations/animations.dart';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/api_base_url_config.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/auth_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/core/config/server_configuration_sheet.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
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
  bool _loggingIn = false;
  bool _loginErrorShown = false;
  bool _obscurePassword = true;
  String? _forgotPasswordMessage;
  CancelToken? _loginToken;

  ApiClient? _api;
  AuthRepository? _authRepo;

  Future<void> _syncApiClientBaseUrl() async {
    final effectiveBaseUrl = ApiBaseUrlConfig.instance.effectiveBaseUrl;
    _api?.updateBaseUrl(effectiveBaseUrl);
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

  @override
  void dispose() {
    _loginToken?.cancel('Login screen disposed');
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _ensureRepo() {
    if (_api != null) return;
    final storage = TokenStorage.defaultInstance();
    _api = ApiClient(config: AppConfig.fromDartDefine(), tokenStorage: storage);
    _authRepo = AuthRepository(api: _api!, tokenStorage: storage);
  }

  void _showLoginErrorOnce(String msg) {
    if (_loginErrorShown || !mounted) return;
    _loginErrorShown = true;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _submitForgotPassword() async {
    if (_isForgotSubmitting) return;

    final identifier = _emailController.text.trim();
    if (identifier.isEmpty) {
      _showLoginErrorOnce('Please enter your email or username.');
      return;
    }

    _ensureRepo();
    _loginToken?.cancel('Retry forgot password');
    final token = CancelToken();
    _loginToken = token;

    if (!mounted) return;
    setState(() {
      _isForgotSubmitting = true;
      _forgotPasswordMessage = null;
    });

    try {
      final message = await _authRepo!.forgotPassword(
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
      _loginErrorShown = false;
      final msg = error is ApiException && error.message.trim().isNotEmpty
          ? error.message
          : 'Unable to send reset link. Please try again.';
      _showLoginErrorOnce(msg);
    }
  }

  Future<void> _submitLogin() async {
    if (_loggingIn) return;

    final identifier = _emailController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.trim().isEmpty) {
      _showLoginErrorOnce('Please enter your credentials.');
      return;
    }

    _ensureRepo();
    _loginErrorShown = false;

    _loginToken?.cancel('Retry login');
    final token = CancelToken();
    _loginToken = token;

    if (!mounted) return;
    setState(() => _loggingIn = true);

    try {
      final res = await _authRepo!.login(
        identifier: identifier,
        password: password,
        cancelToken: token,
      );

      if (!mounted) return;

      res.when(
        success: (_) {
          setState(() => _loggingIn = false);
          context.push('/superadmin/home');
        },
        failure: (err) {
          setState(() => _loggingIn = false);
          final msg = err is ApiException
              ? err.message
              : 'Login failed. Please try again.';
          _showLoginErrorOnce(msg);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loggingIn = false);
      _showLoginErrorOnce('Login failed. Please try again.');
    }
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
      hintStyle: GoogleFonts.roboto(
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Login',
                style: GoogleFonts.roboto(
                  fontSize: labelSize + 4,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Material(
              color: colorScheme.primary.withValues(alpha: 0.1),
              shape: const CircleBorder(),
              child: IconButton(
                onPressed: _openServerConfiguration,
                tooltip: 'Server configuration',
                icon: Icon(
                  Icons.settings_rounded,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your credentials',
          style: GoogleFonts.roboto(
            fontSize: labelSize - 2,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 32),

        // Email Field
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.roboto(
            fontSize: labelSize,
            color: colorScheme.onSurface,
          ),
          decoration: _minimalDecoration(context, hint: "Email").copyWith(
            prefixIcon: Icon(
              Icons.email_outlined,
              color: colorScheme.primary,
              size: 22,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Password Field
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: GoogleFonts.roboto(
            fontSize: labelSize,
            color: colorScheme.onSurface,
          ),
          decoration:
              _minimalDecoration(
                context,
                hint: "Password",
                isPassword: true,
              ).copyWith(
                prefixIcon: Icon(
                  Icons.lock_outlined,
                  color: colorScheme.primary,
                  size: 22,
                ),
              ),
        ),
        const SizedBox(height: 24),

        // Login Button
        GestureDetector(
          onTap: _loggingIn ? null : _submitLogin,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: _loggingIn
                  ? const AppShimmer(width: 18, height: 18, radius: 9)
                  : Text(
                      "Login",
                      style: GoogleFonts.roboto(
                        fontSize: labelSize,
                        color: colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Forgot Password
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
              style: GoogleFonts.roboto(
                fontSize: labelSize - 2,
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
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
              style: GoogleFonts.roboto(
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
          style: GoogleFonts.roboto(
            fontSize: labelSize - 2,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 32),

        // Email Field
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.text,
          style: GoogleFonts.roboto(
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
                      style: GoogleFonts.roboto(
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
                            style: GoogleFonts.roboto(
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
              style: GoogleFonts.roboto(
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
          style: GoogleFonts.roboto(
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
                style: GoogleFonts.roboto(
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
                style: GoogleFonts.roboto(
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

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
        child: Align(
          alignment: Alignment.topCenter, // push toward top
          child: Padding(
            padding: const EdgeInsets.only(
              top: 80,
            ), // adjust this value higher/lower
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                ),
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
                      ? _buildForgotForm(colorScheme, labelSize)
                      : _buildLoginForm(colorScheme, labelSize),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
