import 'package:open_vts/core/theme/app_fonts.dart';
// components/admin/delete_account_box.dart
import 'package:open_vts/core/utils/app_cancellation.dart';
import 'package:open_vts/core/error/legacy_error_presenter.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/shared/presentation/providers/legacy_repository_facade_providers.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class DeleteAccountBox extends ConsumerStatefulWidget {
  final String adminId;

  const DeleteAccountBox({super.key, required this.adminId});

  @override
  ConsumerState<DeleteAccountBox> createState() => _DeleteAccountBoxState();
}

class _DeleteAccountBoxState extends ConsumerState<DeleteAccountBox> {
  bool _submitting = false;
  bool _snackShown = false;
  AppCancellationHandle? _token;
  SuperadminRepository? _repo;

  @override
  void dispose() {
    _token?.cancel('dispose');
    super.dispose();
  }

  void _ensureRepo() {
    if (_repo != null) return;
    _repo = ref.read(superadminRepositoryAdapterProvider);
  }

  void _snackOnce(String msg) {
    if (!mounted || _snackShown) return;
    _snackShown = true;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _confirmDelete() async {
    final colorScheme = Theme.of(context).colorScheme;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colorScheme.error.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: colorScheme.error,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Delete admin?',
                      style: AppFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'This will permanently remove the admin and all related data. You can’t undo this action.',
                style: AppFonts.roboto(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppFonts.roboto(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(46),
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Delete',
                        style: AppFonts.roboto(fontWeight: FontWeight.w700),
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

    return ok == true;
  }

  Future<void> _delete() async {
    if (_submitting) return;
    _snackShown = false;

    final confirmed = await _confirmDelete();
    if (!confirmed) return;

    _ensureRepo();
    _token?.cancel('resubmit');
    _token = AppCancellationHandle();

    if (!mounted) return;
    updateLocalUiState(this, () => _submitting = true);

    try {
      final res = await _repo!.deleteAdmin(widget.adminId, cancelToken: _token);
      if (!mounted) return;

      if (res.isSuccess) {
        // Return `true` so the list screen can refresh + show success feedback.
        Navigator.of(context).pop(true);
        return;
      }

      final err = res.error;
      if (LegacyErrorPresenter.isApiFailure(err) &&
          (LegacyErrorPresenter.statusCode(err) == 401 || LegacyErrorPresenter.statusCode(err) == 403)) {
        _snackOnce('Not authorized.');
      } else if (LegacyErrorPresenter.isApiFailure(err) && LegacyErrorPresenter.message(err).trim().isNotEmpty) {
        _snackOnce(LegacyErrorPresenter.message(err));
      } else {
        _snackOnce("Couldn't delete admin.");
      }
    } catch (_) {
      if (!mounted) return;
      _snackOnce("Couldn't delete admin.");
    } finally {
      if (mounted) updateLocalUiState(this, () => _submitting = false);
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
            style: AppFonts.roboto(
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
                  style: AppFonts.roboto(
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
                    ? const AppShimmer(width: 18, height: 18, radius: 9)
                    : Text(
                        "Delete",
                        style: AppFonts.roboto(
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
