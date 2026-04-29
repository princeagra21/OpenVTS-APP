import 'package:fleet_stack/shared/components/custom_text_field.dart';
import 'package:flutter/material.dart';

class AddBufferScreen extends StatefulWidget {
  final bool isRadius;
  final String initialLabel;

  const AddBufferScreen({
    super.key,
    required this.isRadius,
    this.initialLabel = 'Geofence',
  });

  @override
  State<AddBufferScreen> createState() => _AddBufferScreenState();
}

class _AddBufferScreenState extends State<AddBufferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _valueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _labelController.text = widget.initialLabel;
  }

  @override
  void dispose() {
    _labelController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final title = widget.isRadius ? 'Add Radius' : 'Add Width';
    final hint = widget.isRadius ? 'Radius (meters)' : 'Width (meters)';

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: FractionallySizedBox(
          heightFactor: 0.62,
          child: Column(
            children: [
              const SizedBox(height: 8),
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.initialLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          CustomTextField(
                            controller: _labelController,
                            hintText: 'Label',
                            prefixIcon: Icons.label,
                            fontSize: 16,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a label';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _valueController,
                            hintText: hint,
                            prefixIcon: Icons.straighten,
                            keyboardType: TextInputType.number,
                            fontSize: 16,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a value';
                              }
                              final numVal = num.tryParse(value);
                              if (numVal == null || numVal <= 0) {
                                return 'Please enter a positive number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (!_formKey.currentState!.validate()) {
                                      return;
                                    }
                                    Navigator.pop(context, {
                                      'label': _labelController.text.trim(),
                                      'value': double.parse(
                                        _valueController.text.trim(),
                                      ),
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size.fromHeight(44),
                                    backgroundColor: cs.primary,
                                    foregroundColor: cs.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text('Save'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
