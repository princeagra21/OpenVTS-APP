import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentGatewayDetailsScreen extends StatefulWidget {
  final String gatewayId;

  const PaymentGatewayDetailsScreen({
    super.key,
    required this.gatewayId,
  });

  @override
  State<PaymentGatewayDetailsScreen> createState() =>
      _PaymentGatewayDetailsScreenState();
}

class _PaymentGatewayDetailsScreenState
    extends State<PaymentGatewayDetailsScreen> {
  String selectedTab = "Credentials";
  final List<String> tabs = ["Credentials", "Settings", "Features"];

  Map<String, dynamic> gatewayDetails = {};

  // Controllers for credentials
  final TextEditingController sandboxPublicKey = TextEditingController();
  final TextEditingController sandboxSecretKey = TextEditingController();
  final TextEditingController sandboxWebhookToken = TextEditingController();
  final TextEditingController productionPublicKey = TextEditingController();
  final TextEditingController productionSecretKey = TextEditingController();
  final TextEditingController productionWebhookToken = TextEditingController();

  // Settings
  bool isPrimary = false;
  final List<String> availableCurrencies = [
    "USD", "EUR", "GBP", "JPY", "CNY", "AUD", "CAD", "CHF", "INR", "SGD",
    "HKD", "KRW", "MXN", "BRL", "ARS", "CLP", "COP", "NGN", "KES", "ZAR",
    "GHS", "AED", "SAR", "EGP", "THB", "MYR", "IDR", "PHP", "VND", "DKK",
    "SEK", "NOK"
  ];
  final List<String> selectedCurrencies = [];

  @override
  void initState() {
    super.initState();
    _fetchGatewayDetails();
  }

  void _fetchGatewayDetails() {
    // Simulated API fetch
    setState(() {
      gatewayDetails = {
        "id": widget.gatewayId,
        "name": "Stripe",
        "apiKey": "sk_test_123456",
        "enabled": true,
        "features": ["Recurring Payments", "Refunds"],
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final titleFontSize = AdaptiveUtils.getSubtitleFontSize(screenWidth);
    final spacing = AdaptiveUtils.getLeftSectionSpacing(screenWidth);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(left: horizontalPadding, right: horizontalPadding, top: horizontalPadding,), 
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(horizontalPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black.withOpacity(0.05)),
            ),
            child: Column(
              children: [
                // Top Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.gatewayId,
                      style: GoogleFonts.roboto(
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        size: AdaptiveUtils.getIconSize(screenWidth),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing * 2.5),

                // Tabs using Wrap + SmallTab
                Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: tabs.map((tab) {
                    return _LocalTab(
                      label: tab,
                      selected: selectedTab == tab,
                      onTap: () => setState(() => selectedTab = tab),
                    );
                  }).toList(),
                ),
                SizedBox(height: spacing * 2),

                // Tab content
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: spacing * 2),
                      child: _buildTabContent(screenWidth, spacing),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(double screenWidth, double spacing) {
    switch (selectedTab) {
      case "Credentials":
        return _buildCredentialsTab(screenWidth, spacing);
      case "Settings":
        return _buildSettingsTab(screenWidth, spacing);
      case "Features":
        return _buildFeaturesTab(screenWidth, spacing);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCredentialsTab(double screenWidth, double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sandbox Container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.science_rounded,
                    size: 22,
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Sandbox (Test)",
                    style: GoogleFonts.roboto(
                      fontSize: AdaptiveUtils.getTitleFontSize(screenWidth),
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                "PUBLIC KEY",
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(screenWidth),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                style: GoogleFonts.roboto(
                  color: Colors.black,
                  fontSize: AdaptiveUtils.getTitleFontSize(screenWidth),
                ),
                controller: sandboxPublicKey,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 12),
              Text(
                "SECRET KEY",
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(screenWidth),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                obscureText: true,
                style: GoogleFonts.roboto(
                  color: Colors.black,
                  fontSize: AdaptiveUtils.getTitleFontSize(screenWidth),
                ),
                controller: sandboxSecretKey,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 12),
              Text(
                "WEBHOOK TOKEN",
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(screenWidth),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                style: GoogleFonts.roboto(
                  color: Colors.black,
                  fontSize: AdaptiveUtils.getTitleFontSize(screenWidth),
                ),
                controller: sandboxWebhookToken,
                decoration: _inputDecoration(),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing * 2),
        // Production Container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.rocket_launch_rounded,
                    size: 22,
                    color: Colors.black87,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Production (Live)",
                    style: GoogleFonts.roboto(
                      fontSize: AdaptiveUtils.getTitleFontSize(screenWidth),
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                "PUBLIC KEY",
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(screenWidth),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                style: GoogleFonts.roboto(
                  color: Colors.black,
                  fontSize: AdaptiveUtils.getTitleFontSize(screenWidth),
                ),
                controller: productionPublicKey,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 12),
              Text(
                "SECRET KEY",
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(screenWidth),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                obscureText: true,
                style: GoogleFonts.roboto(
                  color: Colors.black,
                  fontSize: AdaptiveUtils.getTitleFontSize(screenWidth),
                ),
                controller: productionSecretKey,
                decoration: _inputDecoration(),
              ),
              const SizedBox(height: 12),
              Text(
                "WEBHOOK TOKEN",
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(screenWidth),
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                style: GoogleFonts.roboto(
                  color: Colors.black,
                  fontSize: AdaptiveUtils.getTitleFontSize(screenWidth),
                ),
                controller: productionWebhookToken,
                decoration: _inputDecoration(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab(double screenWidth, double spacing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Primary Gateway Container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Set as Primary Gateway",
                    style: GoogleFonts.roboto(
                      fontSize: AdaptiveUtils.getTitleFontSize(screenWidth),
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  Transform.scale(
                    scale: 0.7,
                    child: Switch(
                      value: isPrimary,
                      activeColor: Colors.white,
                      activeTrackColor: Colors.black,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.black.withOpacity(0.3),
                      onChanged: (v) => setState(() => isPrimary = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                "Make this the default payment processor",
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(screenWidth) - 5,
                  fontWeight: FontWeight.w400,
                  color: Colors.black.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing * 2),
        // Currency Selection
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Currencies",
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getTitleFontSize(screenWidth),
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: availableCurrencies.map((currency) {
                  final bool isSelected = selectedCurrencies.contains(currency);
                  return ChoiceChip(
                    label: Text(currency),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          selectedCurrencies.add(currency);
                        } else {
                          selectedCurrencies.remove(currency);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              Text(
                "Selected: ${selectedCurrencies.length} currencies",
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(screenWidth) - 5,
                  fontWeight: FontWeight.w400,
                  color: Colors.black.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesTab(double screenWidth, double spacing) {
    final List<String> features = [
      "Cards",
      "E-Wallets",
      "Virtual Accounts",
      "Retail Outlets",
      "Southeast Asia",
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Feature Info",
            style: GoogleFonts.roboto(
              fontSize: AdaptiveUtils.getTitleFontSize(screenWidth) + 2,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Supported Features and Regions",
            style: GoogleFonts.roboto(
              fontSize: AdaptiveUtils.getSubtitleFontSize(screenWidth) - 5,
              fontWeight: FontWeight.w400,
              color: Colors.black.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: features.map((feature) {
              return Chip(
                label: Text(feature),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: Colors.transparent,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.1)),
      ),
    );
  }
}
class _LocalTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LocalTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool small = MediaQuery.of(context).size.width < 420;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: small ? 12 : 16,
          vertical: small ? 6 : 8,
        ),
        decoration: BoxDecoration(
          color: selected ? Colors.black : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: small ? 11 : 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}