import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_vts/features/superadmin/domain/entities/superadmin_document_type.dart';
import 'package:open_vts/features/user/domain/entities/user_vehicle_details.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_document_item.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_list_item.dart';
import 'package:open_vts/core/error/error_presenter.dart';
import 'package:open_vts/features/user/presentation/screens/vehicles/vehicle_details/config.dart';
import 'package:open_vts/features/user/presentation/screens/vehicles/vehicle_details/models.dart';
import 'package:open_vts/features/user/application/vehicle_details/vehicle_details_repository.dart';
import 'package:open_vts/core/state/effect_controller_mixin.dart';
import 'package:open_vts/core/state/listenable_controller.dart';
import 'package:open_vts/core/state/ui_effect.dart';

class VehicleDetailsController extends ListenableController with EffectControllerMixin {
  VehicleDetailsController({
    required this.vehicleId,
    required this.repository,
    this.initialVehicle,
  });

  final String vehicleId;
  final VehicleDetailsRepository repository;
  final VehicleListItem? initialVehicle;

  UserVehicleDetails? _details;
  bool _loading = false;
  bool _errorShown = false;
  int _detailsRequestId = 0;

  String _selectedTab = VehicleDetailsConfig.tabs.first;
  bool _loadingConfig = true;
  bool _savingConfig = false;
  bool _configLoaded = false;

  bool _loadingDocuments = false;
  bool _documentsLoadFailed = false;
  bool _loadingDocTypes = false;
  final bool _uploadingDocument = false;
  bool _documentsLoaded = false;

  final TextEditingController _docSearchController = TextEditingController();
  String _docFilterTab = VehicleDetailsConfig.documentFilters.first;
  int _docPageSize = VehicleDetailsConfig.documentPageSizes.first;
  List<VehicleDocumentItem> _documents = const <VehicleDocumentItem>[];
  List<SuperadminDocumentType> _docTypes = const <SuperadminDocumentType>[];
  int _documentsRequestId = 0;
  int _docTypesRequestId = 0;
  int _uploadDocumentRequestId = 0;

  final TextEditingController _speedController = TextEditingController(
    text: '1.00',
  );
  final TextEditingController _distanceController = TextEditingController(
    text: '1.00',
  );
  final TextEditingController _odometerController = TextEditingController(
    text: '0',
  );
  final TextEditingController _engineHoursController = TextEditingController(
    text: '0',
  );

  String _ignitionSource = 'Ignition Wire';
  String _snapSpeed = '1.00';
  String _snapDistance = '1.00';
  String _snapOdometer = '0';
  String _snapEngineHours = '0';
  String _snapIgnition = 'Ignition Wire';

  UserVehicleDetails? get details => _details;
  bool get loading => _loading;
  bool get loadingConfig => _loadingConfig;
  bool get savingConfig => _savingConfig;
  bool get configLoaded => _configLoaded;

  bool get loadingDocuments => _loadingDocuments;
  bool get documentsLoadFailed => _documentsLoadFailed;
  bool get loadingDocTypes => _loadingDocTypes;
  bool get uploadingDocument => _uploadingDocument;
  bool get documentsLoaded => _documentsLoaded;

  String get selectedTab => _selectedTab;
  List<String> get tabs => VehicleDetailsConfig.tabs;

  TextEditingController get docSearchController => _docSearchController;
  String get docFilterTab => _docFilterTab;
  int get docPageSize => _docPageSize;
  List<VehicleDocumentItem> get documents => _documents;
  List<SuperadminDocumentType> get docTypes => _docTypes;

  TextEditingController get speedController => _speedController;
  TextEditingController get distanceController => _distanceController;
  TextEditingController get odometerController => _odometerController;
  TextEditingController get engineHoursController => _engineHoursController;
  String get ignitionSource => _ignitionSource;

  void initialize() {
    loadDetails();
    loadVehicleDocuments();
    loadVehicleDocumentTypes();
  }

  void setSelectedTab(String tab) {
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    notifyListeners();

    if (tab == VehicleDetailsTab.documents.label && !_documentsLoaded) {
      loadVehicleDocuments();
    }
  }

