// login_screen.dart
import 'package:animations/animations.dart';
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/auth_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/foundation.dart';
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
  String _selectedRole = 'User';
  bool _isLoggingIn = false;

  CancelToken? _loginToken;
  ApiClient? _api;
  AuthRepository? _authRepo;

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

  String _targetPathForRole() {
    switch (_selectedRole) {
      case 'Super Admin':
        return '/superadmin/home';
      case 'Admin':
        return '/admin/home';
      case 'User':
        return '/user/home';
      case 'Driver':
        return '/user/home';
      default:
        return '/user/home';
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
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
      final res = await _repoOrCreate().login(
        identifier: identifier,
        password: password,
        cancelToken: token,
      );

      if (!mounted) return;

      res.when(
        success: (_) {
          setState(() => _isLoggingIn = false);
          context.go(_targetPathForRole());
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
          ? Icon(Icons.visibility_off_outlined, color: colorScheme.primary)
          : null,
    );
  }

  Widget _buildLoginForm(ColorScheme colorScheme, double labelSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with Dropdown
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Login',
              style: GoogleFonts.inter(
                fontSize: labelSize + 4,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            if (kDebugMode)
              DropdownButton<String>(
                value: _selectedRole,
                icon: Icon(Icons.arrow_drop_down, color: colorScheme.primary),
                style: GoogleFonts.inter(
                  fontSize: labelSize,
                  color: colorScheme.onSurface,
                ),
                underline: const SizedBox(),
                items: ['Super Admin', 'Admin', 'User', 'Driver'].map((
                  String value,
                ) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedRole = newValue!;
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your credentials',
          style: GoogleFonts.inter(
            fontSize: labelSize - 2,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 32),

        // Email Field
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.inter(
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
          obscureText: true,
          style: GoogleFonts.inter(
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
          onTap: _isLoggingIn ? null : _submitLogin,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: _isLoggingIn
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
                      "Login",
                      style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(
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
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.inter(
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
        const SizedBox(height: 32),

        // Buttons
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isForgot = false;
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
                onTap: () {
                  // TODO: Implement forgot password logic
                  setState(() {
                    _isForgot = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double labelSize = AdaptiveUtils.getTitleFontSize(w);

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SingleChildScrollView(
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
