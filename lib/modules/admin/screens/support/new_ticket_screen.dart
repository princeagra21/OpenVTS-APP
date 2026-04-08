import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_user_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_support_repository.dart';
import 'package:fleet_stack/core/repositories/admin_users_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/admin/components/appbars/admin_home_appbar.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key});

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  final CancelToken _loadToken = CancelToken();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _submitting = false;
  bool _loadingUsers = false;
  bool _usersErrorShown = false;

  List<AdminUserListItem> _users = <AdminUserListItem>[];
  AdminUserListItem? _selectedUser;

  ApiClient? _api;
  AdminUsersRepository? _usersRepo;
  AdminSupportRepository? _supportRepo;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _loadToken.cancel('NewTicketScreen disposed');
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  AdminUsersRepository _usersRepoOrCreate() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _usersRepo ??= AdminUsersRepository(api: _api!);
    return _usersRepo!;
  }

  AdminSupportRepository _supportRepoOrCreate() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _supportRepo ??= AdminSupportRepository(api: _api!);
    return _supportRepo!;
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() => _loadingUsers = true);

    try {
      final res = await _usersRepoOrCreate().getUsers(
        page: 1,
        limit: 200,
        cancelToken: _loadToken,
      );
      if (!mounted) return;

      res.when(
        success: (items) {
          setState(() {
            _loadingUsers = false;
            _users = items;
            _selectedUser = null;
          });
        },
        failure: (err) {
          setState(() => _loadingUsers = false);
          if (_usersErrorShown) return;
          _usersErrorShown = true;
          final msg =
              (err is ApiException && (err.statusCode == 401 || err.statusCode == 403))
                  ? 'Not authorized to load users.'
                  : "Couldn't load users.";
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingUsers = false);
      if (_usersErrorShown) return;
      _usersErrorShown = true;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Couldn't load users.")));
    }
  }

  Future<void> _submit() async {
    final user = _selectedUser;
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Select a user first.')));
      return;
    }
    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject and message are required.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _submitting = true);

    final res = await _supportRepoOrCreate().createTicket(
      userId: user.id,
      subject: subject,
      message: message,
      cancelToken: _loadToken,
    );

    if (!mounted) return;

    res.when(
      success: (_) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ticket created.')));
        Navigator.pop(context, true);
      },
      failure: (err) {
        setState(() => _submitting = false);
        final msg = err is ApiException
            ? err.message
            : "Couldn't create ticket.";
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(width) + 6;
    final topPadding = MediaQuery.of(context).padding.top;
    final scale = (width / 420).clamp(0.9, 1.0);
    final labelStyle = GoogleFonts.roboto(
      fontSize: 12 * scale,
      height: 16 / 12,
      fontWeight: FontWeight.w600,
      color: cs.onSurface.withOpacity(0.7),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F7),
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                padding,
                topPadding + AppUtils.appBarHeightCustom + 28,
                padding,
                padding,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: cs.onSurface.withOpacity(0.1),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Create Ticket (on behalf of User)',
                            style: GoogleFonts.roboto(
                              fontSize: 16 * scale,
                              height: 20 / 16,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          RichText(
                            text: TextSpan(
                              style: labelStyle,
                              children: [
                                const TextSpan(text: 'User'),
                                TextSpan(
                                  text: ' *',
                                  style: labelStyle.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (_loadingUsers)
                            const AppShimmer(
                              width: double.infinity,
                              height: 52,
                              radius: 12,
                            )
                          else
                            InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                final chosen =
                                    await showModalBottomSheet<AdminUserListItem>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: cs.surface,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                  ),
                                  builder: (ctx) {
                                    return SafeArea(
                                      child: SizedBox(
                                        height:
                                            MediaQuery.of(ctx).size.height * 0.7,
                                        child: ListView.separated(
                                          padding: const EdgeInsets.all(16),
                                          itemCount: _users.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 8),
                                          itemBuilder: (_, index) {
                                            final user = _users[index];
                                            final title = user.fullName.isNotEmpty
                                                ? user.fullName
                                                : user.email.isNotEmpty
                                                    ? user.email
                                                    : user.id;
                                            final subtitle = user.email.isNotEmpty
                                                ? user.email
                                                : user.id;
                                            return ListTile(
                                              title: Text(
                                                title,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.roboto(
                                                  fontSize: 14 * scale,
                                                  height: 20 / 14,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              subtitle: Text(
                                                subtitle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: GoogleFonts.roboto(
                                                  fontSize: 12 * scale,
                                                  height: 16 / 12,
                                                  fontWeight: FontWeight.w500,
                                                  color:
                                                      cs.onSurface.withOpacity(0.6),
                                                ),
                                              ),
                                              onTap: () => Navigator.pop(ctx, user),
                                            );
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                );
                                if (chosen != null) {
                                  setState(() => _selectedUser = chosen);
                                }
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: cs.onSurface.withOpacity(0.12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _selectedUser != null
                                            ? (_selectedUser!.fullName.isNotEmpty
                                                ? _selectedUser!.fullName
                                                : _selectedUser!.email.isNotEmpty
                                                    ? _selectedUser!.email
                                                    : _selectedUser!.id)
                                            : 'Select user',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.roboto(
                                          fontSize: 14 * scale,
                                          height: 20 / 14,
                                          fontWeight: FontWeight.w500,
                                          color: cs.onSurface,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      Icons.expand_more,
                                      color: cs.onSurface.withOpacity(0.6),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 16),
                          RichText(
                            text: TextSpan(
                              style: labelStyle,
                              children: [
                                const TextSpan(text: 'Subject'),
                                TextSpan(
                                  text: ' *',
                                  style: labelStyle.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _subjectController,
                            maxLength: 60,
                            style: GoogleFonts.roboto(
                              fontSize: 14 * scale,
                              height: 20 / 14,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Brief description of the issue',
                              counterText: '',
                              hintStyle: GoogleFonts.roboto(
                                fontSize: 14 * scale,
                                height: 20 / 14,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface.withOpacity(0.5),
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: cs.onSurface.withOpacity(0.12),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: cs.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _subjectController,
                              builder: (_, value, __) {
                                return Text(
                                  '${value.text.length}/60',
                                  style: GoogleFonts.roboto(
                                    fontSize: 11 * scale,
                                    height: 14 / 11,
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurface.withOpacity(0.6),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          RichText(
                            text: TextSpan(
                              style: labelStyle,
                              children: [
                                const TextSpan(text: 'Message'),
                                TextSpan(
                                  text: ' *',
                                  style: labelStyle.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _messageController,
                            minLines: 4,
                            maxLines: 6,
                            style: GoogleFonts.roboto(
                              fontSize: 14 * scale,
                              height: 20 / 14,
                              fontWeight: FontWeight.w500,
                              color: cs.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Describe the issue in detail',
                              hintStyle: GoogleFonts.roboto(
                                fontSize: 14 * scale,
                                height: 20 / 14,
                                fontWeight: FontWeight.w500,
                                color: cs.onSurface.withOpacity(0.5),
                              ),
                              filled: true,
                              fillColor: Colors.transparent,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: cs.onSurface.withOpacity(0.12),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: cs.primary,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: InkWell(
                              onTap: _submitting ? null : _submit,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: cs.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_submitting)
                                      const AppShimmer(
                                        width: 34,
                                        height: 12,
                                        radius: 6,
                                      )
                                    else ...[
                                      Icon(
                                        Icons.send,
                                        size: 16,
                                        color: cs.onPrimary,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Create Ticket',
                                        style: GoogleFonts.roboto(
                                          fontSize: 14 * scale,
                                          height: 20 / 14,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onPrimary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: padding,
            right: padding,
            top: 0,
            child: Container(
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF0A0A0A)
                  : const Color(0xFFF5F5F7),
              child: const AdminHomeAppBar(
                title: 'Create Ticket',
                leadingIcon: Icons.support_agent_outlined,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