  void setDocumentFilter(String value) {
    _docFilterTab = value;
    _docPageSize = VehicleDetailsConfig.documentPageSizes.first;
    notifyListeners();
  }

  void setDocumentPageSize(int value) {
    _docPageSize = value;
    notifyListeners();
  }

  void onDocumentSearchChanged() {
    _docPageSize = VehicleDetailsConfig.documentPageSizes.first;
    notifyListeners();
  }

  String vehicleAppBarTitle() {
    final currentDetails = _details;
    final fromDetails = currentDetails?.displayTitle.trim();
    if (fromDetails != null && fromDetails.isNotEmpty) return fromDetails;

    final fromInitialName = initialVehicle?.name.trim();
    if (fromInitialName != null && fromInitialName.isNotEmpty) {
      return fromInitialName;
    }

    final fromInitialPlate = initialVehicle?.plateNumber.trim();
    if (fromInitialPlate != null && fromInitialPlate.isNotEmpty) {
      return fromInitialPlate;
    }

    return 'Vehicle Details';
  }

  Future<VehicleDetailsActionResult?> loadDetails() async {
    final requestId = ++_detailsRequestId;

    _loading = true;
    _loadingConfig = true;
    notifyListeners();

    final result = await repository.getVehicleDetails(vehicleId);
    if (requestId != _detailsRequestId) return null;

    VehicleDetailsActionResult? actionResult;
    result.when(
      success: (vehicleDetails) {
        _details = vehicleDetails;
        _loading = false;
        _errorShown = false;
        _loadingConfig = false;
        _loadConfigFromDetails(vehicleDetails);
      },
      failure: (error) {
        _loading = false;
        _loadingConfig = false;
        if (ErrorPresenter.isCancellation(error) || _errorShown) return;

        _errorShown = true;
        final message = ErrorPresenter.message(
          error,
          fallback: "Couldn't load vehicle details.",
        );
        emitEffect(UiEffect.showError(message));
        actionResult = VehicleDetailsActionResult.error(message);
      },
    );

    notifyListeners();
    return actionResult;
  }

  Future<void> loadVehicleDocuments() async {
    final requestId = ++_documentsRequestId;

    _loadingDocuments = true;
    notifyListeners();

    final result = await repository.getVehicleDocuments(vehicleId);
    if (requestId != _documentsRequestId) return;

    result.when(
      success: (items) {
        _documents = items;
        _loadingDocuments = false;
        _documentsLoaded = true;
        _documentsLoadFailed = false;
      },
      failure: (_) {
        _loadingDocuments = false;
        _documentsLoaded = true;
        _documentsLoadFailed = true;
      },
    );

    notifyListeners();
  }

  Future<void> loadVehicleDocumentTypes() async {
    final requestId = ++_docTypesRequestId;

    _loadingDocTypes = true;
    notifyListeners();

    final result = await repository.getVehicleDocumentTypes();
    if (requestId != _docTypesRequestId) return;

    result.when(
      success: (items) {
        _docTypes = items;
        _loadingDocTypes = false;
      },
      failure: (_) {
        _loadingDocTypes = false;
      },
    );

    notifyListeners();
  }

