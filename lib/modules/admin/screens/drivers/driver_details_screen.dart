import 'package:dio/dio.dart';
import 'package:fleet_stack/core/config/app_config.dart';
import 'package:fleet_stack/core/models/admin_document_item.dart';
import 'package:fleet_stack/core/models/admin_driver_details.dart';
import 'package:fleet_stack/core/models/admin_user_list_item.dart';
import 'package:fleet_stack/core/network/api_client.dart';
import 'package:fleet_stack/core/network/api_exception.dart';
import 'package:fleet_stack/core/repositories/admin_drivers_repository.dart';
import 'package:fleet_stack/core/storage/token_storage.dart';
import 'package:fleet_stack/modules/admin/layout/app_layout.dart';
import 'package:fleet_stack/modules/admin/screens/drivers/widget/admin_driver_documents_tab.dart';
import 'package:fleet_stack/modules/admin/screens/drivers/widget/admin_driver_profile_box.dart';
import 'package:fleet_stack/modules/admin/screens/drivers/widget/admin_driver_profile_tab.dart';
import 'package:fleet_stack/modules/admin/screens/drivers/widget/admin_driver_users_tab.dart';
import 'package:fleet_stack/modules/admin/utils/adaptive_utils.dart';
import 'package:fleet_stack/modules/superadmin/components/admin/navigate.dart';
import 'package:flutter/material.dart';

class AdminDriverDetailsScreen extends StatefulWidget {
  final String id;

  const AdminDriverDetailsScreen({super.key, required this.id});

  @override
  State<AdminDriverDetailsScreen> createState() =>
      _AdminDriverDetailsScreenState();
}

class _AdminDriverDetailsScreenState extends State<AdminDriverDetailsScreen> {
  // Confirmed endpoints:
  // - GET /admin/drivers/:id
  // - GET /admin/documents/driver/:id
  // - GET /admin/drivers/linkedusers/:id
  static const List<String> _tabs = <String>['Profile', 'Documents', 'Users'];

  String _selectedTab = 'Profile';

  AdminDriverDetails? _details;
  bool _loadingDetails = false;
  bool _detailsErrorShown = false;
  CancelToken? _detailsToken;

  List<AdminDocumentItem> _documents = const <AdminDocumentItem>[];
  bool _loadingDocuments = false;
  bool _documentsLoaded = false;
  CancelToken? _documentsToken;

  List<AdminUserListItem> _users = const <AdminUserListItem>[];
  bool _loadingUsers = false;
  bool _usersLoaded = false;
  CancelToken? _usersToken;

  final Map<String, bool> _tabErrorShown = <String, bool>{
    'Documents': false,
    'Users': false,
  };

  ApiClient? _apiClient;
  AdminDriversRepository? _repo;

