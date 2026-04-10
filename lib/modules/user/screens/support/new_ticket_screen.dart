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
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  bool _submitting = false;

  ApiClient? _api;
  UserSupportRepository? _supportRepo;

  @override
  void dispose() {
    _loadToken.cancel('NewTicketScreen disposed');
    _subjectController.dispose();
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

  Future<void> _submit() async {
    final subject = _subjectController.text.trim();
    final message = _messageController.text.trim();

    if (subject.isEmpty || message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject and message are required.')),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _submitting = true);

    final res = await _supportRepoOrCreate().createTicket(
      subject: subject,
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
                          Text('Subject', style: labelStyle),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _subjectController,
                            textInputAction: TextInputAction.next,
                            style: GoogleFonts.roboto(
                              fontSize: 14 * scale,
                              height: 20 / 14,
                              color: cs.onSurface,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Subject',
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
                                  onPressed:
                                      _submitting ? null : () => Navigator.pop(
                                    context,
                                    false,
                                  ),
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
