import 'package:open_vts/features/vehicles/domain/entities/vehicle_models.dart';

class VehicleListState {
  const VehicleListState({
    this.vehicles = const <VehicleItem>[],
    this.selectedTab = 'All',
    this.searchQuery = '',
    this.statusFilter,
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.effect,
  });

  final List<VehicleItem> vehicles;
  final String selectedTab;
  final String searchQuery;
  final String? statusFilter;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final VehicleListEffect? effect;

  bool get loading => isLoading || isRefreshing;
  List<VehicleItem> get items => vehicles;

  VehicleListState copyWith({
    List<VehicleItem>? vehicles,
    String? selectedTab,
    String? searchQuery,
    Object? statusFilter = _unchanged,
    bool? isLoading,
    bool? isRefreshing,
    Object? errorMessage = _unchanged,
    Object? effect = _unchanged,
  }) {
    return VehicleListState(
      vehicles: vehicles ?? this.vehicles,
      selectedTab: selectedTab ?? this.selectedTab,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: identical(statusFilter, _unchanged) ? this.statusFilter : statusFilter as String?,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: identical(errorMessage, _unchanged) ? this.errorMessage : errorMessage as String?,
      effect: identical(effect, _unchanged) ? this.effect : effect as VehicleListEffect?,
    );
  }
}

class VehicleListEffect {
  const VehicleListEffect._({required this.message, required this.isError});

  const VehicleListEffect.success(String message) : this._(message: message, isError: false);
  const VehicleListEffect.error(String message) : this._(message: message, isError: true);

  final String message;
  final bool isError;
}

const Object _unchanged = Object();
