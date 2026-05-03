import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/white_label_branding.dart';
import 'package:fleet_stack/core/widgets/app_shimmer.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/repositories/white_label_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/superadmin/components/small_box/small_box.dart';
import 'package:fleet_stack/modules/superadmin/layout/app_layout.dart';
import 'package:fleet_stack/modules/superadmin/utils/adaptive_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BrandingSettingsScreen extends StatefulWidget {
  const BrandingSettingsScreen({super.key});

  @override
  State<BrandingSettingsScreen> createState() => _BrandingSettingsScreenState();
}

class _BrandingSettingsScreenState extends State<BrandingSettingsScreen> {
  // Postman-confirmed availability flags.
  static const bool _hasGetBrandingEndpoint =
      true; // GET /superadmin/whitelabel
  static const bool _hasSaveBrandingEndpoint =
      true; // PATCH /superadmin/whitelabel
  static const bool _hasUploadEndpoint = true; // POST /superadmin/upload/2

  final TextEditingController _baseUrlController = TextEditingController();

  WhiteLabelBranding? _branding;
  bool _loadingBranding = false;
  bool _saving = false;
  DateTime? _lastSaveAt;
  bool _loadErrorShown = false;
  bool _saveErrorShown = false;
  bool _uploadErrorShown = false;
  bool _saveApiUnavailableShown = false;

  bool _uploadingFavicon = false;
  bool _uploadingDarkLogo = false;
  bool _uploadingLightLogo = false;

  String _faviconUrl = '';
  String _darkLogoUrl = '';
  String _lightLogoUrl = '';

  Uint8List? _faviconBytes;
  Uint8List? _darkLogoBytes;
  Uint8List? _lightLogoBytes;

  CancelToken? _loadToken;
  CancelToken? _saveToken;
  CancelToken? _uploadToken;

  ApiClient? _api;
  WhiteLabelRepository? _repo;

  @override
  void initState() {
    super.initState();
    _loadBranding();
  }

  @override
  void dispose() {
    _loadToken?.cancel('BrandingSettings disposed');
    _saveToken?.cancel('BrandingSettings disposed');
    _uploadToken?.cancel('BrandingSettings disposed');
    _baseUrlController.dispose();
    super.dispose();
  }

  WhiteLabelRepository _repoOrCreate() {
    _api ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= WhiteLabelRepository(api: _api!);
    return _repo!;
  }

