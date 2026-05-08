// lib/onboarding_screen.dart
import 'package:open_vts/design_system/components/open_vts_components.dart';
import 'package:open_vts/design_system/theme/open_vts_theme.dart';
import 'package:open_vts/login_screen.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';

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
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double labelSize = AdaptiveUtils.getTitleFontSize(w);
    final double titleSize = labelSize + 6;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _onboardingData.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: OpenVtsSpacing.xxxl,
                    horizontal: OpenVtsSpacing.xl,
                  ),
                  margin: const EdgeInsets.symmetric(
                    horizontal: OpenVtsSpacing.xxl,
                  ),
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
                    children: [
                      FractionallySizedBox(
                        widthFactor: 1,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: Image.asset(
                              _onboardingData[index]['image']!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      Text(
                        _onboardingData[index]['title']!,
                        textAlign: TextAlign.center,
                        style: OpenVtsTypography.headingLarge.copyWith(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 14),

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
              );
            },
          ),

          // SKIP BUTTON (top right, more margin)
          Positioned(
            top: 40,
            right: 20,
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
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

          // NEXT / CONTINUE BUTTON (bottom center, better margin)
          Positioned(
            bottom: 40,
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
