import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/shared/components/custom_dropdown_field.dart';
import 'package:fleet_stack/shared/components/custom_text_field.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ShareTrackAddScreen extends StatefulWidget {
  const ShareTrackAddScreen({super.key});

  @override
  State<ShareTrackAddScreen> createState() => _ShareTrackAddScreenState();
}

class _ShareTrackAddScreenState extends State<ShareTrackAddScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _linkNameController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _previewUrlController = TextEditingController(text: 'trk.fleet.link/preview-link'); // Placeholder
  final TextEditingController _customDurationController = TextEditingController();

  String? selectedDuration;
  final List<String> durations = ["1h", "3h", "6h", "12h", "24h", "7days", "Custom"];

  bool geofence = false;
  bool history24h = false;
  bool driverInfo = false;
  bool sensors = false;

  final List<String> availableVehicles = [
    "UP80AA1234", "UP80BB4567", "DL01C7788", "MH12Q9090",
    "HR26D3344", "GJ01M6666", "RJ14P2211", "TN99Z0000"
  ];
  List<String> selectedVehicles = [];

  @override
  void initState() {
    super.initState();
    _linkNameController.addListener(_updatePreviewUrl);
  }

  void _updatePreviewUrl() {
    final name = _linkNameController.text.toLowerCase().replaceAll(' ', '-');
    setState(() {
      _previewUrlController.text = name.isEmpty ? 'trk.fleet.link/preview-link' : 'trk.fleet.link/$name';
    });
  }

  @override
  void dispose() {
    _linkNameController.dispose();
    _pinController.dispose();
    _previewUrlController.dispose();
    _customDurationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final double w = MediaQuery.of(context).size.width;
    final double padding = AdaptiveUtils.getHorizontalPadding(w);
    final double fs = AdaptiveUtils.getTitleFontSize(w);

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(padding * 1.3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── HEADER ─────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Add Share Track",
                    style: GoogleFonts.inter(
                      fontSize: AdaptiveUtils.getSubtitleFontSize(w),
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  )
                ],
              ),
              const SizedBox(height: 24),

              // ─── FORM ───────────────────────────────
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // VEHICLE SELECT DROPDOWN (MULTI)
                        CustomMultiDropdownField<String>(
                          value: selectedVehicles,
                          items: availableVehicles,
                          hintText: "Select vehicles",
                          prefixIcon: Icons.directions_car,
                          onChanged: (v) => setState(() => selectedVehicles = v),
                          fontSize: fs,
                        ),
                        const SizedBox(height: 16),

                        // LINK NAME
                        CustomTextField(
                          controller: _linkNameController,
                          hintText: "Enter link name",
                          prefixIcon: Icons.link,
                          fontSize: fs,
                        ),
                        const SizedBox(height: 16),

                        // DURATION DROPDOWN
                        CustomDropdownField<String>(
                          value: selectedDuration,
                          items: durations,
                          hintText: "Select duration",
                          prefixIcon: Icons.timer,
                          onChanged: (v) => setState(() => selectedDuration = v),
                          fontSize: fs,
                        ),
                        if (selectedDuration == "Custom") ...[
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _customDurationController,
                            hintText: "Enter custom hours (e.g., 48)",
                            prefixIcon: Icons.hourglass_bottom,
                            keyboardType: TextInputType.number,
                            fontSize: fs,
                          ),
                        ],
                        const SizedBox(height: 16),

                        // PREVIEW URL (non-editable)
                        IgnorePointer(
                          child: TextField(
                            controller: _previewUrlController,
                            enabled: false,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.preview, color: cs.primary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            style: GoogleFonts.inter(fontSize: fs),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // PERMISSIONS TOGGLES
                        Text(
                          "Permissions",
                          style: GoogleFonts.inter(fontSize: fs, fontWeight: FontWeight.bold),
                        ),
                        SwitchListTile(
                          title: Text("Geofence", style: GoogleFonts.inter(fontSize: fs)),
                          value: geofence,
                          onChanged: (v) => setState(() => geofence = v),
                        ),
                        SwitchListTile(
                          title: Text("History last 24 hours", style: GoogleFonts.inter(fontSize: fs)),
                          value: history24h,
                          onChanged: (v) => setState(() => history24h = v),
                        ),
                        SwitchListTile(
                          title: Text("Driver info", style: GoogleFonts.inter(fontSize: fs)),
                          value: driverInfo,
                          onChanged: (v) => setState(() => driverInfo = v),
                        ),
                        SwitchListTile(
                          title: Text("Sensors", style: GoogleFonts.inter(fontSize: fs)),
                          value: sensors,
                          onChanged: (v) => setState(() => sensors = v),
                        ),
                        const SizedBox(height: 16),

                        // SECURITY PIN
                        CustomTextField(
                          controller: _pinController,
                          hintText: "PIN (optional)",
                          prefixIcon: Icons.lock,
                          fontSize: fs,
                          isPassword: true, // Assuming PIN is sensitive
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Recipients must enter this PIN to open",
                          style: GoogleFonts.inter(fontSize: fs - 2, color: cs.onSurface.withOpacity(0.6)),
                        ),
                        const SizedBox(height: 24),

                        // WARNING TEXT
                        Text(
                          "Links auto-expire and can be revoked anytime.",
                          style: GoogleFonts.inter(fontSize: fs - 1, color: Colors.red),
                        ),
                        const SizedBox(height: 32),

                        // ─── ACTION BUTTONS ─────────────────
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    side: BorderSide(color: cs.primary.withOpacity(0.2)),
                                  ),
                                ),
                                child: Text(
                                  "Cancel",
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_formKey.currentState!.validate()) {
                                    // SUBMIT LOGIC: Create track with selected values
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(36),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                child: Text(
                                  "Create",
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomMultiDropdownField<T> extends StatelessWidget {
  final List<T> value;
  final List<T> items;
  final String hintText;
  final IconData? prefixIcon;
  final Function(List<T>) onChanged;
  final double fontSize;
  final String Function(T)? itemLabelBuilder;

  const CustomMultiDropdownField({
    super.key,
    required this.value,
    required this.items,
    required this.hintText,
    this.prefixIcon,
    required this.onChanged,
    required this.fontSize,
    this.itemLabelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayText = value.isEmpty ? hintText : 'Selected (${value.length}) vehicles';

    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) {
            List<T> tempSelected = List.from(value);
            return AlertDialog(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 20.0), // Reduced horizontal padding
              titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
              actionsPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              title: Text(hintText),
              content: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.5, // Limit height to support scrolling
                  maxWidth: MediaQuery.of(ctx).size.width * 0.9,
                ),
                child: SingleChildScrollView(
                  child: StatefulBuilder(
                    builder: (context, dialogSetState) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: items.map((item) {
                        return CheckboxListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4.0), // Further reduce inner padding if needed
                          title: Text(
                            itemLabelBuilder != null ? itemLabelBuilder!(item) : item.toString(),
                            style: GoogleFonts.inter(fontSize: fontSize),
                          ),
                          value: tempSelected.contains(item),
                          onChanged: (bool? checked) {
                            dialogSetState(() {
                              if (checked == true) {
                                tempSelected.add(item);
                              } else {
                                tempSelected.remove(item);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    onChanged(tempSelected);
                    Navigator.pop(ctx);
                  },
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            if (prefixIcon != null) ...[
              Icon(prefixIcon, color: colorScheme.primary, size: 22),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                displayText,
                style: GoogleFonts.inter(
                  fontSize: fontSize,
                  color: value.isEmpty ? colorScheme.onSurface.withOpacity(0.5) : colorScheme.onSurface,
                ),
              ),
            ),
            Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.primary),
          ],
        ),
      ),
    );
  }
}