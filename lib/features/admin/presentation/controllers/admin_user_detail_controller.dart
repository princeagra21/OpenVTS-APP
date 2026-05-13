import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_vts/core/error/app_error.dart';
import 'package:open_vts/features/admin/di/admin_account_providers.dart';
import 'package:open_vts/features/admin/domain/entities/admin_document_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_driver_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_ticket_list_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_transaction_item.dart';
import 'package:open_vts/features/admin/domain/entities/admin_user_details.dart';
import 'package:open_vts/features/admin/domain/entities/admin_vehicle_list_item.dart';

class AdminUserDetailState {
  const AdminUserDetailState({
    this.user,
    this.vehicles = const <AdminVehicleListItem>[],
    this.drivers = const <AdminDriverListItem>[],
    this.documents = const <AdminDocumentItem>[],
    this.tickets = const <AdminTicketListItem>[],
    this.payments = const <AdminTransactionItem>[],
    this.isLoading = false,
    this.isLoadingVehicles = false,
    this.isLoadingDrivers = false,
    this.isLoadingDocuments = false,
    this.isLoadingTickets = false,
    this.isLoadingPayments = false,
    this.vehiclesLoaded = false,
    this.driversLoaded = false,
    this.documentsLoaded = false,
    this.ticketsLoaded = false,
    this.paymentsLoaded = false,
    this.error,
  });

  final AdminUserDetails? user;
  final List<AdminVehicleListItem> vehicles;
  final List<AdminDriverListItem> drivers;
  final List<AdminDocumentItem> documents;
  final List<AdminTicketListItem> tickets;
  final List<AdminTransactionItem> payments;
  final bool isLoading;
  final bool isLoadingVehicles;
  final bool isLoadingDrivers;
  final bool isLoadingDocuments;
  final bool isLoadingTickets;
  final bool isLoadingPayments;
  final bool vehiclesLoaded;
  final bool driversLoaded;
  final bool documentsLoaded;
  final bool ticketsLoaded;
  final bool paymentsLoaded;
  final AppError? error;

  AdminUserDetailState copyWith({
    AdminUserDetails? user,
    List<AdminVehicleListItem>? vehicles,
    List<AdminDriverListItem>? drivers,
    List<AdminDocumentItem>? documents,
    List<AdminTicketListItem>? tickets,
    List<AdminTransactionItem>? payments,
    bool? isLoading,
    bool? isLoadingVehicles,
    bool? isLoadingDrivers,
    bool? isLoadingDocuments,
    bool? isLoadingTickets,
    bool? isLoadingPayments,
    bool? vehiclesLoaded,
    bool? driversLoaded,
    bool? documentsLoaded,
    bool? ticketsLoaded,
    bool? paymentsLoaded,
    Object? error = _unchanged,
  }) {
    return AdminUserDetailState(
      user: user ?? this.user,
      vehicles: vehicles ?? this.vehicles,
      drivers: drivers ?? this.drivers,
      documents: documents ?? this.documents,
      tickets: tickets ?? this.tickets,
      payments: payments ?? this.payments,
      isLoading: isLoading ?? this.isLoading,
      isLoadingVehicles: isLoadingVehicles ?? this.isLoadingVehicles,
      isLoadingDrivers: isLoadingDrivers ?? this.isLoadingDrivers,
      isLoadingDocuments: isLoadingDocuments ?? this.isLoadingDocuments,
      isLoadingTickets: isLoadingTickets ?? this.isLoadingTickets,
      isLoadingPayments: isLoadingPayments ?? this.isLoadingPayments,
      vehiclesLoaded: vehiclesLoaded ?? this.vehiclesLoaded,
      driversLoaded: driversLoaded ?? this.driversLoaded,
      documentsLoaded: documentsLoaded ?? this.documentsLoaded,
      ticketsLoaded: ticketsLoaded ?? this.ticketsLoaded,
      paymentsLoaded: paymentsLoaded ?? this.paymentsLoaded,
      error: identical(error, _unchanged) ? this.error : error as AppError?,
    );
  }
}

const Object _unchanged = Object();

class AdminUserDetailController extends StateNotifier<AdminUserDetailState> {
  AdminUserDetailController(this._ref, this._userId)
      : super(const AdminUserDetailState());

  final Ref _ref;
  final String _userId;
  int _requestSeq = 0;

  int _nextRequest() => ++_requestSeq;
  bool _isCurrent(int requestId) => mounted && requestId == _requestSeq;

  Future<bool> load({bool silent = false}) async {
    final requestId = _nextRequest();
    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    } else {
      state = state.copyWith(error: null);
    }

