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
    final normalized = _config.normalizeInput(value);
    if (normalized == null) {
      return 'Enter a valid http(s) URL';
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
      child: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: scheme.onSurface.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(100),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Server Configuration',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure your company server URL',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _urlController,
                    validator: _validateUrl,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: 'API Base URL',
                      hintText: 'https://yourcompany.com/api',
                      helperText: 'Example: https://yourcompany.com/api',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onFieldSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Current default: ${_config.defaultBaseUrl}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface.withValues(alpha: 0.65),
                    ),
                  ),
                  if (_feedbackMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _feedbackMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _feedbackMessage == 'Connection successful'
                            ? scheme.primary
                            : scheme.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _testing ? null : _testConnection,
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
                      Expanded(
                        child: TextButton(
                          onPressed: _reset,
                          child: const Text('Reset to Default'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _save,
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
