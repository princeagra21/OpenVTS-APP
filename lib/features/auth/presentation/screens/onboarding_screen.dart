// lib/onboarding_screen.dart
import 'dart:math' as math;

import 'package:open_vts/shared/widgets/open_vts/open_vts_components.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';
import 'package:open_vts/features/auth/presentation/screens/login_screen.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingData = [
    {
      'image': 'assets/images/screen-1.png',
      'title': 'Command Every Vehicle',
      'subtitle':
          'Monitor live locations, routes, drivers, and activity from one secure control center built for serious fleet operations.',
    },
    {
      'image': 'assets/images/screen-2.png',
      'title': 'Your Data Stays Yours',
      'subtitle':
          'OpenVTS keeps fleet data inside your own infrastructure, giving your business stronger security and privacy.',
    },
    {
      'image': 'assets/images/screen-3.png',
      'title': 'Own The Platform',
      'subtitle':
          'No SaaS lock-in. No outside dependency. Run self-hosted GPS software with full control, access, and ownership.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double labelSize = AdaptiveUtils.getTitleFontSize(w);
    final double titleSize = labelSize + 6;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final maxHeight = constraints.maxHeight;
            final horizontalPadding = w < 420 ? OpenVtsSpacing.md : OpenVtsSpacing.xl;
            final cardPadding = w < 420 ? OpenVtsSpacing.lg : OpenVtsSpacing.xl;
            final cardMaxWidth = math.min(w - (horizontalPadding * 2), 560.0);
            final imageSize = math.min(
              cardMaxWidth - (cardPadding * 2),
              math.max(220.0, maxHeight * 0.42),
            );

            return Stack(
              children: [
                Positioned.fill(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _onboardingData.length,
                    onPageChanged: (index) {
                      updateLocalUiState(this, () => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          OpenVtsSpacing.xxl,
                          horizontalPadding,
                          128,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: cardMaxWidth),
                            child: Container(
                              padding: EdgeInsets.all(cardPadding),
                              decoration: BoxDecoration(
                                color: OpenVtsColors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(
                                  OpenVtsRadius.xl + OpenVtsSpacing.sm,
                                ),
                                border: Border.all(
                                  color: OpenVtsColors.white.withOpacity(0.08),
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: imageSize,
                                    height: imageSize,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Image.asset(
                                        _onboardingData[index]['image']!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  Text(
                                    _onboardingData[index]['title']!,
                                    textAlign: TextAlign.center,
                                    style: OpenVtsTypography.headingLarge.copyWith(
                                      fontSize: titleSize,
                                      fontWeight: FontWeight.w800,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    _onboardingData[index]['subtitle']!,
                                    textAlign: TextAlign.center,
                                    style: OpenVtsTypography.bodyLarge.copyWith(
                                      fontSize: labelSize,
                                      height: 1.4,
                                      color: colorScheme.onSurface.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                Positioned(
                  top: OpenVtsSpacing.md,
                  right: OpenVtsSpacing.md,
                  child: TextButton(
                    onPressed: _openLogin,
                    child: Text(
                      'Skip',
                      style: OpenVtsTypography.labelLarge.copyWith(
                        fontSize: labelSize,
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  bottom: OpenVtsSpacing.xl,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      width: 180,
                      child: OpenVtsButton(
                        label: _currentPage == _onboardingData.length - 1
                            ? 'Continue'
                            : 'Next',
                        onPressed: () {
                          if (_currentPage < _onboardingData.length - 1) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          } else {
                            _openLogin();
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
