import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/user_support_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/admin/utils/app_utils.dart';
import 'package:fleet_stack/modules/user/components/appbars/user_home_appbar.dart';
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
  final TextEditingController _messageController = TextEditingController();

  bool _submitting = false;
  String? _selectedCategory;
  String? _selectedPriority;

  ApiClient? _api;
  UserSupportRepository? _supportRepo;

  @override
  void dispose() {
    _loadToken.cancel('NewTicketScreen disposed');
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  UserSupportRepository _supportRepoOrCreate() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _supportRepo ??= UserSupportRepository(api: _api!);
    return _supportRepo!;
  }

  Future<String?> _pickOption(
    BuildContext context,
    String title,
    List<String> items,
  ) async {
    final cs = Theme.of(context).colorScheme;
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.5,
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final item = items[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: cs.surface,
                        title: Text(
                          item,
                          style: GoogleFonts.roboto(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        onTap: () => Navigator.pop(ctx, item),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    final category = _selectedCategory;
    final priority = _selectedPriority;

    if (title.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title and message are required.')),
      );
      return;
    }
    if (category == null || priority == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select category and priority.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _submitting = true);

    final res = await _supportRepoOrCreate().createTicket(
      title: title,
      category: category,
      priority: priority,
      message: message,
      cancelToken: _loadToken,
    );

    if (!mounted) return;

    res.when(
      success: (_) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket created.')),
        );
        Navigator.pop(context, true);
      },
      failure: (err) {
        setState(() => _submitting = false);
        final msg = err is ApiException && err.message.trim().isNotEmpty
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

    Widget selectionField({
      required String label,
      required String value,
      required VoidCallback onTap,
    }) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: labelStyle),
          const SizedBox(height: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: cs.onSurface.withOpacity(0.12)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
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
      );
    }

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
                            'Create Ticket',
                            style: GoogleFonts.roboto(
                              fontSize: 16 * scale,
                              height: 20 / 16,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Title', style: labelStyle),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _titleController,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.roboto(
                              fontSize: 14 * scale,
                              height: 20 / 14,
                              color: cs.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Ticket title',
                              hintStyle: GoogleFonts.roboto(
                                fontSize: 14 * scale,
                                height: 20 / 14,
                                color: cs.onSurface.withOpacity(0.4),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: selectionField(
                                  label: 'Category',
                                  value: _selectedCategory ?? 'Select',
                                  onTap: () async {
                                    final chosen = await _pickOption(
                                      context,
                                      'Select Category',
                                      const [
                                        'SERVER',
                                        'NOTIFICATION',
                                        'INSTALLATION',
                                        'MAPS',
                                        'BILLING',
                                        'OTHERS',
                                      ],
                                    );
                                    if (chosen != null) {
                                      setState(() => _selectedCategory = chosen);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: selectionField(
                                  label: 'Priority',
                                  value: _selectedPriority ?? 'Select',
                                  onTap: () async {
                                    final chosen = await _pickOption(
                                      context,
                                      'Select Priority',
                                      const ['LOW', 'MEDIUM', 'HIGH'],
                                    );
                                    if (chosen != null) {
                                      setState(() => _selectedPriority = chosen);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text('Message', style: labelStyle),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _messageController,
                            minLines: 4,
                            maxLines: 6,
                            style: GoogleFonts.roboto(
                              fontSize: 14 * scale,
                              height: 20 / 14,
                              color: cs.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Tell us more...',
                              hintStyle: GoogleFonts.roboto(
                                fontSize: 14 * scale,
                                height: 20 / 14,
                                color: cs.onSurface.withOpacity(0.4),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _submitting
                                      ? null
                                      : () => Navigator.pop(context, false),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(46),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    'Cancel',
                                    style: GoogleFonts.roboto(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _submitting ? null : _submit,
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(46),
                                    backgroundColor: cs.primary,
                                    foregroundColor: cs.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: _submitting
                                      ? const SizedBox(
                                          height: 18,
                                          width: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Create',
                                          style: GoogleFonts.roboto(
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
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: padding,
            right: padding,
            top: 0,
            child: UserHomeAppBar(
              title: 'New Ticket',
              leadingIcon: Icons.support_agent_outlined,
              onClose: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
