// components/auth/login_screen.dart
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isForgot = false;

  // Reusable minimal InputDecoration
  InputDecoration _minimalDecoration(BuildContext context, {String? hint, bool isPassword = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: colorScheme.onSurface.withOpacity(0.5),
        fontSize: AdaptiveUtils.getTitleFontSize(MediaQuery.of(context).size.width),
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
      suffixIcon: isPassword ? Icon(Icons.visibility_off_outlined, color: colorScheme.primary) : null,
    );
  }

  Widget _buildLoginForm(ColorScheme colorScheme, double labelSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'Login',
          style: GoogleFonts.inter(
            fontSize: labelSize + 4,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
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
          style: GoogleFonts.inter(fontSize: labelSize, color: colorScheme.onSurface),
          decoration: _minimalDecoration(context, hint: "Email").copyWith(
            prefixIcon: Icon(Icons.email_outlined, color: colorScheme.primary, size: 22),
          ),
        ),
        const SizedBox(height: 16),

        // Password Field
        TextField(
          controller: _passwordController,
          obscureText: true,
          style: GoogleFonts.inter(fontSize: labelSize, color: colorScheme.onSurface),
          decoration: _minimalDecoration(context, hint: "Password", isPassword: true).copyWith(
            prefixIcon: Icon(Icons.lock_outlined, color: colorScheme.primary, size: 22),
          ),
        ),
        const SizedBox(height: 24),

        // Login Button
        GestureDetector(
          onTap: () {
            context.push('/admin/home');
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
              child: Icon(Icons.close, size: 28, color: colorScheme.onSurface.withOpacity(0.8)),
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
          style: GoogleFonts.inter(fontSize: labelSize, color: colorScheme.onSurface),
          decoration: _minimalDecoration(context, hint: "Email").copyWith(
            prefixIcon: Icon(Icons.email_outlined, color: colorScheme.primary, size: 22),
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
      padding: const EdgeInsets.only(top: 80), // adjust this value higher/lower
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