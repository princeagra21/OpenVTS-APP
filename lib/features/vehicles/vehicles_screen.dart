import 'package:flutter/material.dart';
import 'package:open_vts/core/widgets/app_shimmer.dart';
import 'package:open_vts/features/vehicles/vehicle_controller.dart';
import 'package:open_vts/features/vehicles/vehicle_models.dart';
import 'package:open_vts/features/vehicles/vehicle_repository.dart';
import 'package:open_vts/features/vehicles/vehicle_role_config.dart';
import 'package:open_vts/features/vehicles/widgets/vehicle_filter_bar.dart';
import 'package:open_vts/features/vehicles/widgets/vehicle_list.dart';

/// Shared vehicle list screen
class VehiclesScreen extends StatefulWidget {
  const VehiclesScreen({
    super.key,
    required this.config,
  });

  final VehicleRoleConfig config;

  @override
  State<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends State<VehiclesScreen> {
  late final VehicleController _controller;
  late final VehicleRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository = VehicleRepositoryFactory.create(widget.config.role);
    _controller = VehicleController(
      config: widget.config,
      repository: _repository,
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: VehicleFilterBar(
            controller: _controller,
            config: widget.config,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _controller.refresh,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final state = _controller.state;

            if (state.loading && state.items.isEmpty) {
              return _buildLoadingView();
            }

            if (state.errorMessage != null && state.items.isEmpty) {
              return _buildErrorView(state.errorMessage!);
            }

            return VehicleList(
              vehicles: state.items,
              loading: state.loading,
              config: widget.config,
              onVehicleTap: _onVehicleTap,
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return ListView.builder(
      itemCount: 10,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: AppShimmer(
          width: double.infinity,
          height: 120,
          radius: 12,
        ),
      ),
    );
  }

  Widget _buildErrorView(String errorMessage) {
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
            onPressed: _controller.refresh,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  void _onVehicleTap(VehicleItem vehicle) {
    // TODO: Navigate to vehicle details
    // final route = widget.config.routeBuilder(vehicle.id);
    // context.go(route);
  }
}