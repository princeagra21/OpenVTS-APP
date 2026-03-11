import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_notification_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_notifications_repository.dart';
import 'package:fleet_stack/core/services/push_notifications_service.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/core/widgets/push_notification_banner.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminNotificationsScreen extends StatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  State<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends State<AdminNotificationsScreen> {
  final List<AdminNotificationItem> _items = <AdminNotificationItem>[];

  bool _loading = false;
  bool _loadErrorShown = false;
  bool _pushStateLoading = false;
  bool _pushActionLoading = false;
  PushDeviceState? _pushState;

  ApiClient? _api;
  AdminNotificationsRepository? _repo;
  CancelToken? _loadToken;
  CancelToken? _markToken;
  CancelToken? _markAllToken;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
    _loadPushState();
  }

  @override
  void dispose() {
    _loadToken?.cancel('Admin notifications disposed');
    _markToken?.cancel('Admin notifications disposed');
    _markAllToken?.cancel('Admin notifications disposed');
    super.dispose();
  }

  String _safe(String? value) {
    final v = (value ?? '').trim();
    return v.isEmpty ? '—' : v;
  }

  String _formatDate(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '—';
    final dt = DateTime.tryParse(value);
    if (dt == null) return value;

    const months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final local = dt.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final mm = local.minute.toString().padLeft(2, '0');
    return '${local.day} ${months[local.month - 1]} ${local.year}, $hour:$mm $ampm';
  }

  AdminNotificationItem _withRead(AdminNotificationItem item, bool read) {
    final next = Map<String, dynamic>.from(item.raw);
    next['isRead'] = read;
    next['read'] = read;
    return AdminNotificationItem(next);
  }

  Future<void> _loadNotifications() async {
    _loadToken?.cancel('Reload notifications');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= AdminNotificationsRepository(api: _api!);

      final res = await _repo!.getNotifications(cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (data) {
          if (!mounted) return;
          setState(() {
            _items
              ..clear()
              ..addAll(data);
            _loading = false;
            _loadErrorShown = false;
          });
        },
        failure: (error) {
          if (!mounted) return;
          setState(() {
            _items.clear();
            _loading = false;
          });

          if (_loadErrorShown) return;
          _loadErrorShown = true;

          String msg = "Couldn't load notifications.";
          if (error is ApiException && error.message.trim().isNotEmpty) {
            msg = error.message;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items.clear();
        _loading = false;
      });
      if (_loadErrorShown) return;
      _loadErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load notifications.")),
      );
    }
  }

  Future<void> _loadPushState() async {
    if (!mounted) return;
    setState(() => _pushStateLoading = true);
    final state = await PushNotificationsService.instance.getStatus();
    if (!mounted) return;
    setState(() {
      _pushState = state;
      _pushStateLoading = false;
    });
  }

  Future<void> _togglePushState() async {
    final state = _pushState;
    if (_pushActionLoading || state == null || !state.canShowBanner) return;
    if (!mounted) return;
    setState(() => _pushActionLoading = true);

    if (state.canDisable) {
      final result = await PushNotificationsService.instance.disable();
      if (!mounted) return;
      result.when(
        success: (_) {},
        failure: (error) {
          final message =
              error is ApiException && error.message.trim().isNotEmpty
              ? error.message
              : "Couldn't update push notifications.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
      );
    } else {
      final result = await PushNotificationsService.instance.enable();
      if (!mounted) return;
      result.when(
        success: (_) {},
        failure: (error) {
          final message =
              error is ApiException && error.message.trim().isNotEmpty
              ? error.message
              : "Couldn't enable push notifications.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        },
      );
    }

    await _loadPushState();
    if (!mounted) return;
    setState(() => _pushActionLoading = false);
  }

  Future<void> _markOneRead(AdminNotificationItem item) async {
    if (item.isRead) return;

    final index = _items.indexWhere((e) => e.id == item.id);
    if (index < 0) return;

    final original = _items[index];
    if (!mounted) return;
    setState(() {
      _items[index] = _withRead(original, true);
    });

    _markToken?.cancel('Restart mark read');
    final token = CancelToken();
    _markToken = token;

    try {
      _repo ??= AdminNotificationsRepository(
        api:
            _api ??
            ApiClient(
              config: AppConfig.fromDartDefine(),
              tokenStorage: TokenStorage.defaultInstance(),
            ),
      );

      final res = await _repo!.markRead(item.id, cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (_) {},
        failure: (error) {
          if (!mounted) return;
          setState(() {
            _items[index] = original;
          });
          String msg = "Couldn't mark notification as read.";
          if (error is ApiException && error.message.trim().isNotEmpty) {
            msg = error.message;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items[index] = original;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't mark notification as read.")),
      );
    }
  }

  Future<void> _markAllRead() async {
    if (_loading || _items.isEmpty) return;

    final snapshot = List<AdminNotificationItem>.from(_items);
    if (!mounted) return;
    setState(() {
      for (var i = 0; i < _items.length; i++) {
        _items[i] = _withRead(_items[i], true);
      }
    });

    _markAllToken?.cancel('Restart mark all read');
    final token = CancelToken();
    _markAllToken = token;

    try {
      _repo ??= AdminNotificationsRepository(
        api:
            _api ??
            ApiClient(
              config: AppConfig.fromDartDefine(),
              tokenStorage: TokenStorage.defaultInstance(),
            ),
      );

      final res = await _repo!.markAllRead(cancelToken: token);
      if (!mounted) return;

      res.when(
        success: (_) {},
        failure: (error) {
          if (!mounted) return;
          setState(() {
            _items
              ..clear()
              ..addAll(snapshot);
          });

          String msg = "Couldn't mark all notifications as read.";
          if (error is ApiException && error.message.trim().isNotEmpty) {
            msg = error.message;
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(snapshot);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't mark all notifications as read."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);

    return AppLayout(
      title: 'FLEET STACK',
      subtitle: 'Notifications',
      actionIcons: const [Icons.done_all],
      onActionTaps: [_markAllRead],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inbox',
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getSubtitleFontSize(width),
                fontWeight: FontWeight.w800,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_items.length} notifications',
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getTitleFontSize(width),
                color: colorScheme.onSurface.withOpacity(0.54),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            if ((_pushState?.canShowBanner ?? false) || _pushStateLoading)
              if (_pushState != null)
                PushNotificationBanner(
                  state: _pushState!,
                  loading: _pushActionLoading || _pushStateLoading,
                  onPressed: _togglePushState,
                )
              else
                const _PushBannerShimmer(),
            if (_loading)
              const _NotificationShimmerList()
            else if (_items.isEmpty)
              const _EmptyNotificationsCard()
            else
              ..._items.map(
                (item) => _NotificationCard(
                  item: item,
                  onTap: () => _markOneRead(item),
                  safe: _safe,
                  formatDate: _formatDate,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PushBannerShimmer extends StatelessWidget {
  const _PushBannerShimmer();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: const Row(
        children: [
          AppShimmer(width: 40, height: 40, radius: 12),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppShimmer(width: 180, height: 14, radius: 7),
                SizedBox(height: 6),
                AppShimmer(width: double.infinity, height: 12, radius: 6),
              ],
            ),
          ),
          SizedBox(width: 12),
          AppShimmer(width: 64, height: 36, radius: 18),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.onTap,
    required this.safe,
    required this.formatDate,
  });

  final AdminNotificationItem item;
  final VoidCallback onTap;
  final String Function(String?) safe;
  final String Function(String) formatDate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width);

    final title = safe(item.title);
    final body = safe(item.body);
    final kind = safe(item.type);
    final created = formatDate(item.createdAt);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        padding: EdgeInsets.all(hp),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: (item.isRead ? Colors.grey : colorScheme.primary)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.isRead ? 'Read' : 'Unread',
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getTitleFontSize(width) - 1,
                      fontWeight: FontWeight.w700,
                      color: item.isRead
                          ? Colors.grey[700]
                          : colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$kind • $created',
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                color: colorScheme.onSurface.withOpacity(0.54),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Text(
              body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: AdaptiveUtils.getTitleFontSize(width),
                color: colorScheme.onSurface.withOpacity(0.87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationShimmerList extends StatelessWidget {
  const _NotificationShimmerList();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        _NotificationShimmerCard(),
        _NotificationShimmerCard(),
        _NotificationShimmerCard(),
      ],
    );
  }
}

class _NotificationShimmerCard extends StatelessWidget {
  const _NotificationShimmerCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppShimmer(
                  width: double.infinity,
                  height: 16,
                  radius: 8,
                ),
              ),
              SizedBox(width: 8),
              AppShimmer(width: 54, height: 20, radius: 10),
            ],
          ),
          SizedBox(height: 8),
          AppShimmer(width: 180, height: 12, radius: 6),
          SizedBox(height: 10),
          AppShimmer(width: double.infinity, height: 12, radius: 6),
          SizedBox(height: 6),
          AppShimmer(width: 220, height: 12, radius: 6),
        ],
      ),
    );
  }
}

class _EmptyNotificationsCard extends StatelessWidget {
  const _EmptyNotificationsCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final hp = AdaptiveUtils.getHorizontalPadding(width);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
      ),
      child: Text(
        'No notifications',
        style: GoogleFonts.inter(
          fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }
}
