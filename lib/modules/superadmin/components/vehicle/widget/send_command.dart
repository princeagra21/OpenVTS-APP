// components/vehicle/send_commands_tab.dart
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/command_option.dart';
import 'package:fleet_stack/core/models/sent_command_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/superadmin_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class SendCommandsTab extends StatefulWidget {
  final String? imei;
  final String vehiclePlate;
  final String vehicleModel;

  const SendCommandsTab({
    super.key,
    this.imei,
    this.vehiclePlate = "DL01 AB 1287",
    this.vehicleModel = "GT06",
  });

  @override
  State<SendCommandsTab> createState() => _SendCommandsTabState();
}

class _SendCommandsTabState extends State<SendCommandsTab> {
  String selectedCommand = "Set Geofence";
  final TextEditingController payload1Controller = TextEditingController();
  bool showJson = false;
  bool confirmBeforeSend = false;
  bool _loadingRefs = false;
  bool _sending = false;
  bool _fetchErrorShown = false;
  bool _missingImeiShown = false;

  final List<String> _fallbackCommandOptions = const [
    "ping",
    "immobile",
    "mobilize",
    "Set Timezone",
    "Set Geofence",
    "Reboot device",
    "custom",
  ];
  List<CommandOption> _commandOptions = const [];
  List<SentCommandItem> _recentCommands = const [];

  CancelToken? _fetchToken;
  CancelToken? _sendToken;
  ApiClient? _api;
  SuperadminRepository? _repo;

  @override
  void initState() {
    super.initState();
    _loadCommandReferences();
  }

  @override
  void dispose() {
    _fetchToken?.cancel('SendCommandsTab fetch disposed');
    _sendToken?.cancel('SendCommandsTab send disposed');
    payload1Controller.dispose();
    super.dispose();
  }

  List<String> get _commandNames {
    if (_commandOptions.isNotEmpty) {
      return _commandOptions
          .map((e) => e.name.isNotEmpty ? e.name : e.code)
          .where((e) => e.trim().isNotEmpty)
          .toList();
    }
    return _fallbackCommandOptions;
  }

  CommandOption? get _selectedOption {
    for (final option in _commandOptions) {
      final name = option.name.isNotEmpty ? option.name : option.code;
      if (name == selectedCommand) return option;
    }
    return null;
  }

