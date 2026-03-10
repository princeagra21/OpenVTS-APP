// lib/screens/notifications/notify_users_screen.dart
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_user_recipient.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_notification_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/card/search_bar.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotifyUsersScreen extends StatefulWidget {
  const NotifyUsersScreen({super.key});

  @override
  State<NotifyUsersScreen> createState() => _NotifyUsersScreenState();
}

class _NotifyUsersScreenState extends State<NotifyUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  /// FleetStack-API-Reference.md (Admin section) confirmed endpoints:
  /// - GET /admin/users (query: search)
  /// - GET /admin/shortusers (alternative list endpoint)
  /// - No ADMIN send-notification POST endpoint documented.
  ///   Send action is kept local-safe with "API not available yet".
  AdminNotificationRepository? _repo;
  ApiClient? _api;
  Timer? _searchDebounce;

  bool _loadingRecipients = false;
  bool _sending = false;
  bool _loadErrorShown = false;
  bool _sendErrorShown = false;

  CancelToken? _loadToken;
  CancelToken? _sendToken;

  String _query = '';
  List<AdminUserRecipient> _recipients = const [];
  final Set<String> _selectedUserIds = <String>{};

  final List<bool> _channels = [true, false]; // [email, in-app]

  @override
  void initState() {
    super.initState();
    _messageController.text = 'Hello, this is a quick update for you.';
    _searchController.addListener(_onSearchChanged);
    _loadRecipients(query: '');
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _loadToken?.cancel('Notify users disposed');
    _sendToken?.cancel('Notify users disposed');
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  String _recipientKey(AdminUserRecipient user) {
    final id = user.id.trim();
    if (id.isNotEmpty) return id;
    final email = user.email.trim();
    if (email.isNotEmpty) return email;
    return user.name.trim();
  }

  void _onSearchChanged() {
    final next = _searchController.text.trim();
    if (next == _query) return;
    _query = next;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), () {
      _loadRecipients(query: _query);
    });
  }

  int get _recipientCount => _selectedUserIds.length;
  int get _channelCount => _channels.where((c) => c).length;

  Future<void> _loadRecipients({required String query}) async {
    _loadToken?.cancel('Reload recipients');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loadingRecipients = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= AdminNotificationRepository(api: _api!);

      final res = await _repo!.searchRecipients(
        query: query,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (users) {
          if (!mounted) return;
          setState(() {
            _recipients = users;
            _loadingRecipients = false;
            _loadErrorShown = false;
          });
        },
        failure: (error) {
          if (!mounted) return;
          setState(() {
            _recipients = const [];
            _loadingRecipients = false;
          });
          if (_loadErrorShown) return;
          _loadErrorShown = true;
          final msg = error is ApiException
              ? (error.message.trim().isNotEmpty
                    ? error.message
                    : "Couldn't load recipients.")
              : "Couldn't load recipients.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recipients = const [];
        _loadingRecipients = false;
      });
      if (_loadErrorShown) return;
      _loadErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load recipients.")),
      );
    }
  }

  Future<void> _openUserMultiSelectDialog() async {
    final tempSelected = Set<String>.from(_selectedUserIds);
    final dialogSearchController = TextEditingController();
    String dialogFilter = '';

    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 24,
          ),
          contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          titlePadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          title: Text(
            'Select recipients',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: StatefulBuilder(
              builder: (context, dialogSetState) {
                final visible = _recipients.where((user) {
                  if (dialogFilter.isEmpty) return true;
                  return user.name.toLowerCase().contains(dialogFilter) ||
                      user.email.toLowerCase().contains(dialogFilter);
                }).toList();

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: dialogSearchController,
                      onChanged: (value) {
                        dialogSetState(() {
                          dialogFilter = value.trim().toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Filter users...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: _loadingRecipients
                          ? ListView(
                              shrinkWrap: true,
                              children: const [
                                _RecipientShimmerTile(),
                                SizedBox(height: 8),
                                _RecipientShimmerTile(),
                                SizedBox(height: 8),
                                _RecipientShimmerTile(),
                              ],
                            )
                          : (visible.isEmpty
                                ? Center(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child: Text(
                                        'No users found',
                                        style: GoogleFonts.inter(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface
                                              .withOpacity(0.6),
                                        ),
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: visible.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, i) {
                                      final user = visible[i];
                                      final key = _recipientKey(user);
                                      final selected = tempSelected.contains(
                                        key,
                                      );

                                      return CheckboxListTile(
                                        value: selected,
                                        onChanged: (v) {
                                          dialogSetState(() {
                                            if (v == true) {
                                              tempSelected.add(key);
                                            } else {
                                              tempSelected.remove(key);
                                            }
                                          });
                                        },
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 4,
                                            ),
                                        visualDensity: VisualDensity.compact,
                                        title: Text(
                                          user.name.isEmpty ? '-' : user.name,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: Text(
                                          user.email.isEmpty ? '-' : user.email,
                                          style: GoogleFonts.inter(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.6),
                                          ),
                                        ),
                                        secondary: CircleAvatar(
                                          radius: 18,
                                          backgroundColor: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.12),
                                          child: Text(
                                            user.initials,
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  )),
                    ),
                  ],
                );
              },
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: GoogleFonts.inter()),
            ),
            ElevatedButton(
              onPressed: () {
                if (!mounted) return;
                setState(() {
                  _selectedUserIds
                    ..clear()
                    ..addAll(tempSelected);
                });
                Navigator.of(ctx).pop();
              },
              child: Text(
                'Done',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        );
      },
    );

    dialogSearchController.dispose();
  }

  Future<void> _sendNotifications() async {
    if (_sending) return;

    if (_recipientCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one recipient.')),
      );
      return;
    }
    if (_channelCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one channel.')),
      );
      return;
    }
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Message cannot be empty.')));
      return;
    }

    _sendToken?.cancel('Restart send');
    final token = CancelToken();
    _sendToken = token;

    if (!mounted) return;
    setState(() {
      _sending = true;
      _sendErrorShown = false;
    });

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= AdminNotificationRepository(api: _api!);

      final channel = _channels[0] ? 'EMAIL' : 'IN_APP';
      final res = await _repo!.sendNotification(
        channel: channel,
        userIds: _selectedUserIds.toList(),
        subject: _subjectController.text.trim().isEmpty
            ? null
            : _subjectController.text.trim(),
        message: _messageController.text.trim(),
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (_) {
          if (!mounted) return;
          setState(() => _sending = false);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Sent')));
          Navigator.of(context).pop(true);
        },
        failure: (error) {
          if (!mounted) return;
          setState(() => _sending = false);
          if (_sendErrorShown) return;
          _sendErrorShown = true;

          if (kDebugMode &&
              error is ApiException &&
              error.message.toLowerCase().contains('not available')) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Send API not available yet')),
            );
            return;
          }

          final msg = error is ApiException
              ? (error.message.trim().isNotEmpty
                    ? error.message
                    : "Couldn't send notification.")
              : "Couldn't send notification.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      if (_sendErrorShown) return;
      _sendErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't send notification.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double pad = AdaptiveUtils.getHorizontalPadding(w);
    final double fs = AdaptiveUtils.getTitleFontSize(w);

    final selectedUsers = _recipients
        .where((u) => _selectedUserIds.contains(_recipientKey(u)))
        .toList();

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(pad * 1.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Notify Users',
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              AdminSearchField(
                controller: _searchController,
                hintText: 'Search users by name or email',
                onChanged: (_) {},
              ),
              const SizedBox(height: 10),
              Text('Channels'),
              SizedBox(height: pad - 2),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    _channelPill(
                      label: 'Email',
                      value: _channels[0],
                      onTap: _sending
                          ? () {}
                          : () => setState(() => _channels[0] = !_channels[0]),
                      cs: cs,
                    ),
                    const SizedBox(width: 8),
                    _channelPill(
                      label: 'In-app',
                      value: _channels[1],
                      onTap: _sending
                          ? () {}
                          : () => setState(() => _channels[1] = !_channels[1]),
                      cs: cs,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _MultiSelectDropdown(
                label: 'Recipients',
                hint: _loadingRecipients
                    ? 'Loading recipients...'
                    : (_recipients.isEmpty
                          ? 'No users found'
                          : 'Select recipients'),
                width: w,
                selectedUsers: selectedUsers,
                loading: _loadingRecipients,
                onTap: _openUserMultiSelectDialog,
                onClear: () {
                  setState(() => _selectedUserIds.clear());
                },
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 4,
                shadowColor: Colors.black.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subject (optional)',
                        style: GoogleFonts.inter(fontSize: fs - 2),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _subjectController,
                        decoration: InputDecoration(
                          hintText: 'Write a short subject',
                          hintStyle: GoogleFonts.inter(
                            color: cs.onSurface.withOpacity(0.6),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: cs.surfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Message *',
                        style: GoogleFonts.inter(
                          fontSize: fs - 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _messageController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Write your message here',
                            hintStyle: GoogleFonts.inter(
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: cs.surfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: cs.primary.withOpacity(0.28)),
                        foregroundColor: cs.primary,
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _sending ? null : _sendNotifications,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _sending
                          ? const AppShimmer(width: 34, height: 14, radius: 6)
                          : Text(
                              'Send',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _channelPill({
    required String label,
    required bool value,
    required VoidCallback onTap,
    required ColorScheme cs,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value ? cs.primary.withOpacity(0.12) : cs.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: value ? cs.primary : cs.onSurface.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(
              value ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: value ? cs.primary : cs.onSurface.withOpacity(0.8),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                color: value ? cs.primary : cs.onSurface.withOpacity(0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MultiSelectDropdown extends StatelessWidget {
  final String label;
  final String hint;
  final double width;
  final List<AdminUserRecipient> selectedUsers;
  final bool loading;
  final VoidCallback onTap;
  final VoidCallback onClear;

  const _MultiSelectDropdown({
    required this.label,
    required this.hint,
    required this.width,
    required this.selectedUsers,
    required this.loading,
    required this.onTap,
    required this.onClear,
  });

  String _summaryText() {
    if (selectedUsers.isEmpty) return '';
    if (selectedUsers.length == 1) return selectedUsers.first.name;
    final first = selectedUsers.first.name;
    final others = selectedUsers.length - 1;
    return '$first and $others other${others > 1 ? 's' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final fs = AdaptiveUtils.getTitleFontSize(width);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: fs),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: loading ? null : onTap,
          child: Container(
            height: 55,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: cs.surfaceVariant,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.onSurface.withOpacity(0.04)),
            ),
            child: loading
                ? const Row(
                    children: [
                      Expanded(
                        child: AppShimmer(
                          width: double.infinity,
                          height: 16,
                          radius: 7,
                        ),
                      ),
                      SizedBox(width: 10),
                      AppShimmer(width: 18, height: 18, radius: 9),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedUsers.isEmpty ? hint : _summaryText(),
                          style: GoogleFonts.inter(
                            color: selectedUsers.isEmpty
                                ? cs.onSurface.withOpacity(0.6)
                                : cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (selectedUsers.isNotEmpty)
                        GestureDetector(
                          onTap: onClear,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Icon(
                              Icons.clear,
                              size: 20,
                              color: cs.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ),
                      Icon(
                        Icons.arrow_drop_down,
                        color: cs.onSurface.withOpacity(0.6),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

class _RecipientShimmerTile extends StatelessWidget {
  const _RecipientShimmerTile();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        AppShimmer(width: 20, height: 20, radius: 4),
        SizedBox(width: 12),
        AppShimmer(width: 36, height: 36, radius: 18),
        SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppShimmer(width: double.infinity, height: 12, radius: 6),
              SizedBox(height: 6),
              AppShimmer(width: 160, height: 10, radius: 5),
            ],
          ),
        ),
      ],
    );
  }
}