    final result = await _ref.read(getAdminUserDetailUseCaseProvider)(_userId);
    if (!_isCurrent(requestId)) return false;

    return result.when(
      success: (user) {
        state = state.copyWith(user: user, isLoading: false, error: null);
        return true;
      },
      failure: (error) {
        state = state.copyWith(isLoading: false, error: error);
        return false;
      },
    );
  }

  Future<bool> loadVehicles({bool force = false}) async {
    if (!force && (state.vehiclesLoaded || state.isLoadingVehicles)) return true;
    state = state.copyWith(isLoadingVehicles: true, error: null);
    final result = await _ref.read(getAdminUserLinkedVehiclesUseCaseProvider)(_userId);
    if (!mounted) return false;
    return result.when(
      success: (items) {
        state = state.copyWith(
          vehicles: items,
          vehiclesLoaded: true,
          isLoadingVehicles: false,
          error: null,
        );
        return true;
      },
      failure: (error) {
        state = state.copyWith(
          vehicles: const <AdminVehicleListItem>[],
          vehiclesLoaded: true,
          isLoadingVehicles: false,
          error: error,
        );
        return false;
      },
    );
  }

  Future<bool> loadDrivers({bool force = false}) async {
    if (!force && (state.driversLoaded || state.isLoadingDrivers)) return true;
    state = state.copyWith(isLoadingDrivers: true, error: null);
    final result = await _ref.read(getAdminUserLinkedDriversUseCaseProvider)(_userId);
    if (!mounted) return false;
    return result.when(
      success: (items) {
        state = state.copyWith(
          drivers: items,
          driversLoaded: true,
          isLoadingDrivers: false,
          error: null,
        );
        return true;
      },
      failure: (error) {
        state = state.copyWith(
          drivers: const <AdminDriverListItem>[],
          driversLoaded: true,
          isLoadingDrivers: false,
          error: error,
        );
        return false;
      },
    );
  }

  Future<bool> loadDocuments({bool force = false}) async {
    if (!force && (state.documentsLoaded || state.isLoadingDocuments)) return true;
    state = state.copyWith(isLoadingDocuments: true, error: null);
    final result = await _ref.read(getAdminUserDocumentsUseCaseProvider)(_userId);
    if (!mounted) return false;
    return result.when(
      success: (items) {
        state = state.copyWith(
          documents: items,
          documentsLoaded: true,
          isLoadingDocuments: false,
          error: null,
        );
        return true;
      },
      failure: (error) {
        state = state.copyWith(
          documents: const <AdminDocumentItem>[],
          documentsLoaded: true,
          isLoadingDocuments: false,
          error: error,
        );
        return false;
      },
    );
  }

  Future<bool> loadTickets({int? limit, int? rk, bool force = false}) async {
    if (!force && (state.ticketsLoaded || state.isLoadingTickets)) return true;
    state = state.copyWith(isLoadingTickets: true, error: null);
    final result = await _ref.read(getAdminUserTicketsUseCaseProvider)(_userId, limit: limit, rk: rk);
    if (!mounted) return false;
    return result.when(
      success: (items) {
        state = state.copyWith(
          tickets: items,
          ticketsLoaded: true,
          isLoadingTickets: false,
          error: null,
        );
        return true;
      },
      failure: (error) {
        state = state.copyWith(
          tickets: const <AdminTicketListItem>[],
          ticketsLoaded: true,
          isLoadingTickets: false,
          error: error,
        );
        return false;
      },
    );
  }

  Future<bool> loadPayments({bool force = false}) async {
    if (!force && (state.paymentsLoaded || state.isLoadingPayments)) return true;
    state = state.copyWith(isLoadingPayments: true, error: null);
    final result = await _ref.read(getAdminUserPaymentsUseCaseProvider)(_userId);
    if (!mounted) return false;
    return result.when(
      success: (items) {
        state = state.copyWith(
          payments: items,
          paymentsLoaded: true,
          isLoadingPayments: false,
          error: null,
        );
        return true;
      },
      failure: (error) {
        state = state.copyWith(
          payments: const <AdminTransactionItem>[],
          paymentsLoaded: true,
          isLoadingPayments: false,
          error: error,
        );
        return false;
      },
    );
  }

  Future<void> refreshActiveTab(String selectedTab) async {
    await load(silent: true);
    switch (selectedTab) {
      case 'Vehicles':
        await loadVehicles(force: true);
        break;
      case 'Drivers':
        await loadDrivers(force: true);
        break;
      case 'Payments':
        await loadPayments(force: true);
        break;
      case 'Documents':
        await loadDocuments(force: true);
        break;
      case 'Tickets':
        await loadTickets(force: true);
        break;
      default:
        break;
    }
  }
}
