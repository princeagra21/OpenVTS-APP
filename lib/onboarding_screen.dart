// lib/onboarding_screen.dart
import 'package:fleet_stack/login_screen.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      'image': 'assets/image/group.webp',
      'title': 'We Make It Easiest Just Deploy',
      'subtitle': 'Open VTS’s ethos is simple: remove barriers and empower businesses to manage their fleets without technical expertise. Our software is built on simplicity, community, and real empowerment—giving clients full control and fueling success through easy, self-managed installations.',
    },
    {
      'image': 'assets/image/Delivery.webp',
      'title': 'Delivery',
      'subtitle': 'Open VTS™ GPS Software boosts delivery efficiency, profitability, and client satisfaction. Designed for modern delivery services, it ensures accurate, timely deliveries, helping organizations thrive in today’s fast-paced world.',
    },
    {
      'image': 'assets/image/logistics.webp',
      'title': 'Logistics & Trucking',
      'subtitle': 'Open VTS’s self-hosted GPS system gives logistics and trucking providers real-time updates, ensuring timely deliveries and compliance with traffic regulations. On-time reporting helps businesses streamline operations and keep clients satisfied.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double labelSize = AdaptiveUtils.getTitleFontSize(w);
    final double titleSize = labelSize + 6;

    return Scaffold(
      backgroundColor: colorScheme.background,
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
                    vertical: 40,
                    horizontal: 28,
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.asset(
                          _onboardingData[index]['image']!,
                          height: 250,
                          width: 250,
                          fit: BoxFit.cover,
                        ),
                      ),

                      const SizedBox(height: 30),

                      Text(
                        _onboardingData[index]['title']!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                        ),
                      ),

                      const SizedBox(height: 14),

                      Text(
                        _onboardingData[index]['subtitle']!,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
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
                style: GoogleFonts.inter(
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
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
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
                child: Text(
                  _currentPage == _onboardingData.length - 1
                      ? 'Continue'
                      : 'Next',
                  style: GoogleFonts.inter(
                    fontSize: labelSize,
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
