import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_vts/shared/widgets/top_bar.dart';
import 'package:open_vts/features/vehicles/domain/config/vehicle_role_config.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_list_state.dart';
import 'package:open_vts/features/vehicles/domain/entities/vehicle_models.dart';
import 'package:open_vts/features/vehicles/presentation/controllers/vehicle_list_controller.dart';
import 'package:open_vts/features/vehicles/presentation/widgets/vehicle_filter_bar.dart';
import 'package:open_vts/features/vehicles/presentation/widgets/vehicle_list.dart';
import 'package:open_vts/shared/widgets/app_shimmer.dart';

class VehiclesScreen extends ConsumerStatefulWidget {
  const VehiclesScreen({super.key, required this.config});

  final VehicleRoleConfig config;

  @override
  ConsumerState<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends ConsumerState<VehiclesScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _syncRoleAndLoad();
  }

  @override
  void didUpdateWidget(covariant VehiclesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.role != widget.config.role ||
        oldWidget.config.listEndpoint != widget.config.listEndpoint) {
      _syncRoleAndLoad();
    }
  }

  void _syncRoleAndLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(selectedVehicleRoleProvider.notifier).state = widget.config.role;
      ref.read(vehicleListControllerProvider(widget.config).notifier).loadVehicles();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = vehicleListControllerProvider(widget.config);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    ref.listen(provider.select((value) => value.effect), (previous, next) {
      if (next == null || previous == next) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(content: Text(next.message)));
      controller.clearEffect();
    });

    if (_searchController.text != state.searchQuery) {
      _searchController.value = TextEditingValue(
        text: state.searchQuery,
        selection: TextSelection.collapsed(offset: state.searchQuery.length),
      );
    }

    return Scaffold(
      appBar: TopBar(
        title: widget.config.title,
        onClose: () => Navigator.of(context).pop(),
      ),
      body: Column(
        children: [
          VehicleFilterBar(
            searchController: _searchController,
            selectedTab: state.selectedTab,
            config: widget.config,
            onSearchChanged: controller.setSearchQuery,
            onTabSelected: controller.setSelectedTab,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: controller.refresh,
              child: _buildBody(state, controller),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(VehicleListState state, VehicleListController controller) {
    if (state.isLoading && state.vehicles.isEmpty) {
      return _buildLoadingView();
    }

    if (state.errorMessage != null && state.vehicles.isEmpty) {
      return _buildErrorView(state.errorMessage!, controller.refresh);
    }

    return VehicleList(
      vehicles: state.vehicles,
      loading: state.loading,
      config: widget.config,
      onVehicleTap: _onVehicleTap,
    );
  }

  Widget _buildLoadingView() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: AppShimmer(width: double.infinity, height: 120, radius: 12),
      ),
    );
  }

  Widget _buildErrorView(String errorMessage, Future<void> Function() retry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            errorMessage,
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: retry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _onVehicleTap(VehicleItem vehicle) {
    final vehicleId = vehicle.id.trim();
    if (vehicleId.isEmpty) return;
    context.push(widget.config.routeBuilder(vehicleId));
  }
}
