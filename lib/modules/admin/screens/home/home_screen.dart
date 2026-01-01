// lib/screens/home/home_screen.dart
// -----------------------------
import 'package:fleet_stack/main.dart';
import 'package:fleet_stack/modules/admin/components/card/actions_buttons.dart';
import 'package:fleet_stack/modules/admin/components/card/fleet_card.dart';
import 'package:fleet_stack/modules/admin/components/card/recent_activity_box.dart';
import 'package:fleet_stack/modules/admin/components/card/search_bar.dart';
import 'package:fleet_stack/modules/admin/components/card/vehicle_status_box.dart';
import 'package:fleet_stack/modules/admin/theme/app_theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../layout/app_layout.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedLanguage = 'EN';

  /// Stylish popup (top-right card). Uses showGeneralDialog for custom animation.
  Future<void> _showLanguagePicker(BuildContext context) async {
    final chosen = await showGeneralDialog<String?>(
      context: context,
      barrierLabel: "Language",
      barrierDismissible: true,
      barrierColor: Colors.black45,
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim1, anim2) {
        // pageBuilder must return something — actual UI is in transitionBuilder
        return const SizedBox.shrink();
      },
      transitionBuilder: (ctx, anim, secondaryAnim, child) {
        final theme = Theme.of(context);
        // Position the popup near the top-right .
        return SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 72.0, right: 14.0),
              child: FadeTransition(
                opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.97, end: 1.0)
                      .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
                  child: Material(
                    color: theme.colorScheme.surface,
                    elevation: 18,
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 220, maxWidth: 260),
                      child: IntrinsicWidth(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Header
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  Text(
                                    'Language',
                                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: () => Navigator.of(ctx).pop(),
                                    child: Container(
                                      height: 32,
                                      width: 32,
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(Icons.close, size: 18, color: theme.colorScheme.primary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                            // Options
                            _languageTile(ctx, 'EN', 'English', '🇬🇧'),
                            _languageTile(ctx, 'FR', 'Français', '🇫🇷'),
                            _languageTile(ctx, 'ES', 'Español', '🇪🇸'),
                            const SizedBox(height: 8),
                            // Optional footer / small caption
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              child: Text(
                                'App language will update after selection.',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    if (chosen != null && chosen != _selectedLanguage) {
      setState(() {
        _selectedLanguage = chosen;
      });
      // TODO: Hook into your localization provider here.
      debugPrint('Language changed to: $chosen');
    }
  }

  Widget _languageTile(BuildContext ctx, String code, String label, String flag) {
    final theme = Theme.of(ctx);
    final bool selected = code == _selectedLanguage;

    return InkWell(
      onTap: () => Navigator.of(ctx).pop(code),
      borderRadius: BorderRadius.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // flag circle
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: theme.colorScheme.primary.withOpacity(0.06),
              ),
              alignment: Alignment.center,
              child: Text(flag, style: const TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(code, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withOpacity(0.6))),
                ],
              ),
            ),
            if (selected)
              Container(
                height: 28,
                width: 28,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check, size: 16, color: theme.colorScheme.onPrimary),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final themeIcon = isDark ? Icons.light_mode : Icons.dark_mode;

    return AppLayout(
      title: "FLEET STACK",
      subtitle: "Overview",
      // action icons: language, theme toggle, notifications
      actionIcons: [
        Icons.language,
        themeIcon,
        CupertinoIcons.bell,
      ],

      // onActionTaps must map 1:1 with actionIcons order
      onActionTaps: [
        // Language tap -> stylish popup
        () => _showLanguagePicker(context),

        // Theme tap -> toggle light/dark immediately (non-blocking)
        () {
          final isCurrentlyDark = Theme.of(context).brightness == Brightness.dark;
          final newDarkMode = !isCurrentlyDark;

          // update controller (instant UI update if your controller notifies listeners)
          themeController.setDarkMode(newDarkMode);

          // persist (non-blocking)
          AppTheme.setDarkMode(newDarkMode);

          // If using the Default brand, ensure brand matches mode
          if (AppTheme.brandColor == AppTheme.defaultBrand ||
              AppTheme.brandColor == AppTheme.defaultDarkBrand) {
            final forcedBrand = newDarkMode ? AppTheme.defaultDarkBrand : AppTheme.defaultBrand;
            themeController.setBrand(forcedBrand);
            AppTheme.setBrand(forcedBrand);
          }
        },

        // Notifications tap
      //  () => context.push('/admin/notifications'),
      ],

      leftAvatarText: 'FS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          AppSearchBar(),
          SizedBox(height: 12),
          ActionsButtons(),
          SizedBox(height: 24),
          FleetOverviewBox(),
          SizedBox(height: 24),
          VehicleStatusBox(),
          SizedBox(height: 24),
          RecentActivityBox(),
          SizedBox(height: 24),
        ],
      ),
    );
  }
}
