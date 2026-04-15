import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/utils/file_picker_helper.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/components/appbars/superadmin_home_appbar.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/superadmin/utils/app_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NewTicketScreen extends StatefulWidget {
  const NewTicketScreen({super.key});

  @override
  State<NewTicketScreen> createState() => _NewTicketScreenState();
}

class _NewTicketScreenState extends State<NewTicketScreen> {
  final CancelToken _loadToken = CancelToken();
  final TextEditingController _titleController = TextEditingController();
  final List<PickedFilePayload> _attachments = <PickedFilePayload>[];
  bool _submitting = false;
  ApiClient? _api;
  SuperadminRepository? _repo;
  bool _loadingAdmins = false;
  bool _adminsErrorShown = false;
  List<AdminListItem> _admins = <AdminListItem>[];
  AdminListItem? _selectedAdmin;
  final TextEditingController _messageController = TextEditingController();
  String? _selectedCategory;
  String? _selectedPriority;

  @override
  void initState() {
    super.initState();
    _loadAdmins();
  }

  @override
  void dispose() {
    _loadToken.cancel('NewTicketScreen disposed');
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadAdmins() async {
    if (!mounted) return;
    setState(() => _loadingAdmins = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final res = await _repo!.getAdmins(
        page: 1,
        limit: 200,
        cancelToken: _loadToken,
      );
      if (!mounted) return;

      res.when(
        success: (items) {
          setState(() {
            _loadingAdmins = false;
            _admins = items;
            _selectedAdmin = null;
          });
        },
        failure: (err) {
          setState(() => _loadingAdmins = false);
          if (_adminsErrorShown) return;
          _adminsErrorShown = true;
          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load admins.'
              : "Couldn't load admins.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingAdmins = false);
      if (_adminsErrorShown) return;
      _adminsErrorShown = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't load admins.")));
    }
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
                          'Create Ticket (on behalf of Admin)',
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
                              const TextSpan(text: 'Admin'),
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
                        if (_loadingAdmins)
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
                                  await showModalBottomSheet<AdminListItem>(
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
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        16,
                                        16,
                                        16,
                                        8,
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 42,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: cs.onSurface
                                                  .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(2),
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Select Admin',
                                            style: GoogleFonts.roboto(
                                              fontWeight: FontWeight.w600,
                                              color: cs.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            height:
                                                MediaQuery.of(ctx).size.height *
                                                    0.7,
                                            child: Column(
                                              children: [
                                                Expanded(
                                                  child: ListView.separated(
                                                    itemCount: _admins.length,
                                                    separatorBuilder: (_, __) =>
                                                        const SizedBox(
                                                      height: 8,
                                                    ),
                                                    itemBuilder: (_, index) {
                                                      final admin =
                                                          _admins[index];
                                                      final title =
                                                          admin.name.isNotEmpty
                                                              ? admin.name
                                                              : admin.email
                                                                      .isNotEmpty
                                                                  ? admin.email
                                                                  : admin.id;
                                                      final subtitle =
                                                          admin.email.isNotEmpty
                                                              ? admin.email
                                                              : admin.id;
                                                      return ListTile(
                                                        contentPadding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                          horizontal: 6,
                                                        ),
                                                        title: Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                title,
                                                                maxLines: 2,
                                                                softWrap: true,
                                                                overflow:
                                                                    TextOverflow
                                                                        .visible,
                                                                style:
                                                                    GoogleFonts
                                                                        .roboto(
                                                                  fontSize:
                                                                      14 * scale,
                                                                  height: 20 / 14,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        subtitle: Row(
                                                          children: [
                                                            Expanded(
                                                              child: Text(
                                                                subtitle,
                                                                maxLines: 2,
                                                                softWrap: true,
                                                                overflow:
                                                                    TextOverflow
                                                                        .visible,
                                                                style:
                                                                    GoogleFonts
                                                                        .roboto(
                                                                  fontSize:
                                                                      12 * scale,
                                                                  height: 16 / 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w500,
                                                                  color: cs
                                                                      .onSurface
                                                                      .withOpacity(
                                                                    0.6,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        onTap: () =>
                                                            Navigator.pop(
                                                          ctx,
                                                          admin,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                              if (chosen != null) {
                                setState(() => _selectedAdmin = chosen);
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _selectedAdmin != null
                                          ? (_selectedAdmin!.name.isNotEmpty
                                              ? _selectedAdmin!.name
                                              : _selectedAdmin!.email.isNotEmpty
                                                  ? _selectedAdmin!.email
                                                  : _selectedAdmin!.id)
                                          : 'Select admin',
                                      maxLines: 2,
                                      softWrap: true,
                                      overflow: TextOverflow.visible,
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
                              const TextSpan(text: 'Title'),
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
                          controller: _titleController,
                          maxLength: 30,
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
                            valueListenable: _titleController,
                            builder: (_, value, __) {
                              return Text(
                                '${value.text.length}/30',
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
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Category', style: labelStyle),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () async {
                                      final chosen = await showModalBottomSheet<
                                          String>(
                                        context: context,
                                        backgroundColor: cs.surface,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(16),
                                          ),
                                        ),
                                        builder: (ctx) {
                                          final items = [
                                            'Billing',
                                            'Technical',
                                            'Other',
                                          ];
                                          return SafeArea(
                                            child: ListView.separated(
                                              padding: const EdgeInsets.all(16),
                                              itemCount: items.length,
                                              separatorBuilder: (_, __) =>
                                                  const SizedBox(height: 8),
                                              itemBuilder: (_, index) {
                                                final item = items[index];
                                                return ListTile(
                                                  title: Text(
                                                    item,
                                                    style: GoogleFonts.roboto(
                                                      fontSize: 14 * scale,
                                                      height: 20 / 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  onTap: () =>
                                                      Navigator.pop(ctx, item),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      );
                                      if (chosen != null) {
                                        setState(
                                          () => _selectedCategory = chosen,
                                        );
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
                                              _selectedCategory ?? 'Select',
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
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Priority', style: labelStyle),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () async {
                                      final chosen = await showModalBottomSheet<
                                          String>(
                                        context: context,
                                        backgroundColor: cs.surface,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(16),
                                          ),
                                        ),
                                        builder: (ctx) {
                                          final items = ['Low', 'Medium', 'High'];
                                          return SafeArea(
                                            child: ListView.separated(
                                              padding: const EdgeInsets.all(16),
                                              itemCount: items.length,
                                              separatorBuilder: (_, __) =>
                                                  const SizedBox(height: 8),
                                              itemBuilder: (_, index) {
                                                final item = items[index];
                                                return ListTile(
                                                  title: Text(
                                                    item,
                                                    style: GoogleFonts.roboto(
                                                      fontSize: 14 * scale,
                                                      height: 20 / 14,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  onTap: () =>
                                                      Navigator.pop(ctx, item),
                                                );
                                              },
                                            ),
                                          );
                                        },
                                      );
                                      if (chosen != null) {
                                        setState(
                                          () => _selectedPriority = chosen,
                                        );
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
                                              _selectedPriority ?? 'Select',
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
                                ],
                              ),
                            ),
                          ],
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
                          minLines: 5,
                          maxLines: 5,
                          maxLength: 1000,
                          style: GoogleFonts.roboto(
                            fontSize: 14 * scale,
                            height: 20 / 14,
                            fontWeight: FontWeight.w500,
                            color: cs.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Describe the issue in detail',
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
                            valueListenable: _messageController,
                            builder: (_, value, __) {
                              return Text(
                                '${value.text.length}/1000',
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
                        Text('Attachments', style: labelStyle),
                        const SizedBox(height: 8),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            if (_attachments.length >= 5) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Max 5 files allowed.'),
                                ),
                              );
                              return;
                            }
                            final file = await pickSingleFilePayload();
                            if (!mounted) return;
                            if (file == null) return;
                            if (file.bytes.length > 5 * 1024 * 1024) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Max file size is 5MB.'),
                                ),
                              );
                              return;
                            }
                            setState(() => _attachments.add(file));
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: cs.onSurface.withOpacity(0.12),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: cs.onSurface.withOpacity(0.08),
                                  ),
                                  alignment: Alignment.center,
                                  child: Icon(
                                    Icons.attach_file,
                                    size: 18 * scale,
                                    color: cs.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Click to attach files',
                                  style: GoogleFonts.roboto(
                                    fontSize: 13 * scale,
                                    height: 18 / 13,
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurface.withOpacity(0.7),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Max 5 files, 5MB each',
                                  style: GoogleFonts.roboto(
                                    fontSize: 11 * scale,
                                    height: 14 / 11,
                                    fontWeight: FontWeight.w500,
                                    color: cs.onSurface.withOpacity(0.5),
                                  ),
                                ),
                                if (_attachments.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Column(
                                    children: [
                                      for (final f in _attachments)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 4,
                                          ),
                                          child: Text(
                                            f.filename,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.roboto(
                                              fontSize: 11 * scale,
                                              height: 14 / 11,
                                              fontWeight: FontWeight.w500,
                                              color: cs.onSurface
                                                  .withOpacity(0.6),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: cs.onSurface.withOpacity(0.12)),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _submitting
                                    ? null
                                    : () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  side: BorderSide(
                                    color: cs.onSurface.withOpacity(0.2),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Cancel',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14 * scale,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w600,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _submitting
                                    ? null
                                    : () async {
                                        if (_selectedAdmin == null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text('Select an admin.'),
                                            ),
                                          );
                                          return;
                                        }
                                        if (_selectedCategory == null ||
                                            _selectedPriority == null) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Select category and priority.'),
                                            ),
                                          );
                                          return;
                                        }
                                        if (_titleController.text
                                            .trim()
                                            .isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text('Title required.'),
                                            ),
                                          );
                                          return;
                                        }
                                        final msgText =
                                            _messageController.text.trim();
                                        if (msgText.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text('Message required.'),
                                            ),
                                          );
                                          return;
                                        }
                                        if (msgText.length < 10) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Message must be at least 10 characters.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        setState(() => _submitting = true);
                                        try {
                                          _api ??= ApiClient(
                                            config:
                                                AppConfig.fromDartDefine(),
                                            tokenStorage:
                                                TokenStorage.defaultInstance(),
                                          );
                                          _repo ??=
                                              SuperadminRepository(api: _api!);
                                          final res =
                                              await _repo!.createTicket(
                                            message:
                                                msgText,
                                            category: _selectedCategory!
                                                .toUpperCase(),
                                            priority: _selectedPriority!
                                                .toUpperCase(),
                                            subject: _titleController.text
                                                .trim(),
                                            adminId: _selectedAdmin?.id,
                                            cancelToken: _loadToken,
                                          );
                                          if (!mounted) return;
                                          res.when(
                                            success: (_) {
                                              setState(
                                                () => _submitting = false,
                                              );
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                      'Ticket created.'),
                                                ),
                                              );
                                              Navigator.pop(context, true);
                                            },
                                            failure: (err) {
                                              setState(
                                                () => _submitting = false,
                                              );
                                              final msg =
                                                  (err is ApiException &&
                                                          (err.statusCode ==
                                                                  401 ||
                                                              err.statusCode ==
                                                                  403))
                                                      ? 'Not authorized.'
                                                      : "Couldn't create ticket.";
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(content: Text(msg)),
                                              );
                                            },
                                          );
                                        } catch (_) {
                                          if (!mounted) return;
                                          setState(
                                            () => _submitting = false,
                                          );
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content:
                                                  Text("Couldn't create ticket."),
                                            ),
                                          );
                                        }
                                      },
                                icon: _submitting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.add),
                                label: Text(
                                  'Create Ticket',
                                  style: GoogleFonts.roboto(
                                    fontSize: 14 * scale,
                                    height: 20 / 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  backgroundColor: cs.primary,
                                  foregroundColor: cs.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
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
              child: const SuperAdminHomeAppBar(
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