  Future<VehicleDetailsActionResult?> saveConfig() async {
    final speedError = _validateRange(
      'Speed Multiplier',
      _speedController.text,
      min: VehicleDetailsConfig.minMultiplier,
      max: VehicleDetailsConfig.maxMultiplier,
    );
    final distanceError = _validateRange(
      'Distance Multiplier',
      _distanceController.text,
      min: VehicleDetailsConfig.minMultiplier,
      max: VehicleDetailsConfig.maxMultiplier,
    );
    final odometerError = _validateRange(
      'Odometer',
      _odometerController.text,
      min: 0,
      max: VehicleDetailsConfig.maxOdometer,
    );
    final engineHoursError = _validateRange(
      'Engine Hours',
      _engineHoursController.text,
      min: 0,
      max: VehicleDetailsConfig.maxEngineHours,
    );

    final validationError =
        speedError ?? distanceError ?? odometerError ?? engineHoursError;
    if (validationError != null) {
      return VehicleDetailsActionResult.error(validationError);
    }

    _savingConfig = true;
    notifyListeners();

    try {
      final speed = double.tryParse(_speedController.text.trim());
      final distance = double.tryParse(_distanceController.text.trim());
      final odometer = double.tryParse(_odometerController.text.trim());
      final engineHours = double.tryParse(_engineHoursController.text.trim());

      final payload = <String, dynamic>{
        if (speed != null) 'speedVariation': speed,
        if (distance != null) 'distanceVariation': distance,
        if (odometer != null) 'odometer': odometer,
        if (engineHours != null) 'engineHours': engineHours,
        'ignitionSource': _ignitionSource == 'Motion-Based' ? 'MOTION' : 'ACC',
      };

      VehicleDetailsActionResult? result;
      final response = await repository.updateVehicleConfig(
        vehicleId: vehicleId,
        payload: payload,
      );

      response.when(
        success: (_) {
          _snapSpeed = _speedController.text;
          _snapDistance = _distanceController.text;
          _snapOdometer = _odometerController.text;
          _snapEngineHours = _engineHoursController.text;
          _snapIgnition = _ignitionSource;
          result = VehicleDetailsActionResult.success('Config updated');
        },
        failure: (error) {
          final message = ErrorPresenter.message(
            error,
            fallback: "Couldn't update config.",
          );
          emitEffect(UiEffect.showError(message));
          result = VehicleDetailsActionResult.error(message);
        },
      );

      return result;
    } catch (_) {
      return VehicleDetailsActionResult.error("Couldn't update config.");
    } finally {
      _savingConfig = false;
      notifyListeners();
    }
  }

  void applyConfigSnapshot() {
    _speedController.text = _snapSpeed;
    _distanceController.text = _snapDistance;
    _odometerController.text = _snapOdometer;
    _engineHoursController.text = _snapEngineHours;
    _ignitionSource = _snapIgnition;
    notifyListeners();
  }

  void setIgnitionSource(String value) {
    if (_savingConfig) return;
    _ignitionSource = value;
    notifyListeners();
  }

  Future<String?> uploadVehicleDocument({
    required String title,
    required int docTypeId,
    required Uint8List fileBytes,
    required String filename,
    required String tags,
    required String description,
    required String? expiryAt,
    required bool isVisible,
  }) async {
    final requestId = ++_uploadDocumentRequestId;

    final response = await repository.uploadVehicleDocument(
      vehicleId: vehicleId,
      title: title,
      docTypeId: docTypeId,
      fileBytes: fileBytes,
      filename: filename,
      tags: tags,
      expiryAt: expiryAt,
      isVisible: isVisible,
    );

    if (requestId != _uploadDocumentRequestId) {
      return null;
    }

    if (response.isSuccess) {
      return null;
    }

    final message = ErrorPresenter.message(
      response.error,
      fallback: "Couldn't upload document.",
    );
    emitEffect(UiEffect.showError(message));
    return message;
  }

  List<Map<String, dynamic>> filteredMappedDocuments() {
    final query = _docSearchController.text.trim().toLowerCase();
    final mappedDocs = _documents.map(mapVehicleDocToAdminStyle).toList();

    return mappedDocs.where((file) {
      final matchesSearch =
          query.isEmpty ||
          file['fileName'].toString().toLowerCase().contains(query) ||
          file['title'].toString().toLowerCase().contains(query) ||
          file['fileType'].toString().toLowerCase().contains(query) ||
          file['type'].toString().toLowerCase().contains(query) ||
          file['status'].toString().toLowerCase().contains(query) ||
          file['isVisible'].toString().toLowerCase().contains(query) ||
          (file['tags'] as List<String>).any(
            (tag) => tag.toLowerCase().contains(query),
          ) ||
          file['expiryDate'].toString().toLowerCase().contains(query) ||
          file['uploadedDate'].toString().toLowerCase().contains(query);

      final matchesTab = switch (_docFilterTab) {
        'All' => true,
        'Valid' => file['_valid'] == true,
        'Warning' => file['_warning'] == true,
        'Expired' => file['_expired'] == true,
        _ => true,
      };

      return matchesSearch && matchesTab;
    }).toList();
  }

