import 'package:flutter/material.dart';

import 'api_base_url_config.dart';

class ServerConfigurationSheet extends StatefulWidget {
  const ServerConfigurationSheet({super.key});

  @override
  State<ServerConfigurationSheet> createState() =>
      _ServerConfigurationSheetState();
}

class _ServerConfigurationSheetState extends State<ServerConfigurationSheet> {
  late final TextEditingController _urlController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _testing = false;
  String? _feedbackMessage;

  ApiBaseUrlConfig get _config => ApiBaseUrlConfig.instance;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: _config.effectiveBaseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  String? _validateUrl(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) {
      return 'API Base URL is required';
    }
    if (!(raw.startsWith('http://') || raw.startsWith('https://'))) {
      return 'URL must start with http:// or https://';
    }
    final normalized = _config.normalizeInput(raw);
    if (normalized == null) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  Future<void> _testConnection() async {
    final url = _urlController.text.trim();
    final error = _validateUrl(url);
    if (error != null) {
      setState(() => _feedbackMessage = error);
      return;
    }

    setState(() {
      _testing = true;
      _feedbackMessage = null;
    });

    final ok = await _config.testConnection(url);
    if (!mounted) return;

    setState(() {
      _testing = false;
      _feedbackMessage = ok
          ? 'Connection successful'
          : 'Unable to connect. Check the URL.';
    });
  }

  Future<void> _save() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    final normalized = _config.normalizeInput(_urlController.text);
    if (normalized == null) return;

    await _config.setCustomBaseUrl(normalized);
    if (!mounted) return;
    Navigator.of(context).pop<String>('saved');
  }

  Future<void> _reset() async {
    await _config.resetBaseUrl();
    if (!mounted) return;
    Navigator.of(context).pop<String>('reset');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: const Icon(Icons.dns_rounded, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Server Configuration',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Configure your company server URL',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                                color: scheme.onSurface.withValues(alpha: 0.66),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F4F6),
                          foregroundColor: scheme.onSurface,
                        ),
                        icon: const Icon(Icons.close_rounded, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'API Base URL',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _urlController,
                    validator: _validateUrl,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'https://yourcompany.com/api',
                      helperText: 'Example: https://yourcompany.com/api',
                      prefixIcon: const Icon(Icons.link_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: scheme.onSurface,
                          width: 1.2,
                        ),
                      ),
                    ),
                    onFieldSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current default',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _config.defaultBaseUrl,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.74,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_feedbackMessage != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          _feedbackMessage == 'Connection successful'
                              ? Icons.check_circle_rounded
                              : Icons.error_rounded,
                          size: 16,
                          color: _feedbackMessage == 'Connection successful'
                              ? Colors.green.shade700
                              : scheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _feedbackMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: _feedbackMessage == 'Connection successful'
                                  ? Colors.green.shade700
                                  : scheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _testing ? null : _testConnection,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(46),
                            side: const BorderSide(color: Color(0xFF111827)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _testing
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Test Connection'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        onPressed: _reset,
                        style: TextButton.styleFrom(
                          minimumSize: const Size(0, 46),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                        ),
                        child: const Text('Reset to Default'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
