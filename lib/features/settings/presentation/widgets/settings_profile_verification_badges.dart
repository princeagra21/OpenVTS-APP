import 'package:flutter/material.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_button.dart';
import 'package:open_vts/shared/widgets/open_vts/open_vts_status_chip.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class SettingsProfileEmailCard extends StatelessWidget {
  const SettingsProfileEmailCard({
    super.key,
    required this.email,
    required this.verified,
    required this.loading,
    required this.onVerify,
    required this.showActionWhenVerified,
    required this.actionLoading,
  });

  final String email;
  final bool verified;
  final bool loading;
  final Future<void> Function()? onVerify;
  final bool showActionWhenVerified;
  final bool actionLoading;

  @override
  Widget build(BuildContext context) {
    return SettingsProfileVerificationCard(
      icon: Icons.mail_outline,
      label: 'Email',
      value: email,
      verified: verified,
      loading: loading,
      onVerify: onVerify,
      showActionWhenVerified: showActionWhenVerified,
      actionLoading: actionLoading,
    );
  }
}

class SettingsProfilePhoneCard extends StatelessWidget {
  const SettingsProfilePhoneCard({
    super.key,
    required this.phone,
    required this.verified,
    required this.loading,
    required this.onVerify,
    required this.showActionWhenVerified,
    required this.actionLoading,
  });

  final String phone;
  final bool verified;
  final bool loading;
  final Future<void> Function()? onVerify;
  final bool showActionWhenVerified;
  final bool actionLoading;

  @override
  Widget build(BuildContext context) {
    return SettingsProfileVerificationCard(
      icon: Icons.phone_outlined,
      label: 'Phone',
      value: phone,
      verified: verified,
      loading: loading,
      onVerify: onVerify,
      showActionWhenVerified: showActionWhenVerified,
      actionLoading: actionLoading,
    );
  }
}

class SettingsProfileWhatsappCard extends StatelessWidget {
  const SettingsProfileWhatsappCard({
    super.key,
    required this.phone,
    required this.loading,
  });

  final String phone;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SettingsProfileVerificationCard(
      icon: Icons.chat_bubble_outline,
      label: 'WhatsApp',
      value: phone,
      verified: false,
      loading: loading,
      showBadge: false,
    );
  }
}

class SettingsProfileVerificationCard extends StatelessWidget {
  const SettingsProfileVerificationCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.verified,
    required this.loading,
    this.onVerify,
    this.showActionWhenVerified = false,
    this.actionLoading = false,
    this.showBadge = true,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool verified;
  final bool loading;
  final Future<void> Function()? onVerify;
  final bool showActionWhenVerified;
  final bool actionLoading;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final width = MediaQuery.of(context).size.width;
    final scale = (width / 420).clamp(0.9, 1.0);
    final labelSize = AdaptiveUtils.getTitleFontSize(width) + 1;
    final valueSize = AdaptiveUtils.getSubtitleFontSize(width) - 4;

    final validValue = value.trim().isNotEmpty && value.trim() != '-';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.onSurface.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 36 * scale,
            height: 36 * scale,
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? cs.surfaceContainerHighest
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 18 * scale, color: cs.onSurface),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppFonts.roboto(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.65),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loading ? '—' : value,
                  maxLines: 2,
                  overflow: TextOverflow.visible,
                  softWrap: true,
                  style: AppFonts.roboto(
                    fontSize: valueSize,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (!loading && showBadge)
            SettingsProfileVerificationBadge(
              verified: verified,
              onSendOtp: validValue ? onVerify : null,
              showActionWhenVerified: showActionWhenVerified,
              loading: actionLoading,
            ),
        ],
      ),
    );
  }
}

class SettingsProfileVerificationBadge extends StatefulWidget {
  const SettingsProfileVerificationBadge({
    super.key,
    required this.verified,
    required this.onSendOtp,
    required this.showActionWhenVerified,
    required this.loading,
  });

  final bool verified;
  final Future<void> Function()? onSendOtp;
  final bool showActionWhenVerified;
  final bool loading;

  @override
  State<SettingsProfileVerificationBadge> createState() =>
      _SettingsProfileVerificationBadgeState();
}

class _SettingsProfileVerificationBadgeState
    extends State<SettingsProfileVerificationBadge> {
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    final shouldShowAction = widget.showActionWhenVerified || !widget.verified;
    final isBusy = _sending || widget.loading;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        OpenVtsStatusChip(
          label: widget.verified ? 'Verified' : 'Unverified',
          tone: widget.verified
              ? OpenVtsStatusTone.success
              : OpenVtsStatusTone.danger,
          icon: widget.verified ? Icons.verified : Icons.error_outline,
          compact: true,
        ),
        if (shouldShowAction && widget.onSendOtp != null) ...[
          const SizedBox(height: 6),
          SizedBox(
            width: 96,
            child: OpenVtsButton(
              label: 'Verify',
              onPressed: isBusy
                  ? null
                  : () async {
                      updateLocalUiState(this, () => _sending = true);
                      try {
                        await widget.onSendOtp?.call();
                      } finally {
                        if (mounted) {
                          updateLocalUiState(this, () => _sending = false);
                        }
                      }
                    },
              loading: isBusy,
              size: OpenVtsButtonSize.small,
              expand: false,
            ),
          ),
        ],
      ],
    );
  }
}