  List<Map<String, dynamic>> visibleMappedDocuments() {
    final filtered = filteredMappedDocuments();
    return filtered.take(_docPageSize).toList();
  }

  bool showEmptyDocuments() {
    return !_loadingDocuments && filteredMappedDocuments().isEmpty;
  }

  String safe(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty || text.toLowerCase() == 'null') return '—';
    return text;
  }

  String formatDateTime(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return '—';
    final parsed = DateTime.tryParse(value);
    if (parsed == null) return value;

    final local = parsed.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year}, '
        '${two(local.hour)}:${two(local.minute)}';
  }

  String headerTitle() {
    final currentDetails = _details;
    if (currentDetails != null) return safe(currentDetails.displayTitle);

    final initial = initialVehicle;
    if (initial == null) return '—';

    final plate = initial.plateNumber.trim();
    if (plate.isNotEmpty) return plate;

    final name = initial.name.trim();
    if (name.isNotEmpty) return name;

    return safe(initial.id);
  }

  String headerSubtitle() {
    final currentDetails = _details;
    if (currentDetails != null) {
      final vehicleName = safe(currentDetails.name);
      return vehicleName == '—' ? safe(currentDetails.vehicleTypeName) : vehicleName;
    }

    final initial = initialVehicle;
    if (initial == null) return '—';

    final name = initial.name.trim();
    if (name.isNotEmpty) return name;

    return safe(initial.type);
  }

  String statusLabel() {
    final currentDetails = _details;
    if (currentDetails != null) return safe(currentDetails.statusLabel);

    final initial = initialVehicle;
    if (initial == null) return '—';

    return initial.isActive ? 'Active' : 'Inactive';
  }

  String documentBucket(VehicleDocumentItem item) {
    final status = item.status.toLowerCase();
    if (status.contains('expired')) return 'Expired';
    if (status.contains('warning') || status.contains('expiring')) {
      return 'Warning';
    }

    if (item.expiresAt.trim().isNotEmpty) {
      final expiry = DateTime.tryParse(item.expiresAt.trim());
      if (expiry != null) {
        final days = expiry.difference(DateTime.now()).inDays;
        if (days < 0) return 'Expired';
        if (days <= 15) return 'Warning';
      }
    }

    return 'Valid';
  }

  Map<String, dynamic> mapVehicleDocToAdminStyle(VehicleDocumentItem item) {
    String readDocTypeName() {
      final rawDocType = item.raw['docType'];
      if (rawDocType is Map) {
        final name = (rawDocType['name'] ?? '').toString().trim();
        if (name.isNotEmpty) return name;
      }

      final rawType =
          item.raw['type'] ?? item.raw['documentType'] ?? item.raw['docType'];
      if (rawType is String && rawType.trim().isNotEmpty) {
        return rawType.trim();
      }
      if (rawType is Map) {
        final name = (rawType['name'] ?? '').toString().trim();
        if (name.isNotEmpty) return name;
      }

      final fallback = item.type.trim();
      return fallback.isEmpty ? 'Document' : fallback;
    }

    final fileName = item.fileName.trim().isEmpty ? '—' : item.fileName.trim();
    final titleValue = (item.raw['title'] ?? '').toString().trim();
    final cleanTitle = titleValue.isEmpty ? fileName : titleValue;
    final fileTypeValue = (item.raw['fileType'] ?? '').toString().trim();

    final tagsRaw = item.raw['tags'];
    final tagsList = <String>[];
    if (tagsRaw is String && tagsRaw.trim().isNotEmpty) {
      tagsList.addAll(
        tagsRaw.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty),
      );
    } else if (tagsRaw is List) {
      tagsList.addAll(
        tagsRaw.map((tag) => tag.toString().trim()).where((tag) => tag.isNotEmpty),
      );
    }

    final bucket = documentBucket(item);
    final isValid = bucket == 'Valid';
    final isWarning = bucket == 'Warning';
    final isExpired = bucket == 'Expired';

    final rawFilePath =
        (item.raw['filePath'] ??
                item.raw['fileUrl'] ??
                item.raw['url'] ??
                item.raw['path'])
            .toString()
            .trim();
    final mappedFilePath = rawFilePath.isNotEmpty ? rawFilePath : item.url.trim();

    return <String, dynamic>{
      'id': item.id,
      'docTypeId': '',
      'fileName': fileName,
      'version': '',
      'fileSize': item.sizeBytes <= 0
          ? ''
          : '${(item.sizeBytes / 1024).toStringAsFixed(2)} KB',
      'type': readDocTypeName(),
      'fileType': fileTypeValue,
      'filePath': mappedFilePath,
      'title': cleanTitle,
      'description': '',
      'tags': tagsList,
      'uploadedDate': item.uploadedAt,
      'createdAt': item.uploadedAt,
      'expiryAt': item.expiresAt,
      'expiryDate': item.expiresAt.trim().isEmpty ? '—' : item.expiresAt.trim(),
      'status': item.status.trim().isEmpty ? bucket : item.status.trim(),
      'isVisible': true,
      'associateType': 'VEHICLE',
      'associateUserId': '',
      'associateDriverId': '',
      'associateVehicleId': vehicleId,
      'uploadedByType': 'USER',
      'uploadedByUserId': '',
      'uploadedByDriverId': '',
      '_valid': isValid,
      '_warning': isWarning,
      '_expired': isExpired,
      '_sizeBytes': item.sizeBytes,
    };
  }

  String? _validateRange(
    String label,
    String raw, {
    required double min,
    required double max,
  }) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    final value = double.tryParse(text);
    if (value == null) {
      return '$label must be a valid number.';
    }

    if (value < min || value > max) {
      return '$label must be between ${min.toStringAsFixed(min == min.toInt() ? 0 : 1)} and ${max.toStringAsFixed(max == max.toInt() ? 0 : 1)}.';
    }

    return null;
  }

  void _loadConfigFromDetails(UserVehicleDetails details) {
    final device = details.device;

    String formatDecimal(Object? value, {int fixed = 2}) {
      final text = safe(value?.toString());
      final parsed = double.tryParse(text);
      if (parsed == null) return text == '—' ? '' : text;
      return parsed.toStringAsFixed(fixed);
    }

    _speedController.text =
        formatDecimal(device['speedVariation'], fixed: 2).isEmpty
        ? '1.00'
        : formatDecimal(device['speedVariation'], fixed: 2);
    _distanceController.text =
        formatDecimal(device['distanceVariation'], fixed: 2).isEmpty
        ? '1.00'
        : formatDecimal(device['distanceVariation'], fixed: 2);
    _odometerController.text = formatDecimal(device['odometer'], fixed: 0).isEmpty
        ? '0'
        : formatDecimal(device['odometer'], fixed: 0);
    _engineHoursController.text =
        formatDecimal(device['engineHours'], fixed: 0).isEmpty
        ? '0'
        : formatDecimal(device['engineHours'], fixed: 0);

    final ignition = safe(device['ignitionSource']?.toString());
    if (ignition.isNotEmpty && ignition != '—') {
      _ignitionSource = ignition.toLowerCase().contains('motion')
          ? 'Motion-Based'
          : 'Ignition Wire';
    }

    _snapSpeed = _speedController.text;
    _snapDistance = _distanceController.text;
    _snapOdometer = _odometerController.text;
    _snapEngineHours = _engineHoursController.text;
    _snapIgnition = _ignitionSource;
    _configLoaded = true;
  }

  @override
  void dispose() {
    _detailsRequestId++;
    _documentsRequestId++;
    _docTypesRequestId++;
    _uploadDocumentRequestId++;

    _speedController.dispose();
    _distanceController.dispose();
    _odometerController.dispose();
    _engineHoursController.dispose();
    _docSearchController.dispose();

    super.dispose();
  }
}
