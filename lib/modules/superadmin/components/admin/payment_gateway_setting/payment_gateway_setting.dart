import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PaymentGatewaySettingsScreen extends StatelessWidget {
  const PaymentGatewaySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: "Open VTS",
      subtitle: "Payment Gateway",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// SINGLE MAIN CONTAINER
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(hp),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.black.withOpacity(0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// BUTTONS FIRST
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.black, width: 1.4),
                          padding: EdgeInsets.symmetric(
                            horizontal: hp,
                            vertical: hp - 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Reset",
                          style: GoogleFonts.roboto(
                            fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          padding: EdgeInsets.symmetric(
                            horizontal: hp + 2,
                            vertical: hp - 4,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          "Save All",
                          style: GoogleFonts.roboto(
                            fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// TEXT BELOW BUTTONS
                  Text(
                    "Payment Gateway Configuration",
                    style: GoogleFonts.roboto(
                      fontSize: AdaptiveUtils.getTitleFontSize(width) + 1,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),

                  Text(
                    "Configure and manage your payment processors",
                    style: GoogleFonts.roboto(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w200,
                      color: Colors.black.withOpacity(0.9),
                    ),
                  ),

                  const SizedBox(height: 30),

                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(hp),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// HEADER
                        Text(
                          "Active Configuration",
                          style: GoogleFonts.roboto(
                            fontSize: AdaptiveUtils.getTitleFontSize(width),
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 20),

                        /// ROW OF 3 ITEMS
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            /// ITEM 1 - Enabled Gateways
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "2",
                                    style: GoogleFonts.roboto(
                                      fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Enabled Gateways",
                                    style: GoogleFonts.roboto(
                                      fontSize: AdaptiveUtils.getTitleFontSize(width) - 3,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// ITEM 2 - Primary Gateway
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "Not Set",
                                    style: GoogleFonts.roboto(
                                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Primary Gateway",
                                    style: GoogleFonts.roboto(
                                      fontSize: AdaptiveUtils.getTitleFontSize(width) - 3,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            /// ITEM 3 - Total Available
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    "14",
                                    style: GoogleFonts.roboto(
                                      fontSize: AdaptiveUtils.getTitleFontSize(width) + 2,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Total Available",
                                    style: GoogleFonts.roboto(
                                      fontSize: AdaptiveUtils.getTitleFontSize(width) - 3,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 10),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.25,
                    children: const [
                      PaymentGatewayBox(
                        id: "stripe",
                        emoji: "💳",
                        name: "Stripe",
                        region: "Global, North America, Europe, Asia Pacific",
                      ),
                      PaymentGatewayBox(
                        id: "adyen",
                        emoji: "🅰️",
                        name: "Adyen",
                        region: "Global, Europe, Asia Pacific, Latin America",
                      ),
                      PaymentGatewayBox(
                        id: "checkout",
                        emoji: "✓",
                        name: "Checkout.com",
                        region: "Global, Europe, Middle East, Asia Pacific",
                      ),
                      PaymentGatewayBox(
                        id: "braintree",
                        emoji: "🌳",
                        name: "Braintree",
                        region: "North America, Europe, Asia Pacific",
                      ),
                      PaymentGatewayBox(
                        id: "razorpay",
                        emoji: "⚡",
                        name: "Razorpay",
                        region: "India, Asia Pacific",
                      ),
                      PaymentGatewayBox(
                        id: "mollie",
                        emoji: "🔷",
                        name: "Mollie",
                        region: "Europe",
                      ),
                      PaymentGatewayBox(
                        id: "gocardless",
                        emoji: "🏦",
                        name: "GoCardless",
                        region: "Europe, North America, Asia Pacific",
                      ),
                      PaymentGatewayBox(
                        id: "flutterwave",
                        emoji: "🦋",
                        name: "Flutterwave",
                        region: "Africa",
                      ),
                      PaymentGatewayBox(
                        id: "mercadopago",
                        emoji: "💰",
                        name: "Mercado Pago",
                        region: "Latin America",
                      ),
                      PaymentGatewayBox(
                        id: "xendit",
                        emoji: "🚀",
                        name: "Xendit",
                        region: "Southeast Asia",
                      ),
                      PaymentGatewayBox(
                        id: "paystack",
                        emoji: "📚",
                        name: "Paystack",
                        region: "Africa",
                      ),
                      PaymentGatewayBox(
                        id: "2c2p",
                        emoji: "🏪",
                        name: "2C2P",
                        region: "Asia Pacific, Southeast Asia",
                      ),
                      PaymentGatewayBox(
                        id: "amazon",
                        emoji: "📦",
                        name: "Amazon Payment Services",
                        region: "Middle East, North Africa",
                      ),
                      PaymentGatewayBox(
                        id: "dlocal",
                        emoji: "🌎",
                        name: "dLocal",
                        region: "Latin America, Africa, Asia Pacific",
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class PaymentGatewayBox extends StatefulWidget {
  final String id; // <- Unique ID
  final String emoji;
  final String name;
  final String region;

  const PaymentGatewayBox({
    super.key,
    required this.id,
    required this.emoji,
    required this.name,
    required this.region,
  });

  @override
  State<PaymentGatewayBox> createState() => _PaymentGatewayBoxState();
}

class _PaymentGatewayBoxState extends State<PaymentGatewayBox> {
  bool isHover = false;

  @override
  Widget build(BuildContext context) {
    final double hp = MediaQuery.of(context).size.height * 0.018;

    return MouseRegion(
      onEnter: (_) => setState(() => isHover = true),
      onExit: (_) => setState(() => isHover = false),
      child: GestureDetector(
        onTap: () {
          // Navigate to payment gateway detail page
          context.push("/superadmin/payment-gateway/${widget.id}");
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: EdgeInsets.all(hp),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.black.withOpacity(0.05),
              width: isHover ? 2 : 1,
            ),
            boxShadow: isHover
                ? [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ]
                : [],
          ),
          child: Column(  // Removed unnecessary Flexible here
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              /// Row: Emoji + Name
              Row(
                children: [
                  Text(
                    widget.emoji,
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.name,
                      style: GoogleFonts.roboto(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              ),

              SizedBox(height: hp * 0.5),

              /// Region text (2 lines max) - Wrapped in Flexible to prevent overflow
              Flexible(
                child: Text(
                  widget.region,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}