  AdminDriversRepository _repoOrCreate() {
    _apiClient ??= ApiClient(
      config: AppConfig.fromDartDefine(),
      tokenStorage: TokenStorage.defaultInstance(),
    );
    _repo ??= AdminDriversRepository(api: _apiClient!);
    return _repo!;
  }

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _detailsToken?.cancel('Driver details disposed');
    _documentsToken?.cancel('Driver documents disposed');
    _usersToken?.cancel('Driver linked users disposed');
    super.dispose();
  }

  bool _isCancelled(Object err) {
    return err is ApiException &&
        err.message.toLowerCase() == 'request cancelled';
  }

  void _showDetailsErrorOnce(String message) {
    if (_detailsErrorShown || !mounted) return;
    _detailsErrorShown = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showTabErrorOnce(String tab, String message) {
    if ((_tabErrorShown[tab] ?? false) || !mounted) return;
    _tabErrorShown[tab] = true;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _loadDetails() async {
    _detailsToken?.cancel('Reload driver details');
    final token = CancelToken();
    _detailsToken = token;

    if (!mounted) return;
    setState(() => _loadingDetails = true);

    try {
      final result = await _repoOrCreate().getDriverDetails(
        widget.id,
        cancelToken: token,
      );
      if (!mounted) return;

      result.when(
        success: (details) {
          setState(() {
            _details = details;
            _loadingDetails = false;
            _detailsErrorShown = false;
          });
        },
        failure: (err) {
          setState(() {
            _details = null;
            _loadingDetails = false;
          });
          if (_isCancelled(err)) return;
          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load driver details.'
              : "Couldn't load driver details.";
          _showDetailsErrorOnce(message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _details = null;
        _loadingDetails = false;
      });
      _showDetailsErrorOnce("Couldn't load driver details.");
    }
  }

  void _selectTab(String tab) {
    if (_selectedTab == tab) return;
    setState(() => _selectedTab = tab);
    _ensureSelectedTabLoaded(tab);
  }

  void _ensureSelectedTabLoaded(String tab) {
    switch (tab) {
      case 'Documents':
        if (!_documentsLoaded && !_loadingDocuments) _loadDocuments();
        break;
      case 'Users':
        if (!_usersLoaded && !_loadingUsers) _loadUsers();
        break;
      default:
        break;
    }
  }

  Future<void> _loadDocuments() async {
    _documentsToken?.cancel('Reload driver documents');
    final token = CancelToken();
    _documentsToken = token;

    if (!mounted) return;
    setState(() => _loadingDocuments = true);

    try {
      final result = await _repoOrCreate().getDriverDocuments(
        widget.id,
        cancelToken: token,
      );
      if (!mounted) return;
      result.when(
        success: (items) {
          setState(() {
            _documents = items;
            _documentsLoaded = true;
            _loadingDocuments = false;
            _tabErrorShown['Documents'] = false;
          });
        },
        failure: (err) {
          setState(() {
            _documents = const <AdminDocumentItem>[];
            _documentsLoaded = true;
            _loadingDocuments = false;
          });
          if (_isCancelled(err)) return;
          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load driver documents.'
              : "Couldn't load driver documents.";
          _showTabErrorOnce('Documents', message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _documents = const <AdminDocumentItem>[];
        _documentsLoaded = true;
        _loadingDocuments = false;
      });
      _showTabErrorOnce('Documents', "Couldn't load driver documents.");
    }
  }

  Future<void> _loadUsers() async {
    _usersToken?.cancel('Reload linked users');
    final token = CancelToken();
    _usersToken = token;

    if (!mounted) return;
    setState(() => _loadingUsers = true);

    try {
      final result = await _repoOrCreate().getLinkedUsers(
        widget.id,
        cancelToken: token,
      );
      if (!mounted) return;
      result.when(
        success: (items) {
          setState(() {
            _users = items;
            _usersLoaded = true;
            _loadingUsers = false;
            _tabErrorShown['Users'] = false;
          });
        },
        failure: (err) {
          setState(() {
            _users = const <AdminUserListItem>[];
            _usersLoaded = true;
            _loadingUsers = false;
          });
          if (_isCancelled(err)) return;
          final message =
              (err is ApiException &&
                  (err.statusCode == 401 || err.statusCode == 403))
              ? 'Not authorized to load linked users.'
              : "Couldn't load linked users.";
          _showTabErrorOnce('Users', message);
        },
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _users = const <AdminUserListItem>[];
        _usersLoaded = true;
        _loadingUsers = false;
      });
      _showTabErrorOnce('Users', "Couldn't load linked users.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final padding = AdaptiveUtils.getHorizontalPadding(w);
    final titleFs = AdaptiveUtils.getTitleFontSize(w);
    final bodyFs = titleFs - 1;
    final smallFs = titleFs - 3;
    final subtitle =
        (_details?.fullName ?? _details?.username ?? 'Driver Details').trim();
    final initialsSource = (_details?.initials ?? '--').trim();

    return AppLayout(
      title: 'DRIVER',
      subtitle: subtitle.isEmpty ? 'Driver Details' : subtitle,
      showLeftAvatar: false,
      leftAvatarText: initialsSource.isEmpty ? '--' : initialsSource,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminDriverProfileBox(details: _details, loading: _loadingDetails),
          SizedBox(height: padding),
          NavigateBox(
            selectedTab: _selectedTab,
            tabs: _tabs,
            onTabSelected: _selectTab,
          ),
          SizedBox(height: padding),
          _buildTabContent(bodyFs, smallFs),
        ],
      ),
    );
  }

  Widget _buildTabContent(double bodyFs, double smallFs) {
    switch (_selectedTab) {
      case 'Documents':
        return AdminDriverDocumentsTab(
          items: _documents,
          loading: _loadingDocuments,
          bodyFontSize: bodyFs,
          smallFontSize: smallFs,
        );
      case 'Users':
        return AdminDriverUsersTab(
          items: _users,
          loading: _loadingUsers,
          bodyFontSize: bodyFs,
          smallFontSize: smallFs,
        );
      case 'Profile':
      default:
        return AdminDriverProfileTab(
          details: _details,
          loading: _loadingDetails,
          bodyFontSize: bodyFs,
        );
    }
  }
}
