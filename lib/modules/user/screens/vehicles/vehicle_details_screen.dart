import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_vts/core/models/vehicle_list_item.dart';
import 'package:open_vts/core/network/api_client.dart';
import 'package:open_vts/core/network/api_client_provider.dart';
import 'package:open_vts/design_system/theme/open_vts_theme.dart';
import 'package:open_vts/core/utils/adaptive_utils.dart';
import 'package:open_vts/core/utils/app_utils.dart';
import 'package:open_vts/core/repositories/user_vehicles_repository.dart';
import 'package:open_vts/modules/user/components/appbars/user_home_appbar.dart';
import 'package:open_vts/modules/user/screens/vehicles/vehicle_details/controller.dart';
import 'package:open_vts/modules/user/screens/vehicles/vehicle_details/repository.dart';
import 'package:open_vts/modules/user/screens/vehicles/vehicle_details/widgets/add_document_screen.dart';
import 'package:open_vts/modules/user/screens/vehicles/vehicle_details/widgets/config_tab.dart';
import 'package:open_vts/modules/user/screens/vehicles/vehicle_details/widgets/details_tab.dart';
import 'package:open_vts/modules/user/screens/vehicles/vehicle_details/widgets/documents_tab.dart';
import 'package:open_vts/modules/user/screens/vehicles/vehicle_details/widgets/navigation_box.dart';

class VehicleDetailsScreen extends StatefulWidget {
  const VehicleDetailsScreen({
    super.key,
    required this.vehicleId,
    this.initialVehicle,
  });

  final String vehicleId;
  final VehicleListItem? initialVehicle;

  @override
  State<VehicleDetailsScreen> createState() => _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState extends State<VehicleDetailsScreen> {
  ApiClient? _apiClient;
  UserVehiclesRepository? _baseRepository;
  late final VehicleDetailsController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VehicleDetailsController(
      vehicleId: widget.vehicleId,
      initialVehicle: widget.initialVehicle,
      repository: _buildFeatureRepository(),
    )
      ..addListener(_onControllerChanged)
      ..initialize();
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  VehicleDetailsRepository _buildFeatureRepository() {
    _apiClient ??= ApiClientProvider.shared();
    _baseRepository ??= UserVehiclesRepository(api: _apiClient!);
    return VehicleDetailsRepository(delegate: _baseRepository!);
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _showResult(String message) {
    if (!mounted || message.trim().isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadDocuments() {
    return _controller.loadVehicleDocuments();
  }

  Future<void> _saveConfig() async {
    final result = await _controller.saveConfig();
    if (result != null) {
      _showResult(result.message);
    }
  }

  Future<void> _openAddVehicleDocumentSheet() async {
    if (_controller.docTypes.isEmpty) {
      await _controller.loadVehicleDocumentTypes();
    }
    if (!mounted) return;

    final submitted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => UserVehicleAddDocumentScreen(
          docTypes: _controller.docTypes,
          vehicleLabel: _controller.vehicleAppBarTitle(),
          loadingDocTypes: _controller.loadingDocTypes,
          onReloadTypes: _controller.loadVehicleDocumentTypes,
          onSubmit:
              ({
                required String title,
                required int docTypeId,
                required PlatformFile file,
                required String tags,
                required String description,
                required String? expiryAt,
                required bool isVisible,
              }) async {
                final bytes = file.bytes;
                if (bytes == null) {
                  return 'Unable to read selected file.';
                }

                final error = await _controller.uploadVehicleDocument(
                  title: title,
                  docTypeId: docTypeId,
                  fileBytes: bytes,
                  filename: file.name,
                  tags: tags,
                  description: description,
                  expiryAt: expiryAt,
                  isVisible: isVisible,
                );
                return error;
              },
        ),
      ),
    );

    if (submitted == true) {
      await _controller.loadVehicleDocuments();
      if (mounted) {
        _showResult('Document uploaded successfully');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontalPadding = AdaptiveUtils.isVerySmallScreen(width)
        ? 12.0
        : AdaptiveUtils.isSmallScreen(width)
            ? 14.0
            : 18.0;
    final topPadding = AdaptiveUtils.isVerySmallScreen(width)
        ? 8.0
        : AdaptiveUtils.isSmallScreen(width)
            ? 10.0
            : 12.0;
    final sectionSpacing = AdaptiveUtils.getLeftSectionSpacing(width);
    final hp = AdaptiveUtils.getHorizontalPadding(width);

    final visibleDocuments = _controller.visibleMappedDocuments();
    final showEmptyDocuments = _controller.showEmptyDocuments();

    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? OpenVtsColors.panelDark
          : OpenVtsColors.panelLight,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              topPadding + AppUtils.appBarHeightCustom + 70,
              horizontalPadding,
              84,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VehicleDetailsNavigationBox(
                  selectedTab: _controller.selectedTab,
                  tabs: _controller.tabs,
                  title: 'Vehicle screens',
                  subtitle: 'Switch between vehicle sections below.',
                  onTabSelected: _controller.setSelectedTab,
                ),
                const SizedBox(height: 16),
                if (_controller.selectedTab == 'Vehicle Details')
                  VehicleDetailsInfoTab(
                    details: _controller.details,
                    loading: _controller.loading,
                    horizontalPadding: hp,
                    spacing: sectionSpacing,
                    width: width,
                    safe: _controller.safe,
                  )
                else if (_controller.selectedTab == 'Documents')
                  VehicleDetailsDocumentsTab(
                    loadingDocuments: _controller.loadingDocuments,
                    documentsLoadFailed: _controller.documentsLoadFailed,
                    loadingDocTypes: _controller.loadingDocTypes,
                    uploadingDocument: _controller.uploadingDocument,
                    searchController: _controller.docSearchController,
                    onSearchChanged: (_) => _controller.onDocumentSearchChanged(),
                    onFilterSelected: _controller.setDocumentFilter,
                    onPageSizeSelected: _controller.setDocumentPageSize,
                    onUploadTap: _openAddVehicleDocumentSheet,
                    onRetry: _loadDocuments,
                    visibleDocuments: visibleDocuments,
                    showEmpty: showEmptyDocuments,
                    onDocumentChanged: _loadDocuments,
                  )
                else
                  VehicleDetailsConfigTab(
                    loadingConfig: _controller.loadingConfig,
                    savingConfig: _controller.savingConfig,
                    speedController: _controller.speedController,
                    distanceController: _controller.distanceController,
                    odometerController: _controller.odometerController,
                    engineHoursController: _controller.engineHoursController,
                    ignitionSource: _controller.ignitionSource,
                    onReset: _controller.applyConfigSnapshot,
                    onSave: _saveConfig,
                    onIgnitionSourceChanged: _controller.setIgnitionSource,
                  ),
              ],
            ),
          ),
          Positioned(
            left: horizontalPadding,
            right: horizontalPadding,
            top: 0,
            child: UserHomeAppBar(
              title: _controller.vehicleAppBarTitle(),
              leadingIcon: Icons.directions_car,
              onClose: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}

