// components/admin/delete_account_box.dart
import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DeleteAccountBox extends StatefulWidget {
  final String adminId;

  const DeleteAccountBox({super.key, required this.adminId});

  @override
  State<DeleteAccountBox> createState() => _DeleteAccountBoxState();
}

class _DeleteAccountBoxState extends State<DeleteAccountBox> {
  bool _submitting = false;
  bool _snackShown = false;
  CancelToken? _token;

  ApiClient? _api;
  SuperadminRepository? _repo;

  @override
  void dispose() {
    _token?.cancel('dispose');
    super.dispose();
  }

  void _ensureRepo() {
    if (_api != null) return;
    _api = ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo = SuperadminRepository(api: _api!);
  }

  void _snackOnce(String msg) {
    if (!mounted || _snackShown) return;
    _snackShown = true;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _confirmDelete() async {
    final colorScheme = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double fontSize = AdaptiveUtils.getTitleFontSize(w);

    final ok = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            'Delete admin?',
            style: GoogleFonts.inter(
              fontSize: fontSize + 2,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          content: Text(
            'This action cannot be undone.',
            style: GoogleFonts.inter(
              fontSize: fontSize,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: GoogleFonts.inter(color: colorScheme.onSurface),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(
                'Delete',
                style: GoogleFonts.inter(color: colorScheme.error),
              ),
            ),
          ],
        );
      },
    );

    return ok == true;
  }

  Future<void> _delete() async {
    if (_submitting) return;
    _snackShown = false;

    final confirmed = await _confirmDelete();
    if (!confirmed) return;

    _ensureRepo();
    _token?.cancel('resubmit');
    _token = CancelToken();

    if (!mounted) return;
    setState(() => _submitting = true);

    try {
      final res = await _repo!.deleteAdmin(
        widget.adminId,
        cancelToken: _token,
      );
      if (!mounted) return;

      if (res.isSuccess) {
        // Return `true` so the list screen can refresh + show success feedback.
        Navigator.of(context).pop(true);
        return;
      }

      final err = res.error;
      if (err is ApiException && (err.statusCode == 401 || err.statusCode == 403)) {
        _snackOnce('Not authorized.');
      } else {
        _snackOnce("Couldn't delete admin.");
      }
    } catch (_) {
      if (!mounted) return;
      _snackOnce("Couldn't delete admin.");
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(screenWidth);
    final double fontSize = AdaptiveUtils.getTitleFontSize(screenWidth);

    // Semantic error color — works perfectly in light & dark mode
    final Color dangerColor = colorScheme.error;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: dangerColor, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Danger Zone",
            style: GoogleFonts.inter(
              fontSize: fontSize + 2,
              fontWeight: FontWeight.bold,
              color: dangerColor,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "This action cannot be undone. It will permanently delete the user account and remove all associated data.",
                  style: GoogleFonts.inter(
                    fontSize: fontSize,
                    color: dangerColor,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _submitting ? null : _delete,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: dangerColor, width: 2),
                  backgroundColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: padding * 2,
                    vertical: padding,
                  ),
                ),
                child: _submitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(dangerColor),
                        ),
                      )
                    : Text(
                        "Delete",
                        style: GoogleFonts.inter(
                          fontSize: fontSize,
                          color: dangerColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
