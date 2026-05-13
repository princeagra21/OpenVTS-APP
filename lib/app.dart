import 'dart:async';

import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:open_vts/core/providers/core_providers.dart';
import 'package:open_vts/core/router/route_names.dart';
import 'package:open_vts/core/auth/session_expired_bus.dart';
import 'package:open_vts/core/theme/theme_controller.dart';
import 'package:open_vts/core/theme/open_vts_theme.dart';

/// Application root.
///
/// The architecture blueprint keeps bootstrap (`main.dart`) separate from the
/// app shell (`app.dart`). This widget owns app-wide rendering concerns only:
/// routing, theme, directionality, device preview, screen scaling, and session
/// expiration handling.
class FleetStackApp extends ConsumerStatefulWidget {
  const FleetStackApp({
    required this.router,
    this.enableDevicePreview = false,
    super.key,
  });

  final GoRouter router;
  final bool enableDevicePreview;

  @override
  ConsumerState<FleetStackApp> createState() => _FleetStackAppState();
}

class _FleetStackAppState extends ConsumerState<FleetStackApp> {
  StreamSubscription<void>? _sessionExpiredSub;
  DateTime? _lastSessionNoticeAt;

  @override
  void initState() {
    super.initState();
    _sessionExpiredSub = SessionExpiredBus.stream.listen((_) async {
      await ref.read(appContainerProvider).tokenStorage.clear();
      if (!mounted) return;
      widget.router.go(AppRoutePaths.login);

      final now = DateTime.now();
      final last = _lastSessionNoticeAt;
      if (last == null || now.difference(last).inSeconds >= 2) {
        _lastSessionNoticeAt = now;
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _sessionExpiredSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      builder: (_, __) {
        return AnimatedBuilder(
          animation: themeController,
          builder: (_, __) {
            final mode = themeController.themeMode.value;
            final brand = themeController.brandColor.value;
            final direction = themeController.textDirection.value;

            return MaterialApp.router(
              title: 'Open VTS',
              debugShowCheckedModeBanner: false,
              scaffoldMessengerKey: rootScaffoldMessengerKey,
              locale: widget.enableDevicePreview
                  ? DevicePreview.locale(context)
                  : null,
              builder: (context, child) {
                final theme = Theme.of(context);
                final isDark = theme.brightness == Brightness.dark;
                final backgroundColor = theme.scaffoldBackgroundColor;
                final overlayStyle = SystemUiOverlayStyle(
                  statusBarColor: backgroundColor,
                  statusBarIconBrightness:
                      isDark ? Brightness.light : Brightness.dark,
                  statusBarBrightness:
                      isDark ? Brightness.dark : Brightness.light,
                  systemNavigationBarColor: backgroundColor,
                  systemNavigationBarIconBrightness:
                      isDark ? Brightness.light : Brightness.dark,
                  systemNavigationBarDividerColor: Colors.transparent,
                );

                Widget result = AnnotatedRegion<SystemUiOverlayStyle>(
                  value: overlayStyle,
                  child: ColoredBox(
                    color: backgroundColor,
                    child: Directionality(
                      textDirection: direction,
                      child: child ?? const SizedBox.shrink(),
                    ),
                  ),
                );

                if (widget.enableDevicePreview) {
                  result = DevicePreview.appBuilder(context, result);
                }

                if (kDebugMode) {
                  result = Banner(
                    message: 'WEB DEBUG',
                    location: BannerLocation.topStart,
                    child: result,
                  );
                }

                return result;
              },
              routerConfig: widget.router,
              theme: OpenVtsTheme.light(brand),
              darkTheme: OpenVtsTheme.dark(brand),
              themeMode: mode,
            );
          },
        );
      },
    );
  }
}
