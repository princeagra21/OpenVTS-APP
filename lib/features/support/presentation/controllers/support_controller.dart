import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/features/support/domain/config/support_role_config.dart';
import 'package:open_vts/features/support/domain/entities/support_models.dart';

class SupportState {
  const SupportState({
    this.tickets = const <SupportTicketSummary>[],
    this.isLoading = false,
    this.selectedTab = 'All',
    this.scope = SupportListScope.all,
    this.searchQuery = '',
    this.errorMessage,
    this.effect,
  });

  final List<SupportTicketSummary> tickets;
  final bool isLoading;
  final String selectedTab;
  final SupportListScope scope;
  final String searchQuery;
  final String? errorMessage;
  final SupportEffect? effect;

  List<SupportTicketSummary> get filteredTickets {
    final query = searchQuery.trim().toLowerCase();
    return tickets.where((ticket) {
      final matchesSearch =
          query.isEmpty ||
          ticket.subject.toLowerCase().contains(query) ||
          ticket.ticketNumber.toLowerCase().contains(query) ||
          ticket.ownerName.toLowerCase().contains(query) ||
          ticket.description.toLowerCase().contains(query) ||
          ticket.id.toLowerCase().contains(query);
      final normalized = SupportController.normalizeStatus(ticket.status);
      final matchesTab = selectedTab == 'All' || normalized == selectedTab;
      return matchesSearch && matchesTab;
    }).toList();
  }

  SupportState copyWith({
    List<SupportTicketSummary>? tickets,
    bool? isLoading,
    String? selectedTab,
    SupportListScope? scope,
    String? searchQuery,
    Object? errorMessage = _unchanged,
    Object? effect = _unchanged,
  }) {
    return SupportState(
      tickets: tickets ?? this.tickets,
      isLoading: isLoading ?? this.isLoading,
      selectedTab: selectedTab ?? this.selectedTab,
      scope: scope ?? this.scope,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
      effect: identical(effect, _unchanged) ? this.effect : effect as SupportEffect?,
    );
  }
}

class SupportEffect {
  const SupportEffect._(this.message, {required this.isError});
  const SupportEffect.success(String message) : this._(message, isError: false);
  const SupportEffect.error(String message) : this._(message, isError: true);

  final String message;
  final bool isError;
}

class SupportController extends StateNotifier<SupportState> {
  SupportController({required this.config, required dynamic repository})
      : _repository = repository,
        super(const SupportState());

  final SupportRoleConfig config;
  final dynamic _repository;
  int _loadVersion = 0;
  Timer? _searchDebounce;

  Future<void> loadTickets() async {
    final version = ++_loadVersion;
    state = state.copyWith(isLoading: true, errorMessage: null);

    final result = await _repository.getTickets(
      SupportListQuery(
        search: state.searchQuery.trim().isEmpty ? null : state.searchQuery.trim(),
        status: state.selectedTab == 'All' ? null : state.selectedTab,
        rk: DateTime.now().millisecondsSinceEpoch,
        limit: state.scope == SupportListScope.mine ? 100 : 50,
        scope: state.scope,
      ),
    );

    if (!mounted || version != _loadVersion) return;
    result.when(
      success: (items) => state = state.copyWith(
        tickets: items,
        isLoading: false,
        errorMessage: null,
      ),
      failure: (error) {
        final message = error.toString();
        state = state.copyWith(
          tickets: const <SupportTicketSummary>[],
          isLoading: false,
          errorMessage: message,
          effect: SupportEffect.error(message),
        );
      },
    );
  }

  void setTab(String tab) {
    if (state.selectedTab == tab) return;
    state = state.copyWith(selectedTab: tab);
  }

  void setScope(SupportListScope scope) {
    if (state.scope == scope) return;
    state = state.copyWith(scope: scope);
    unawaited(loadTickets());
  }

  void setSearchQuery(String value) {
    if (state.searchQuery == value) return;
    state = state.copyWith(searchQuery: value);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 250), loadTickets);
  }

  void clearEffect() => state = state.copyWith(effect: null);
  void clearError() => state = state.copyWith(errorMessage: null);

  static String normalizeStatus(String raw) {
    final status = raw.trim();
    final s = status.toLowerCase().replaceAll('_', ' ').replaceAll('-', ' ');
    if (s.isEmpty) return 'Open';
    if (s.contains('close')) return 'Closed';
    if (s.contains('answer') || s.contains('resolve')) return 'Answered';
    if (s.contains('hold')) return 'Hold';
    if (s.contains('process') || s.contains('progress') || s.contains('pending')) {
      return 'In Process';
    }
    if (s.contains('open') || s.contains('new')) return 'Open';
    return status;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}

const Object _unchanged = Object();
