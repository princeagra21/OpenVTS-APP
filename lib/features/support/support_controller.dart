import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:open_vts/features/support/support_models.dart';
import 'package:open_vts/features/support/support_repository.dart';
import 'package:open_vts/features/support/support_role_config.dart';

class SupportController extends ChangeNotifier {
  SupportController({required this.config, required this.repository}) {
    searchController.addListener(_onSearchChanged);
  }

  final SupportRoleConfig config;
  final SupportRepositoryAdapter repository;

  final TextEditingController searchController = TextEditingController();

  CancelToken? _loadToken;

  List<SupportTicketSummary> _tickets = const <SupportTicketSummary>[];
  bool _loading = false;
  String _selectedTab = 'All';
  SupportListScope _scope = SupportListScope.all;
  String? _errorMessage;

  List<SupportTicketSummary> get tickets => _tickets;
  bool get loading => _loading;
  String get selectedTab => _selectedTab;
  SupportListScope get scope => _scope;
  String? get errorMessage => _errorMessage;

  List<SupportTicketSummary> get filteredTickets {
    final query = searchController.text.trim().toLowerCase();
    return _tickets.where((ticket) {
      final matchesSearch =
          query.isEmpty ||
          ticket.subject.toLowerCase().contains(query) ||
          ticket.ticketNumber.toLowerCase().contains(query) ||
          ticket.ownerName.toLowerCase().contains(query) ||
          ticket.description.toLowerCase().contains(query) ||
          ticket.id.toLowerCase().contains(query);
      final normalized = _normalizeStatus(ticket.status);
      final matchesTab = _selectedTab == 'All' || normalized == _selectedTab;
      return matchesSearch && matchesTab;
    }).toList();
  }

  void setTab(String tab) {
    if (_selectedTab == tab) return;
    _selectedTab = tab;
    notifyListeners();
  }

  void setScope(SupportListScope scope) {
    if (_scope == scope) return;
    _scope = scope;
    notifyListeners();
  }

  Future<void> loadTickets() async {
    _loadToken?.cancel('Reload support tickets');
    final token = CancelToken();
    _loadToken = token;

    _loading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await repository.getTickets(
      SupportListQuery(
        rk: DateTime.now().millisecondsSinceEpoch,
        limit: _scope == SupportListScope.mine ? 100 : 50,
        scope: _scope,
      ),
      cancelToken: token,
    );

    if (token.isCancelled) return;

    result.when(
      success: (items) {
        _tickets = items;
        _loading = false;
        _errorMessage = null;
      },
      failure: (error) {
        _tickets = const <SupportTicketSummary>[];
        _loading = false;
        _errorMessage = error.toString();
      },
    );
    notifyListeners();
  }

  String _normalizeStatus(String raw) {
    final status = raw.trim();
    final s = status.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');
    if (s.isEmpty) return 'Open';
    if (s.contains('close')) return 'Closed';
    if (s.contains('answer') || s.contains('resolve')) return 'Answered';
    if (s.contains('hold')) return 'Hold';
    if (s.contains('process') ||
        s.contains('progress') ||
        s.contains('pending')) {
      return 'In Process';
    }
    if (s.contains('open') || s.contains('new')) return 'Open';
    return status;
  }

  void _onSearchChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    _loadToken?.cancel('SupportController disposed');
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    super.dispose();
  }
}
