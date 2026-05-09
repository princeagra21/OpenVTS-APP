part of 'geofence.dart';

extension _GeofenceMoreMenu on _GeofenceScreenState {
  Future<void> _openLayersSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return MapLayersSheet(
          selectedTileLayerId: _selectedTileLayerId,
          onSelected: (option) {
            setState(() => _selectedTileLayerId = option.id);
            Navigator.pop(sheetContext);
          },
        );
      },
    );
  }

  void _togglePseudo3D() {
    setState(() => _isPseudo3D = !_isPseudo3D);
  }

  void _toggleMoreMenu() {
    setState(() => _isMoreMenuOpen = !_isMoreMenuOpen);
  }

  void _closeMoreMenu() {
    if (!_isMoreMenuOpen) return;
    setState(() => _isMoreMenuOpen = false);
  }

  Widget _buildMoreActionButton({
    required BuildContext context,
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
    bool active = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: glassMapControlButton(
        context: context,
        width: 44,
        height: 44,
        borderRadiusValue: 9,
        backgroundColor: active ? Theme.of(context).colorScheme.primary : null,
        borderColorOverride: active
            ? Theme.of(context).colorScheme.primary
            : null,
        child: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildMoreTextButton({
    required BuildContext context,
    required String tooltip,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: glassMapControlButton(
        context: context,
        width: 44,
        height: 44,
        borderRadiusValue: 9,
        child: Text(label),
        onPressed: onPressed,
      ),
    );
  }

  Widget _buildExpandedMoreMenu(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          _buildMoreActionButton(
            context: context,
            tooltip: 'Landmark List',
            icon: Icons.list_alt_rounded,
            onPressed: () {
              _closeMoreMenu();
              _showLandmarkListSheet();
            },
          ),
          const SizedBox(height: 12),
          _buildMoreActionButton(
            context: context,
            tooltip: 'Map Layers',
            icon: Icons.layers_outlined,
            onPressed: () async {
              _closeMoreMenu();
              await _openLayersSheet();
            },
          ),
          const SizedBox(height: 12),
          _buildMoreTextButton(
            context: context,
            tooltip: _isPseudo3D ? 'Switch to 2D' : 'Switch to 3D',
            label: _isPseudo3D ? '3D' : '2D',
            onPressed: () {
              _closeMoreMenu();
              _togglePseudo3D();
            },
          ),
          const SizedBox(height: 12),
          _buildMoreActionButton(
            context: context,
            tooltip: 'Fit All Landmarks',
            icon: Icons.fit_screen_outlined,
            onPressed: () {
              _closeMoreMenu();
              _fitToLandmarks(_allLandmarkPoints());
            },
          ),
          const SizedBox(height: 12),
          _buildMoreActionButton(
            context: context,
            tooltip: 'Refresh Landmarks',
            icon: Icons.refresh,
            onPressed: () {
              _closeMoreMenu();
              _loadLandmarks();
            },
          ),
          const SizedBox(height: 12),
          _buildMoreActionButton(
            context: context,
            tooltip: 'Clear Drawing',
            icon: Icons.clear_all,
            onPressed: () {
              _closeMoreMenu();
              _clearGeofences();
            },
          ),
        ],
      ),
    );
  }
}