  Future<void> _loadBranding() async {
    if (!_hasGetBrandingEndpoint) {
      if (kDebugMode) {
        debugPrint('Branding GET endpoint not available');
      }
      return;
    }

    _loadToken?.cancel('Reload branding');
    final token = CancelToken();
    _loadToken = token;

    if (!mounted) return;
    setState(() => _loadingBranding = true);

    try {
      final res = await _repoOrCreate().getWhiteLabelBranding(
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (data) {
          setState(() {
            _branding = data;
            _loadingBranding = false;
            _loadErrorShown = false;
            _baseUrlController.text = data.baseUrl.trim();
            _faviconUrl = data.faviconUrl;
            _darkLogoUrl = data.darkLogoUrl;
            _lightLogoUrl = data.lightLogoUrl;
          });
        },
        failure: (err) {
          setState(() => _loadingBranding = false);
          if (_loadErrorShown) return;
          _loadErrorShown = true;
          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to view white label settings.'
              : "Couldn't load white label settings.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingBranding = false);
      if (_loadErrorShown) return;
      _loadErrorShown = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't load white label settings.")),
      );
    }
  }

  Future<void> _saveBranding() async {
    if (_saving) return;
    final now = DateTime.now();
    final last = _lastSaveAt;
    if (last != null && now.difference(last).inMilliseconds < 800) return;
    _lastSaveAt = now;

    final normalizedDomain = _baseUrlController.text
        .trim()
        .replaceFirst(RegExp(r'^https?://', caseSensitive: false), '')
        .replaceFirst(RegExp(r'/+$'), '');
    final customDomain = normalizedDomain;

    if (!_hasSaveBrandingEndpoint) {
      if (kDebugMode && !_saveApiUnavailableShown) {
        _saveApiUnavailableShown = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Save API not available yet')),
        );
      }
      return;
    }

    _saveToken?.cancel('Retry save branding');
    final token = CancelToken();
    _saveToken = token;

    if (!mounted) return;
    setState(() {
      _saving = true;
      _saveErrorShown = false;
    });

    try {
      final res = await _repoOrCreate().updateWhiteLabelBranding(
        customDomain: customDomain.isEmpty ? '' : customDomain,
        primaryColor: 'BLACK',
        faviconUrl: _faviconUrl,
        logoDarkUrl: _darkLogoUrl,
        logoLightUrl: _lightLogoUrl,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (data) {
          setState(() {
            _saving = false;
            _branding = data;
            if (data.baseUrl.trim().isNotEmpty) {
              _baseUrlController.text = data.baseUrl;
            }
            if (data.faviconUrl.trim().isNotEmpty) {
              _faviconUrl = data.faviconUrl;
            }
            if (data.darkLogoUrl.trim().isNotEmpty) {
              _darkLogoUrl = data.darkLogoUrl;
            }
            if (data.lightLogoUrl.trim().isNotEmpty) {
              _lightLogoUrl = data.lightLogoUrl;
            }
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Saved')));
        },
        failure: (err) {
          setState(() => _saving = false);
          if (_saveErrorShown) return;
          _saveErrorShown = true;
          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to save white label settings.'
              : "Couldn't save changes.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      if (_saveErrorShown) return;
      _saveErrorShown = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't save changes.")));
    }
  }

  Future<void> _pickAndUploadAsset(String type) async {
    if (!_hasUploadEndpoint) {
      if (kDebugMode && !_uploadErrorShown) {
        _uploadErrorShown = true;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Upload API not available yet')),
        );
      }
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'ico'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) return;

    if (!mounted) return;
    setState(() {
      _uploadErrorShown = false;
      if (type == 'FAVICON') {
        _uploadingFavicon = true;
        _faviconBytes = bytes;
      } else if (type == 'DARKLOGO') {
        _uploadingDarkLogo = true;
        _darkLogoBytes = bytes;
      } else if (type == 'LIGHTLOGO') {
        _uploadingLightLogo = true;
        _lightLogoBytes = bytes;
      }
    });

    _uploadToken?.cancel('Retry upload');
    final token = CancelToken();
    _uploadToken = token;

    try {
      final res = await _repoOrCreate().uploadBrandAsset(
        type: type,
        bytes: bytes,
        filename: file.name,
        cancelToken: token,
      );
      if (!mounted) return;

      res.when(
        success: (url) {
          setState(() {
            if (type == 'FAVICON') {
              _uploadingFavicon = false;
              if (url.trim().isNotEmpty) _faviconUrl = url;
            } else if (type == 'DARKLOGO') {
              _uploadingDarkLogo = false;
              if (url.trim().isNotEmpty) _darkLogoUrl = url;
            } else if (type == 'LIGHTLOGO') {
              _uploadingLightLogo = false;
              if (url.trim().isNotEmpty) _lightLogoUrl = url;
            }
          });
        },
        failure: (err) {
          setState(() {
            if (type == 'FAVICON') {
              _uploadingFavicon = false;
            } else if (type == 'DARKLOGO') {
              _uploadingDarkLogo = false;
            } else if (type == 'LIGHTLOGO') {
              _uploadingLightLogo = false;
            }
          });
          if (_uploadErrorShown) return;
          _uploadErrorShown = true;
          final msg =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to upload brand assets.'
              : "Couldn't upload file.";
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        if (type == 'FAVICON') {
          _uploadingFavicon = false;
        } else if (type == 'DARKLOGO') {
          _uploadingDarkLogo = false;
        } else if (type == 'LIGHTLOGO') {
          _uploadingLightLogo = false;
        }
      });
      if (_uploadErrorShown) return;
      _uploadErrorShown = true;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Couldn't upload file.")));
    }
  }

  void _clearAsset(String type) {
    if (!mounted) return;
    setState(() {
      if (type == 'FAVICON') {
        _faviconUrl = '';
        _faviconBytes = null;
      } else if (type == 'DARKLOGO') {
        _darkLogoUrl = '';
        _darkLogoBytes = null;
      } else if (type == 'LIGHTLOGO') {
        _lightLogoUrl = '';
        _lightLogoBytes = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width) - 2;

    return AppLayout(
      title: "Open VTS",
      subtitle: "White Label",
      actionIcons: const [],
      leftAvatarText: 'FS',
      showLeftAvatar: false,
      horizontalPadding: 3,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(hp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BrandingSettingsBox(
              baseUrlController: _baseUrlController,
              loadingBranding: _loadingBranding,
              saving: _saving,
              serverIp: _branding?.serverIp ?? '',
              faviconUrl: _faviconUrl,
              darkLogoUrl: _darkLogoUrl,
              lightLogoUrl: _lightLogoUrl,
              faviconBytes: _faviconBytes,
              darkLogoBytes: _darkLogoBytes,
              lightLogoBytes: _lightLogoBytes,
              uploadingFavicon: _uploadingFavicon,
              uploadingDarkLogo: _uploadingDarkLogo,
              uploadingLightLogo: _uploadingLightLogo,
              onSave: _saveBranding,
              onUploadFavicon: () => _pickAndUploadAsset('FAVICON'),
              onUploadDarkLogo: () => _pickAndUploadAsset('DARKLOGO'),
              onUploadLightLogo: () => _pickAndUploadAsset('LIGHTLOGO'),
              onClearFavicon: () => _clearAsset('FAVICON'),
              onClearDarkLogo: () => _clearAsset('DARKLOGO'),
              onClearLightLogo: () => _clearAsset('LIGHTLOGO'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _BrandingSettingsBox extends StatelessWidget {
  final TextEditingController baseUrlController;
  final bool loadingBranding;
  final bool saving;
  final String serverIp;
  final String faviconUrl;
  final String darkLogoUrl;
  final String lightLogoUrl;
  final Uint8List? faviconBytes;
  final Uint8List? darkLogoBytes;
  final Uint8List? lightLogoBytes;
  final bool uploadingFavicon;
  final bool uploadingDarkLogo;
  final bool uploadingLightLogo;
  final VoidCallback onSave;
  final VoidCallback onUploadFavicon;
  final VoidCallback onUploadDarkLogo;
  final VoidCallback onUploadLightLogo;
  final VoidCallback onClearFavicon;
  final VoidCallback onClearDarkLogo;
  final VoidCallback onClearLightLogo;

  const _BrandingSettingsBox({
    required this.baseUrlController,
    required this.loadingBranding,
    required this.saving,
    required this.serverIp,
    required this.faviconUrl,
    required this.darkLogoUrl,
    required this.lightLogoUrl,
    required this.faviconBytes,
    required this.darkLogoBytes,
    required this.lightLogoBytes,
    required this.uploadingFavicon,
    required this.uploadingDarkLogo,
    required this.uploadingLightLogo,
    required this.onSave,
    required this.onUploadFavicon,
    required this.onUploadDarkLogo,
    required this.onUploadLightLogo,
    required this.onClearFavicon,
    required this.onClearDarkLogo,
    required this.onClearLightLogo,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;
    final double hp = AdaptiveUtils.getHorizontalPadding(width);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(hp),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "White Label",
                    style: GoogleFonts.roboto(
                      fontSize: AdaptiveUtils.getTitleFontSize(width),
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface.withOpacity(0.87),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        "Branding Settings",
                        style: GoogleFonts.roboto(
                          fontSize:
                              AdaptiveUtils.getSubtitleFontSize(width) - 3,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface.withOpacity(0.9),
                        ),
                      ),
                      if (loadingBranding) ...[
                        const SizedBox(width: 8),
                        const AppShimmer(width: 12, height: 12, radius: 6),
                      ],
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: saving ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  padding: EdgeInsets.symmetric(
                    horizontal: hp + 2,
                    vertical: hp - 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: SizedBox(
                  width: AdaptiveUtils.getIconSize(width),
                  height: AdaptiveUtils.getIconSize(width),
                  child: saving
                      ? AppShimmer(
                          width: AdaptiveUtils.getIconSize(width),
                          height: AdaptiveUtils.getIconSize(width),
                          radius: AdaptiveUtils.getIconSize(width) / 2,
                        )
                      : Icon(
                          Icons.save_outlined,
                          color: colorScheme.onPrimary,
                          size: AdaptiveUtils.getIconSize(width),
                        ),
                ),
                label: Text(
                  "Save Changes",
                  style: GoogleFonts.roboto(
                    fontSize: AdaptiveUtils.getTitleFontSize(width) - 2,
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: hp * 2),
          _buildSection(
            context: context,
            icon: Icons.language,
            title: "Base URL Configuration",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Base URL",
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                if (loadingBranding && baseUrlController.text.trim().isEmpty)
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppShimmer(
                        width: double.infinity,
                        height: 44,
                        radius: 12,
                      ),
                      SizedBox(height: 6),
                      AppShimmer(width: 250, height: 12, radius: 8),
                    ],
                  )
                else ...[
                  TextField(
                    controller: baseUrlController,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.transparent,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 12,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    style: GoogleFonts.roboto(color: colorScheme.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Enter your custom domain without http:// or https://",
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: colorScheme.onSurface.withOpacity(0.54),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSection(
            context: context,
            icon: Icons.storage,
            title: "Server Information",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (loadingBranding && serverIp.trim().isEmpty)
                  const AppShimmer(width: 220, height: 30, radius: 12)
                else
                  Row(
                    children: [
                      Text(
                        "Server IP:",
                        style: GoogleFonts.roboto(
                          fontSize:
                              AdaptiveUtils.getSubtitleFontSize(width) - 6,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface.withOpacity(0.87),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SmallTab(
                        label: serverIp.trim().isEmpty ? '-' : serverIp.trim(),
                        selected: false,
                        onTap: () {},
                      ),
                    ],
                  ),
                const SizedBox(height: 8),
                Text(
                  serverIp.trim().isEmpty
                      ? "Server IP not provided by API."
                      : "Use this IP address for DNS configuration",
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    color: colorScheme.onSurface.withOpacity(0.54),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 13),
          Divider(color: colorScheme.onSurface.withOpacity(0.2)),
          const SizedBox(height: 13),
          _buildSection(
            context: context,
            icon: Icons.image,
            title: "Favicon & Logos",
            child: Column(
              children: [
                _buildSingleUploadContainer(
                  context: context,
                  width: width,
                  loadingBranding: loadingBranding,
                  title: "Favicon",
                  smallTabLabel: "16×16 or 32×32 px",
                  previewUrl: faviconUrl,
                  previewBytes: faviconBytes,
                  uploading: uploadingFavicon,
                  onUpload: onUploadFavicon,
                  onClear: onClearFavicon,
                ),
                const SizedBox(height: 16),
                _buildSingleUploadContainer(
                  context: context,
                  width: width,
                  loadingBranding: loadingBranding,
                  title: "Dark Logo",
                  smallTabLabel: "For light backgrounds",
                  previewUrl: darkLogoUrl,
                  previewBytes: darkLogoBytes,
                  uploading: uploadingDarkLogo,
                  onUpload: onUploadDarkLogo,
                  onClear: onClearDarkLogo,
                ),
                const SizedBox(height: 16),
                _buildSingleUploadContainer(
                  context: context,
                  width: width,
                  loadingBranding: loadingBranding,
                  title: "Light Logo",
                  smallTabLabel: "For dark backgrounds",
                  previewUrl: lightLogoUrl,
                  previewBytes: lightLogoBytes,
                  uploading: uploadingLightLogo,
                  onUpload: onUploadLightLogo,
                  onClear: onClearLightLogo,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double width = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface.withOpacity(0.9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildSingleUploadContainer({
    required BuildContext context,
    required double width,
    required bool loadingBranding,
    required String title,
    required String smallTabLabel,
    required String previewUrl,
    required Uint8List? previewBytes,
    required bool uploading,
    required VoidCallback onUpload,
    required VoidCallback onClear,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final double boxHeight = width < 500 ? 85 : 110;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: AdaptiveUtils.getSubtitleFontSize(width) - 5,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface.withOpacity(0.87),
                ),
              ),
              const SizedBox(width: 12),
              if (loadingBranding)
                const AppShimmer(width: 130, height: 28, radius: 12)
              else
                SmallTab(label: smallTabLabel, selected: false, onTap: () {}),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: loadingBranding
                    ? AppShimmer(
                        width: double.infinity,
                        height: boxHeight,
                        radius: 12,
                      )
                    : InkWell(
                        onTap: uploading ? null : onUpload,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: boxHeight,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.5),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: uploading
                                ? const AppShimmer(
                                    width: 12,
                                    height: 12,
                                    radius: 6,
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.upload_file,
                                        size: 26,
                                        color: colorScheme.onSurface
                                            .withOpacity(0.54),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Click to upload\nICO, PNG (max 2MB)",
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.roboto(
                                          fontSize:
                                              AdaptiveUtils.getSubtitleFontSize(
                                                width,
                                              ) -
                                              6,
                                          color: colorScheme.onSurface
                                              .withOpacity(0.54),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Stack(
                  children: [
                    if (loadingBranding)
                      AppShimmer(
                        width: double.infinity,
                        height: boxHeight,
                        radius: 12,
                      )
                    else
                      Container(
                        height: boxHeight,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: colorScheme.surfaceVariant,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: previewBytes != null
                              ? Image.memory(
                                  previewBytes,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: double.infinity,
                                )
                              : (previewUrl.trim().isNotEmpty
                                    ? Image.network(
                                        previewUrl,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        height: double.infinity,
                                        errorBuilder: (_, __, ___) => Center(
                                          child: Text(
                                            "Preview",
                                            style: GoogleFonts.roboto(
                                              fontSize: 12,
                                              color: colorScheme.onSurface
                                                  .withOpacity(0.54),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Center(
                                        child: Text(
                                          "Preview",
                                          style: GoogleFonts.roboto(
                                            fontSize: 12,
                                            color: colorScheme.onSurface
                                                .withOpacity(0.54),
                                          ),
                                        ),
                                      )),
                        ),
                      ),
                    if (!loadingBranding)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: onClear,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 14,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
