import 'package:open_vts/features/admin/domain/entities/admin_notification_item.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/shared/widgets/push_notification_banner.dart';
import 'package:open_vts/features/superadmin/presentation/components/appbars/superadmin_home_appbar.dart';
import 'package:open_vts/features/superadmin/presentation/layout/app_layout.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/shell/presentation/controllers/role_notifications_controller.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/router/route_names.dart';
import 'package:open_vts/features/shell/presentation/controllers/push_notification_controller.dart';


class SuperadminNotificationsScreen extends ConsumerStatefulWidget {
  const SuperadminNotificationsScreen({super.key});

  @override
  ConsumerState<SuperadminNotificationsScreen> createState() =>
      _SuperadminNotificationsScreenState();
}

class _SuperadminNotificationsScreenState
    extends ConsumerState<SuperadminNotificationsScreen> {
  static const _notificationsPath = AppRoutePaths.superadminNotifications;

  ProviderSubscription<RoleNotificationsState>? _notificationErrorSubscription;
  ProviderSubscription<PushNotificationState>? _pushErrorSubscription;

  @override
  void initState() {
    super.initState();
    _notificationErrorSubscription = ref.listenManual<RoleNotificationsState>(
      roleNotificationsControllerProvider(_notificationsPath),
      (previous, next) {
        final message = next.errorMessage;
        if (message == null || message == previous?.errorMessage || !mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      },
    );
    _pushErrorSubscription = ref.listenManual<PushNotificationState>(
      pushNotificationControllerProvider,
      (previous, next) {
        final message = next.errorMessage;
        if (message == null || message == previous?.errorMessage || !mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      },
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadNotifications();
      ref.read(pushNotificationControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _notificationErrorSubscription?.close();
    _pushErrorSubscription?.close();
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

  Future<void> _loadNotifications() async {
    await ref.read(roleNotificationsControllerProvider(_notificationsPath).notifier).load();
  }

  Future<void> _togglePushState() async {
    await ref.read(pushNotificationControllerProvider.notifier).toggle();
  }

  Future<void> _markOneRead(AdminNotificationItem item) async {
    if (item.isRead) return;
    await ref.read(roleNotificationsControllerProvider(_notificationsPath).notifier).markRead(item.id);
  }

  Future<void> _markAllRead() async {
    final state = ref.read(roleNotificationsControllerProvider(_notificationsPath));
    if (state.isLoading || state.items.isEmpty) return;
    await ref.read(roleNotificationsControllerProvider(_notificationsPath).notifier).markAllRead();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final notificationsState = ref.watch(roleNotificationsControllerProvider(_notificationsPath));
    final pushNotificationState = ref.watch(pushNotificationControllerProvider);
    final items = notificationsState.items;
    final pushDeviceState = pushNotificationState.deviceState;
    final pushLoading = pushNotificationState.isLoading;
    final pushActionLoading = pushNotificationState.isUpdating;

    return AppLayout(
      title: 'Open VTS',
      subtitle: 'Notifications',
      showAppBar: false,
      customTopBar: const SuperAdminHomeAppBar(
        title: 'Notifications',
        leadingIcon: Icons.notifications_outlined,
      ),
      customTopBarPadding: EdgeInsets.zero,
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Inbox',
                    style: AppFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(width),
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _markAllRead,
                  tooltip: 'Mark all as read',
                  icon: Icon(
                    Icons.done_all,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${items.length} notifications',
              style: AppFonts.inter(
                fontSize: AdaptiveUtils.getTitleFontSize(width),
                color: colorScheme.onSurface.withOpacity(0.54),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 16),
            if ((pushDeviceState?.canShowBanner ?? false) || pushLoading)
              if (pushDeviceState != null)
                PushNotificationBanner(
                  state: pushDeviceState,
                  loading: pushActionLoading || pushLoading,
                  onPressed: _togglePushState,
                )
              else
                const _PushBannerShimmer(),
            if (notificationsState.isLoading)
              const _NotificationShimmerList()
            else if (items.isEmpty)
              const _EmptyNotificationsCard()
            else
              ...items.map(
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
                    style: AppFonts.inter(
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
                    style: AppFonts.inter(
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
              style: AppFonts.inter(
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
              style: AppFonts.inter(
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
        style: AppFonts.inter(
          fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 3,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface.withOpacity(0.7),
        ),
      ),
    );
  }
}