  Future<void> _loadCommandReferences() async {
    final imei = widget.imei?.trim() ?? '';
    if (imei.isEmpty) {
      if (kDebugMode && !_missingImeiShown && mounted) {
        _missingImeiShown = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('IMEI not available. Using fallback commands.'),
          ),
        );
      }
      return;
    }

    _fetchToken?.cancel('Reload command references');
    final token = CancelToken();
    _fetchToken = token;

    if (!mounted) return;
    setState(() => _loadingRefs = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final optionsRes = await _repo!.getCommandOptions(
        imei,
        cancelToken: token,
      );
      if (!mounted) return;

      List<CommandOption> nextOptions = const [];
      bool hadFailure = false;
      optionsRes.when(
        success: (items) => nextOptions = items,
        failure: (_) => hadFailure = true,
      );

      final recentRes = await _repo!.getRecentCommands(
        imei,
        cancelToken: token,
      );
      if (!mounted) return;

      List<SentCommandItem> nextRecent = const [];
      recentRes.when(
        success: (items) => nextRecent = items,
        failure: (_) => hadFailure = true,
      );

      setState(() {
        _loadingRefs = false;
        _commandOptions = nextOptions;
        _recentCommands = nextRecent;
        _fetchErrorShown = false;
        if (!_commandNames.contains(selectedCommand)) {
          selectedCommand = _commandNames.isNotEmpty
              ? _commandNames.first
              : selectedCommand;
        }
      });
      if (hadFailure && !_fetchErrorShown) {
        _fetchErrorShown = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Couldn't load some command data. Using fallback."),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingRefs = false);
      if (_fetchErrorShown) return;
      _fetchErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Couldn't load commands. Using fallback."),
        ),
      );
    }
  }

  Future<void> _onSendPressed() async {
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

    if (confirmBeforeSend) {
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

    _sendToken?.cancel('Previous send command');
    final token = CancelToken();
    _sendToken = token;

    if (!mounted) return;
    setState(() => _sending = true);

    try {
      _api ??= ApiClient(
        config: AppConfig.fromDartDefine(),
        tokenStorage: TokenStorage.defaultInstance(),
      );
      _repo ??= SuperadminRepository(api: _api!);

      final code = _selectedOption?.code.isNotEmpty == true
          ? _selectedOption!.code
          : selectedCommand;

      Map<String, dynamic>? payload;
      final rawPayload = payload1Controller.text.trim();
      if (rawPayload.isNotEmpty) {
        final parsed = jsonDecode(rawPayload);
        if (parsed is Map<String, dynamic>) {
          payload = parsed;
        } else if (parsed is Map) {
          payload = Map<String, dynamic>.from(parsed.cast());
        } else {
          payload = <String, dynamic>{'value': parsed};
        }
      }

      final res = await _repo!.sendCommand(
        imei,
        code,
        payload,
        confirmBeforeSend,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (_) {
          if (!mounted) return;
          setState(() {
            _sending = false;
            _recentCommands = [
              SentCommandItem({
                'name': selectedCommand,
                'status': 'sent',
                'createdAt': DateTime.now().toIso8601String(),
              }),
              ..._recentCommands,
            ];
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Command sent')));
        },
        failure: (err) {
          if (!mounted) return;
          setState(() => _sending = false);
          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to send command.'
              : "Couldn't send command.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } on FormatException {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Invalid JSON payload')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't send command.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);
    final double spacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final double titleFs = AdaptiveUtils.getTitleFontSize(width);
    final double bodyFs = titleFs - 1;
    final double smallFs = titleFs - 3;

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
            "Send Command",
            style: GoogleFonts.roboto(
              fontSize: titleFs + 2,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "${widget.vehiclePlate} • IMEI ${widget.imei?.isNotEmpty == true ? widget.imei : 'N/A'} • ${widget.vehicleModel}",
            style: GoogleFonts.roboto(
              fontSize: smallFs + 1,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<String>(
            value: _commandNames.contains(selectedCommand)
                ? selectedCommand
                : (_commandNames.isNotEmpty ? _commandNames.first : null),
            decoration: InputDecoration(
              labelText: "Select Command",
              labelStyle: GoogleFonts.roboto(
                fontSize: bodyFs,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
              filled: true,
              fillColor: colorScheme.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: colorScheme.outline.withOpacity(0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            style: GoogleFonts.roboto(
              fontSize: bodyFs,
              color: colorScheme.onSurface,
            ),
            dropdownColor: colorScheme.surface,
            items: _commandNames
                .map((cmd) => DropdownMenuItem(value: cmd, child: Text(cmd)))
                .toList(),
            onChanged: (val) =>
                val != null ? setState(() => selectedCommand = val) : null,
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: spacing + 4,
                  vertical: spacing - 2,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  "Payload",
                  style: GoogleFonts.roboto(
                    fontSize: smallFs + 2,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(text: payload1Controller.text),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Payload copied")),
                  );
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: spacing + 8,
                    vertical: spacing - 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy, size: 16, color: colorScheme.onSurface),
                      const SizedBox(width: 6),
                      Text(
                        "Copy",
                        style: GoogleFonts.roboto(
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
            style: GoogleFonts.roboto(
              fontSize: bodyFs,
              color: colorScheme.onSurface,
            ),
            decoration: InputDecoration(
              hintText: "Enter payload here...",
              hintStyle: GoogleFonts.roboto(
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              filled: true,
              fillColor: colorScheme.surfaceVariant,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: colorScheme.outline.withOpacity(0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: colorScheme.primary, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => setState(() => showJson = !showJson),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  showJson
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  size: 18,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
                const SizedBox(width: 6),
                Text(
                  "Request JSON",
                  style: GoogleFonts.roboto(
                    fontSize: smallFs + 2,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          if (showJson) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '{\n  "imei": "${widget.imei ?? "N/A"}",\n  "command": "$selectedCommand",\n  "payload": {}\n}',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: smallFs + 1,
                  color: colorScheme.onSurface.withOpacity(0.9),
                ),
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
                    value: confirmBeforeSend,
                    activeColor: colorScheme.primary,
                    onChanged: (v) => v != null
                        ? setState(() => confirmBeforeSend = v)
                        : null,
                  ),
                  Text(
                    "Confirm Before Send",
                    style: GoogleFonts.roboto(
                      fontSize: bodyFs,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _sending ? null : _onSendPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _sending
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: const AppShimmer(
                          width: 18,
                          height: 18,
                          radius: 9,
                        ),
                      )
                    : Icon(Icons.send, size: 18, color: colorScheme.onPrimary),
                label: Text(
                  "Send",
                  style: GoogleFonts.roboto(
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
                "Recent commands",
                style: GoogleFonts.roboto(
                  fontSize: titleFs,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 12,
                height: 12,
                child: _loadingRefs
                    ? const AppShimmer(width: 12, height: 12, radius: 6)
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 120,
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _recentCommands.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history,
                          size: 36,
                          color: colorScheme.onSurface.withOpacity(0.4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "No recent commands",
                          style: GoogleFonts.roboto(
                            fontSize: smallFs + 2,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _recentCommands.length > 3
                        ? 3
                        : _recentCommands.length,
                    itemBuilder: (context, index) {
                      final item = _recentCommands[index];
                      return ListTile(
                        dense: true,
                        title: Text(
                          item.name.isNotEmpty ? item.name : 'Command',
                          style: GoogleFonts.roboto(fontSize: smallFs + 1),
                        ),
                        subtitle: Text(
                          item.createdAt.isNotEmpty ? item.createdAt : '—',
                          style: GoogleFonts.roboto(
                            fontSize: smallFs,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        trailing: Text(
                          item.status.isNotEmpty ? item.status : 'sent',
                          style: GoogleFonts.roboto(
                            fontSize: smallFs,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
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
