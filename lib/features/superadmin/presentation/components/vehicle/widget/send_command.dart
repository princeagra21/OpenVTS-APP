import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/theme/app_fonts.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_vehicle.dart';
import 'package:open_vts/features/superadmin/presentation/controllers/superadmin_send_command_controller.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';
import 'package:open_vts/core/state/update_local_ui_state.dart';

class SendCommandsTab extends ConsumerStatefulWidget {
  const SendCommandsTab({
    super.key,
    this.imei,
    this.vehiclePlate = 'DL01 AB 1287',
    this.vehicleModel = 'GT06',
  });

  final String? imei;
  final String vehiclePlate;
  final String vehicleModel;

  @override
  ConsumerState<SendCommandsTab> createState() => _SendCommandsTabState();
}

class _SendCommandsTabState extends ConsumerState<SendCommandsTab> {
  final TextEditingController payload1Controller = TextEditingController();
  bool showJson = false;
  bool _missingImeiShown = false;

  final List<String> _fallbackCommandOptions = const <String>[
    'ping',
    'immobile',
    'mobilize',
    'Set Timezone',
    'Set Geofence',
    'Reboot device',
    'custom',
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      final imei = widget.imei?.trim() ?? '';
      if (imei.isEmpty) {
        if (kDebugMode && !_missingImeiShown && mounted) {
          _missingImeiShown = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('IMEI not available. Using fallback commands.')),
          );
        }
        return;
      }
      ref.read(superadminSendCommandControllerProvider.notifier).loadReferences(imei);
    });
  }

  @override
  void dispose() {
    payload1Controller.dispose();
    super.dispose();
  }

  List<String> _commandNames(SuperadminSendCommandState state) {
    if (state.commandOptions.isNotEmpty) {
      return state.commandOptions
          .map((e) => e.name.isNotEmpty ? e.name : e.code)
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }
    return _fallbackCommandOptions;
  }

  Map<String, Object?>? _parsePayload() {
    final rawPayload = payload1Controller.text.trim();
    if (rawPayload.isEmpty) return null;
    final parsed = jsonDecode(rawPayload);
    if (parsed is Map) {
      return <String, Object?>{
        for (final entry in parsed.entries) entry.key.toString(): entry.value,
      };
    }
    return <String, Object?>{'value': parsed};
  }

  Future<void> _onSendPressed(SuperadminSendCommandState state) async {
    final imei = widget.imei?.trim() ?? '';
    if (imei.isEmpty) {
      if (kDebugMode && !_missingImeiShown && mounted) {
        _missingImeiShown = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('IMEI missing. Cannot send command.')),
        );
      }
      return;
    }

    if (state.confirmBeforeSend) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Confirm Command'),
            content: const Text('Send this command to the vehicle?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Send'),
              ),
            ],
          );
        },
      );
      if (confirmed != true) return;
    }

    try {
      final payload = _parsePayload();
      final controller = ref.read(superadminSendCommandControllerProvider.notifier);
      controller.updatePayload(payload);
      await controller.sendCommand(imei);
    } on FormatException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid JSON payload')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final commandState = ref.watch(superadminSendCommandControllerProvider);
    final commandController = ref.read(superadminSendCommandControllerProvider.notifier);

    ref.listen<SuperadminSendCommandState>(superadminSendCommandControllerProvider, (previous, next) {
      final effect = next.effect;
      if (effect == null || previous?.effect == effect) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(effect.message)));
      commandController.clearEffect();
    });

    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final double titleFs = AdaptiveUtils.getTitleFontSize(width);
    final double bodyFs = titleFs - 1;
    final double smallFs = titleFs - 3;
    final commandNames = _commandNames(commandState);
    final selectedCommand = commandNames.contains(commandState.selectedCommand)
        ? commandState.selectedCommand
        : (commandNames.isNotEmpty ? commandNames.first : null);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Send Command',
            style: AppFonts.roboto(
              fontSize: titleFs + 2,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.vehiclePlate} • IMEI ${widget.imei?.isNotEmpty == true ? widget.imei : 'N/A'} • ${widget.vehicleModel}',
            style: AppFonts.roboto(
              fontSize: smallFs + 1,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            initialValue: selectedCommand,
            decoration: InputDecoration(
              labelText: 'Select Command',
              labelStyle: AppFonts.roboto(
                fontSize: bodyFs,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            style: AppFonts.roboto(fontSize: bodyFs, color: colorScheme.onSurface),
            dropdownColor: colorScheme.surface,
            items: commandNames.map((cmd) => DropdownMenuItem(value: cmd, child: Text(cmd))).toList(),
            onChanged: (val) => val != null ? commandController.selectCommand(val) : null,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: spacing + 4, vertical: spacing - 2),
                decoration: BoxDecoration(color: colorScheme.primary, borderRadius: BorderRadius.circular(10)),
                child: Text(
                  'Payload',
                  style: AppFonts.roboto(
                    fontSize: smallFs + 2,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: payload1Controller.text));
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payload copied')));
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: spacing + 8, vertical: spacing - 2),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy, size: 16, color: colorScheme.onSurface),
                      const SizedBox(width: 6),
                      Text(
                        'Copy',
                        style: AppFonts.roboto(
                          fontSize: smallFs + 2,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: payload1Controller,
            minLines: 3,
            maxLines: 5,
            style: AppFonts.roboto(fontSize: bodyFs, color: colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Enter payload here...',
              hintStyle: AppFonts.roboto(color: colorScheme.onSurface.withOpacity(0.6)),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => updateLocalUiState(this, () => showJson = !showJson),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  showJson ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  size: 18,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  'Request JSON',
                  style: AppFonts.roboto(fontSize: smallFs + 2, color: colorScheme.onSurface.withOpacity(0.8)),
                ),
              ],
            ),
          ),
          if (showJson) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
              child: Text(
                '{\n  "imei": "${widget.imei ?? "N/A"}",\n  "command": "${commandState.selectedCommand}",\n  "payload": ${payload1Controller.text.trim().isEmpty ? '{}' : payload1Controller.text.trim()}\n}',
                style: AppFonts.jetBrainsMono(fontSize: smallFs + 1, color: colorScheme.onSurface.withOpacity(0.9)),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: commandState.confirmBeforeSend,
                    activeColor: colorScheme.primary,
                    onChanged: (v) => v != null ? commandController.setConfirmBeforeSend(v) : null,
                  ),
                  Text(
                    'Confirm Before Send',
                    style: AppFonts.roboto(fontSize: bodyFs, color: colorScheme.onSurface),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: commandState.isSending ? null : () => _onSendPressed(commandState),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: commandState.isSending
                    ? const SizedBox(width: 18, height: 18, child: AppShimmer(width: 18, height: 18, radius: 9))
                    : Icon(Icons.send, size: 18, color: colorScheme.onPrimary),
                label: Text(
                  'Send',
                  style: AppFonts.roboto(
                    fontSize: bodyFs,
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Text(
                'Recent commands',
                style: AppFonts.roboto(
                  fontSize: titleFs,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 12,
                height: 12,
                child: commandState.isLoading ? const AppShimmer(width: 12, height: 12, radius: 6) : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
            child: commandState.recentCommands.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history, size: 36, color: colorScheme.onSurface.withOpacity(0.4)),
                        const SizedBox(height: 8),
                        Text(
                          'No recent commands',
                          style: AppFonts.roboto(fontSize: smallFs + 2, color: colorScheme.onSurface.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: commandState.recentCommands.length > 3 ? 3 : commandState.recentCommands.length,
                    itemBuilder: (context, index) {
                      final item = commandState.recentCommands[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          item.name.isNotEmpty ? item.name : 'Command',
                          style: AppFonts.roboto(fontSize: smallFs + 1),
                        ),
                        subtitle: Text(
                          item.createdAt.isNotEmpty ? item.createdAt : '—',
                          style: AppFonts.roboto(fontSize: smallFs, color: colorScheme.onSurface.withOpacity(0.6)),
                        ),
                        trailing: Text(
                          item.status.isNotEmpty ? item.status : 'sent',
                          style: AppFonts.roboto(fontSize: smallFs, color: colorScheme.onSurface.withOpacity(0.7)),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
